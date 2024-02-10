// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Script.sol";
import { BMPImage } from "../src/BMPEncoder.sol";
import { ReaperGambitEpitaph } from "../src/ReaperGambitEpitaph.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Import IERC20.sol from OpenZeppelin contracts repo
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

interface IERC20ReaperGambit is IERC20 {
    // Return block death number or 0 if immortal or unknown
    function KnowDeath(address account) external view returns (uint256);
}
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Write is Script {
    using console2 for string;
    using console2 for bytes;
    using console2 for bytes;
    using Strings for uint256;

    function run() public {

    address alice;
        alice = address(0xa1cecafedeadbeef);
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        ReaperGambitEpitaph rge = ReaperGambitEpitaph(0xE0F13bF07e57ceBa12a4AaB90fb51c77932014FD);
        console.log("Deployed ReaperGambitEpitaph at", address(rge));

        IERC20ReaperGambit rg = IERC20ReaperGambit(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
        rg.approve(address(rge), 20000);

        uint256 minPrice = 0.001 ether;

        uint256[12] memory sig = [uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00), uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000), uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000), uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000), uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000),uint256(0x000000000000000007fe0000f000010007fc000003fe00001c00000780000a00), uint256(0x3c0780007e0380001fff801c000038002000ffffc000e0c000038030003c0000), uint256(0x0000000000003f807ffe387fffe0000000000000000000000000400000001000),uint256(0x00007ffc00000000001300000030000000018007000000001fe7000038200000), uint256(0x000117230000fffc0ceef8018c1800000001c61e00030007c3380e0000400000), uint256(0x00007d7000027ffc3fe00200701e000000000cc00001c007fe0004001fe00000)];
        rge.mintEpitaphOf{value: minPrice}(sig, 0xFFFEFF, msg.sender, "");
        bytes memory tokenURI = rge.BMP(0);
        console.log(tokenURI.length);
        vm.writeFileBinary("img/alive-self.bmp", tokenURI);
        vm.stopPrank();
        tokenURI = rge.BMP(0);
        console.log(tokenURI.length);
        vm.writeFileBinary("img/alive-all.bmp", tokenURI);
        // Loop to skip every 10 blocks and write each subsequent epitaph
        if (false) {
            for (uint256 i = 1; i < 648; i++) {
                vm.roll(block.number + i*100);
                tokenURI = rge.BMP(0);
                console.log(tokenURI.length);
                string memory filename = string(abi.encodePacked("img/dead-", i.toString(), ".bmp"));
                vm.writeFileBinary(filename, tokenURI);
            }
        }
        vm.roll(block.number + 64801);
        tokenURI = rge.BMP(0);
        console.log(tokenURI.length);
        vm.writeFileBinary("img/dead.bmp", tokenURI);
        vm.roll(block.number + 64801);
        tokenURI = rge.BMP(0);
        console.log(tokenURI.length);
        vm.writeFileBinary("img/dead.bmp", tokenURI);
    }
}
