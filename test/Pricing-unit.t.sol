// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "forge-std/Script.sol";

import {PricingV0} from "../src/Pricing.sol";
import {IPricing} from "../src/interfaces/IPricing.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/constants.sol";

contract PricingTest is Test {
    IPricing pricer;

    address alice;

    function setUp() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);

        pricer = IPricing(
            address(new ERC1967Proxy(address(new PricingV0()), abi.encodeCall(PricingV0.initialize, (RGE_ADDRESS))))
        );
    }

    function testGetPrice() public {
        (uint256 price, uint256 ok) = pricer.getPrice(uint256(0xfffff7), new bytes(0));
        assertLt(price, 2 ether);
        assertEq(ok, 0);
    }
}
