pragma solidity 0.8.21;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
/// @dev Use of the non-standard `increaseAllowance` function
interface OZIERC20 is IERC20Metadata {
    function increaseAllowance(address spender, uint256 amount) external returns (bool);
}