// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {BMPImage} from "../src/BMPEncoder.sol";
import {ReaperGambitEpitaph} from "../src/ReaperGambitEpitaph.sol";
// Import IERC20.sol from OpenZeppelin contracts repo
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {Pricing} from "../src/previous_contracts/Pricing.sol";
import {IPricing} from "../src/interfaces/IPricing.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC20ReaperGambit is IERC20 {
    // Return block death number or 0 if immortal or unknown
    function KnowDeath(address account) external view returns (uint256);
}

contract ReaperGambitTest is Test {
    IERC20ReaperGambit rg;
    ERC1967Proxy proxy;
    ReaperGambitEpitaph _implementation;
    ReaperGambitEpitaph rge;
    IUniswapV2Router02 uniswapRouter;

    address alice;

    uint256 mainnetFork;

    function setUp() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        IPricing pricer = IPricing(address(new Pricing(bytes32(0x0))));
        alice = address(0xdeada1ce);
        vm.deal(alice, 3 ether);
        rg = IERC20ReaperGambit(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
        BMPImage renderer = new BMPImage();
        _implementation = new ReaperGambitEpitaph();
        // Deploy && Initialize proxy
        proxy = new ERC1967Proxy(
            address(_implementation), abi.encodeCall(ReaperGambitEpitaph.initialize, (renderer, pricer))
        );
        rge = ReaperGambitEpitaph(address(proxy));
    }

    function testMintingInteg() public {
        // Prank to get Eth
        // Mint using Eth
        vm.startPrank(alice);
        vm.mockCall(address(rg), abi.encodeWithSelector(rg.approve.selector), abi.encode(true));
        rg.approve(address(rge), 20000);
        uint256 amount = 2.1 ether;
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
        rge.mintEpitaphOf{value: amount}(sig, 0xFFFFF9, alice, new bytes(0));
        assertTrue(true);
    }

    function testUpgradesAuthorization() public {
        vm.prank(rge.owner());
        UUPSUpgradeable(rge).upgradeToAndCall(address(_implementation), new bytes(0));
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        UUPSUpgradeable(rge).upgradeToAndCall(address(_implementation), new bytes(0));
    }

    function testTagEpitaphOfDeadAccout() public {
        // Prank to get Eth
        // Mint using Eth
        vm.startPrank(alice);

        rg.approve(address(rge), 20000);
        uint256 amount = 2.0 ether;
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
        address vitalikRGTagged = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        rge.mintEpitaphOf{value: amount}(sig, 0xFFFFF8, vitalikRGTagged, new bytes(0));
        assertTrue(true);
    }
}
