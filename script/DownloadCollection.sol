// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Script.sol";
import {Base64} from "solady/utils/Base64.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IReaperGambitEpitaph} from "../src/interfaces/IReaperGambitEpitaph.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Import IERC20.sol from OpenZeppelin contracts repo
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IWETH} from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

interface IERC20ReaperGambit is IERC20 {
    // Return block death number or 0 if immortal or unknown
    function KnowDeath(address account) external view returns (uint256);
}

contract BaseCollection is Script {
    using LibString for string;

    address rge = 0x46d0d00e847ed9C2756cfD941E70D99e9152A22f;

    function extract(string memory uri) public pure returns (string memory, string memory) {
        string memory sanitizedURI = uri.replace({search: "data:application/json;base64,", replacement: ""});
        string memory decodedURI = string(Base64.decode(sanitizedURI));
        string memory image = string(vm.parseJson(decodedURI, ".image"));
        string memory sanitizedImage = image.replace({search: "data:image/bmp;base64,", replacement: ""});
        string memory obj = string(Base64.decode(sanitizedImage));
        return (decodedURI, obj);
    }

    function setUp() public {}

    function run() public virtual {
        uint256 supply = IReaperGambitEpitaph(rge).totalSupply();
        string memory output = vm.serializeUint("", "totalSupply", supply);

        // Write JSON configuration file
        vm.writeJson(output, "img/collection.json");
    }
}

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract BMP is BaseCollection {
    using console2 for string;
    using console2 for bytes;
    using console2 for bytes;
    using Strings for uint256;

    function run() public override {
        string memory basePath = "img/rg-";

        console.log("Deployed ReaperGambitEpitaph at", address(rge));
        // Get the number of items in the collection
        uint256 itemCount = IReaperGambitEpitaph(rge).totalSupply();
        // For each item in the collection, call BMP function and save the NFT
        for (uint256 i = 0; i < itemCount; i++) {
            address o = ERC721Upgradeable(rge).ownerOf(i);
            // Call BMP as address owner
            vm.prank(o);
            bytes memory tokenURI = IReaperGambitEpitaph(rge).BMP(i);
            string memory filename = string(abi.encodePacked(basePath, i.toString(), ".bmp"));
            vm.writeFileBinary(filename, tokenURI);
            console.log("Downloaded BMP", i);
        }
        super.run();
    }
}

contract JSON is BaseCollection {
    using console2 for string;
    using console2 for bytes;
    using Base64 for bytes;
    using Strings for uint256;

    function run() public override {
        string memory basePath = "img/rg-";

        console.log("Deployed ReaperGambitEpitaph at", rge);
        // Get the number of items in the collection
        uint256 itemCount = IReaperGambitEpitaph(address(rge)).totalSupply();
        // For each item in the collection, call BMP function and save the NFT
        for (uint256 i = 0; i < itemCount; i++) {
            address o = ERC721Upgradeable(rge).ownerOf(i);
            // Call BMP as address owner
            vm.prank(o);
            string memory tokenURI = ERC721Upgradeable(rge).tokenURI(i);
            string memory filename = string(abi.encodePacked(basePath, i.toString(), ".json"));
            (string memory decodedURI,) = extract(tokenURI);
            vm.writeFileBinary(filename, bytes(decodedURI));
            console.log("Downloaded NFT", i);
        }
        super.run();
    }
}
