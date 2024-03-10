pragma solidity 0.8.21;

import {IWETH} from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./constants.sol";

/// @title RGMove - A contract to move RG from the NFT contract to the DAO
/// @author Magicking
/// @notice This contract is used to manipulate RG tokens and move them to the DAO
contract RGMove {
    /// @notice Function to calculate 90% of a value, used to calculate the slippage
    /// @param value The value to calculate 90% of
    /// @return The 90% of the value
    /// @dev This function might display warning for some users because of the slippage
    function f90pc(uint256 value) internal pure returns (uint256) {
        return (value * 90) / 100;
    }

    /// @notice Constructor to move RG from the NFT contract to the DAO
    /// @param from The address of NFT minter
    /// @param inMemoryOf The address of the account to remember
    /// @param _dao The address of the DAO
    /// @dev This contract buys RG with half of the ETH sent, adds liquidity to the pool and sends the LP RG to the DAO
    constructor(address from, address inMemoryOf, address _dao) payable {
        IERC20 WETH = IERC20(uniswapRouter.WETH());

        // Initialize address[] memory path  with Weth and RG pair
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(RG);

        // Take half of the msg.value
        uint256 amount = msg.value >> 1;
        // half of the ETH amount is now RG, increasing RG price
        uint256[] memory maxOuts = uniswapRouter.getAmountsOut(amount, path);
        uniswapRouter.swapExactETHForTokens{value: amount}(2, path, address(this), block.timestamp + 60);
        IWETH(address(WETH)).deposit{value: msg.value - amount}();
        WETH.approve(address(uniswapRouter), type(uint256).max);
        uint256 RGAmount = RG.balanceOf(address(this));
        uint256 dust = 1 ether;
        if (RGAmount <= 2 ether) {
            dust = 1;
        }
        // Send 1 RG towards the sender to improve its health
        RG.transfer(from, dust);
        // Send 1 RG towards the account to remember account
        RG.transfer(inMemoryOf, dust);
        RGAmount = RG.balanceOf(address(this));
        // add liquitidy to the pool
        RG.increaseAllowance(address(uniswapRouter), RGAmount);
        // send the LP RG to DAO
        uniswapRouter.addLiquidity(
            path[1],
            path[0],
            RGAmount,
            msg.value - amount,
            f90pc(RGAmount),
            f90pc(msg.value - amount),
            _dao,
            block.timestamp + 60
        );
        // transfer RG remaining to SENDER
        RGAmount = RG.balanceOf(address(this));
        path[0] = address(RG);
        path[1] = address(WETH);
        // swap remaining RG to ETH and send to dao
        if (RGAmount > 0) {
            maxOuts = uniswapRouter.getAmountsOut(RGAmount, path);
            // 10% slippage for bot honeypotting
            uniswapRouter.swapExactTokensForTokens(RGAmount, f90pc(maxOuts[1]), path, _dao, block.timestamp + 60);
            RGAmount = RG.balanceOf(address(this));
        }
        // transfer WETH remaining to DAO
        amount = WETH.balanceOf(address(this));
        if (amount > 0) {
            WETH.transfer(_dao, amount);
        }
        // transfer RG remaining to SENDER
        RGAmount = RG.balanceOf(address(this));
        if (RGAmount > 0) {
            RG.transfer(from, RGAmount);
        }
    }
}
