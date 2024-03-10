// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/Script.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import {ReaperGambitEpitaph, BokkyPooBahsDateTimeContract} from "../src/ReaperGambitEpitaph.sol";
// Import IERC20.sol from OpenZeppelin contracts repo
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {Pricing} from "../src/previous_contracts/Pricing.sol";
import {IPricing} from "../src/interfaces/IPricing.sol";
import {BMPImage} from "../src/BMPEncoder.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface IERC20ReaperGambit is IERC20 {
    // Return block death number or 0 if immortal or unknown
    function KnowDeath(address account) external view returns (uint256);
}

contract FakeWETHContract {
    function deposit() public payable {}

    function approve(address spender, uint256 amount) public returns (bool) {
        return true;
    }
}

contract ReaperGambitTest is Test {
    using Strings for uint256;

    IERC20ReaperGambit rg;
    ERC1967Proxy proxy;
    ReaperGambitEpitaph _implementation;
    ReaperGambitEpitaph rge;
    IPricing pricer;
    IUniswapV2Router02 uniswapRouter;
    address alice;

    function setUp() public {
        BMPImage renderer = new BMPImage();
        pricer = IPricing(address(new Pricing(bytes32(0x0))));
        vm.deal(alice, 6 ether);
        rg = IERC20ReaperGambit(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
        _implementation = new ReaperGambitEpitaph();
        // Deploy && Initialize proxy
        proxy =
        new ERC1967Proxy(address(_implementation), abi.encodeCall(ReaperGambitEpitaph.initialize, (renderer, pricer)));
        rge = ReaperGambitEpitaph(address(proxy));

        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        alice = address(0xdeadbeefb00b5a1ce);
        vm.deal(alice, 6 ether);
    }

    function testMintingUnit() public {
        // Prank to get Eth
        // Mint using Eth
        vm.startPrank(alice);
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.approve.selector), abi.encode(true));
        rg.approve(address(rge), 20000);
        uint256 amount = 2 ether;
        // For 2 Eth:
        // 20% com fee => 0.4 Eth, 1.6 Eth
        uint256 comfee = amount - (amount * 80) / 100;
        // 50% Eth is used to buy RG, 0.8 Eth, 0.8 Eth
        uint256 RGToBuy = (amount - comfee) >> 1;
        uint256[12] memory sig = [
            uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00),
            uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000),
            uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),
            uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000),
            uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000),
            uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000),
            uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00),
            uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000),
            uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),
            uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000),
            uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000),
            uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000)
        ];
        vm.deal(alice, amount);
        vm.deal(msg.sender, amount);
        vm.deal(address(this), amount);

        uint256[] memory ret = new uint256[](uint256(2));
        FakeWETHContract fakeWETH = new FakeWETHContract();

        ret[0] = block.number + 69400;
        vm.mockCall(
            address(uniswapRouter),
            0,
            abi.encodeWithSelector(uniswapRouter.WETH.selector),
            abi.encode(address(fakeWETH))
        );
        vm.mockCall(
            address(uniswapRouter),
            RGToBuy,
            abi.encodeWithSelector(uniswapRouter.swapExactETHForTokens.selector),
            abi.encode(ret)
        );
        //TODO MOCK
        // deposit WETH
        //vm.mockCall(address(fakeWETH), RGToBuy, abi.encodeWithSelector(FakeWETH.deposit.selector), "");
        // approve
        // transfer 1
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.transfer.selector), abi.encode(1));
        // transfer 1
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.balanceOf.selector), abi.encode(1000));
        // getAmountsOut
        // quote
        // quote
        // increaseAllowance
        // addLiquidity
        // RG transfer
        // WETH transfer
        bytes memory empty;
        vm.mockCall(address(pricer), abi.encodeWithSelector(pricer.payment.selector), empty);
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.KnowDeath.selector), abi.encode(ret[0]));
        rge.mintEpitaphOf{value: amount}(sig, 0xFFFFF9, alice, new bytes(0));
        assertTrue(rge.totalSupply() > 0);
    }

    // Test the creation of a BMP without price check
    function testBMPUnit() public {
        // Prank to get Eth
        // Mint using Eth
        vm.startPrank(alice);
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.approve.selector), abi.encode(true));
        rg.approve(address(rge), 20000);
        uint256 amount = 2 ether;
        uint256[12] memory sig = [
            uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00),
            uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000),
            uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),
            uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000),
            uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000),
            uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000),
            uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00),
            uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000),
            uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),
            uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000),
            uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000),
            uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000)
        ];
        vm.deal(alice, amount);
        vm.deal(msg.sender, amount);
        vm.deal(address(this), amount);
        uint256[] memory ret = new uint256[](uint256(2));
        ret[0] = block.number + 64800;
        vm.mockCall(
            address(uniswapRouter),
            amount,
            abi.encodeWithSelector(uniswapRouter.swapExactETHForTokens.selector),
            abi.encode(ret)
        );
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.KnowDeath.selector), abi.encode(ret[0]));
        vm.mockCall(
            0x23d23d8F243e57d0b924bff3A3191078Af325101,
            abi.encodeWithSelector(BokkyPooBahsDateTimeContract.timestampToDateTime.selector),
            abi.encode(0, 0, 0, 0, 0, 1)
        );
        bytes memory empty;
        vm.mockCall(address(pricer), abi.encodeWithSelector(pricer.payment.selector), empty);
        rge.mintEpitaphOf{value: amount}(sig, 0xFFFFFF, alice, new bytes(0));
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.KnowDeath.selector), abi.encode(ret[0]));
        bytes memory tokenURI = rge.BMP(0);
        assertTrue(tokenURI.length > 0);
    }

    function testMetadataUnit() public {
        // Prank to get Eth
        // Mint using Eth
        vm.startPrank(alice);
        skip(1689337920);
        uint256[12] memory sig = [
            uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00),
            uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000),
            uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),
            uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000),
            uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000),
            uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000),
            uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00),
            uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000),
            uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),
            uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000),
            uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000),
            uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000)
        ];
        vm.mockCall(
            0x23d23d8F243e57d0b924bff3A3191078Af325101,
            abi.encodeWithSelector(BokkyPooBahsDateTimeContract.timestampToDateTime.selector),
            abi.encode(0, 0, 0, 0, 0, 1)
        );

        ReaperGambitEpitaph.Epitaph memory e = ReaperGambitEpitaph.Epitaph(
            0,
            0xffffff,
            false,
            alice,
            alice,
            address(0x00),
            block.timestamp,
            block.timestamp + 64800 * 12,
            block.number + 64800,
            new uint256[](sig.length)
        );
        for (uint256 i = 0; i < sig.length; i++) {
            e.graffity[i] = sig[i];
        }
        string memory tokenURI = rge._metadata(e);
        //console.log(tokenURI);
        assertTrue(bytes(tokenURI).length > 0);
    }
}
