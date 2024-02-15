// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "forge-std/Script.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import {Pricing} from "../src/previous_contracts/Pricing.sol";

struct Coupon {
    bytes32[] proof;
    // First 1 bits is type
    // 0: Percentage
    // 1: address max reduction
    uint256 reduction;
}

contract PricingTest is Test {
    Pricing pricer;
    address alice;

    function setUp() public {
        pricer = new Pricing(bytes32(0x0));
    }

    function testGetPrice() public {
        (uint256 price, uint256 ok) = pricer.getPrice(uint256(0xffffff), new bytes(0));
        assertEq(price, 1 ether);
        assertEq(ok, 0);
        (price, ok) = pricer.getPrice(uint256(0xff0000), new bytes(0));
        assertEq(price, 2 ether);
        assertEq(ok, 0);
    }

    function testFakeCoupon() public {
        bytes memory fakeCoupon = abi.encodePacked(uint256(0x42), uint256(0x24));
        vm.expectRevert();
        pricer.getPrice(uint256(0xff0000), fakeCoupon);
    }

    function testCouponReduction1leaf() public {
        pricer = new Pricing(bytes32(0x97a47206865f6a61badf9ab82ec7cceb903cd016ec85b928b64f319055ab121d));
        Coupon memory coupon = Coupon({proof: new bytes32[](1), reduction: uint256(500)});
        coupon.proof[0] = bytes32(0xf8d00c199691166c7e23a6fa35c716a83e0c1a8ea6c9a584a520c549fad80d5f);
        bytes memory couponB = abi.encode(coupon);
        console.logBytes(couponB);
        (uint256 price, uint256 ok) = pricer.getPrice(uint256(0xff0000), couponB);
        assertEq(price, 0.1 ether);
        assertEq(ok, 0);
    }

    function testCouponReductionMultipleLeafs() public {
        bytes32 root = bytes32(0x8a04e782f94a635ced7da02d59f9ffe041b4bf85ae2f38e76149a052e4911ec6);
        pricer = new Pricing(root);
        Coupon memory coupon = Coupon({proof: new bytes32[](14), reduction: uint256(500)});
        coupon.proof[0] = bytes32(0x402766e9dec681c0dc1ccc57ce00dc76bf96148174753a5ced837da6dcc6d2cb);
        coupon.proof[1] = bytes32(0xa0cb524398f21e15adfa07c9015db668d631f826d87af81d5e82d7d9ea2a37e5);
        coupon.proof[2] = bytes32(0x806a8290e012603ea4027d2ba9a9ba056773b6f6cc4dfc61e1ddbbd9b7cb71c1);
        coupon.proof[3] = bytes32(0xc027f2c023e063985817fd28cb26df22f8ee115dee5da7e25ba9b3b8115cb03b);
        coupon.proof[4] = bytes32(0x40037c5b53a88576d62d12c592f9b5f16562e009a98bb3ef4e005c8d6629e616);
        coupon.proof[5] = bytes32(0x86a2d07e222b1f988649c8a72b9f928525b59ad145c3ed1a6c1734897452d96d);
        coupon.proof[6] = bytes32(0xb11f9fdc11e6556ce5b42953aef63ea179e1442cc6dadac1dbeb7050fb470970);
        coupon.proof[7] = bytes32(0x7b0f94248469514236890da6bcdef41d1e9065619df42d13587e58d6e57a0102);
        coupon.proof[8] = bytes32(0x19a133ae6ccdb375e6d7923f72df57f0b795cf6d0ccf7d60080dd6a39b9d3f9d);
        coupon.proof[9] = bytes32(0xa1b2b2d05119506468a444ed1283df2e7a8141086feb66d6ec531b2be3c91e44);
        coupon.proof[10] = bytes32(0xb8c22a440bf06ea1ca6ad2c447b7b7ebdf1e16573370e3f5d69b7019b125a7e4);
        coupon.proof[11] = bytes32(0x2ce6c80484d850b4683e7a065c5e30ff8029db6d12dbd5407df8111f3105eb79);
        coupon.proof[12] = bytes32(0x39b88c2e9b1d829eb953f22fb53d3244884674dde4c2c20d21e878b8bf268f2e);
        coupon.proof[13] = bytes32(0x4149645829b739d72f63f04995a34a0213086ae67854461780d0a01b9c32c1ba);
        bytes memory couponB = abi.encode(coupon);
        console.logBytes(couponB);
        (uint256 price, uint256 ok) = pricer.getPrice(uint256(0xff0000), couponB);
        assertEq(price, (2 ether * 500) / 10_000);
        assertEq(ok, 0);
    }
}
