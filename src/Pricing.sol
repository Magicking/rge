pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC5313} from "@openzeppelin/contracts/interfaces/IERC5313.sol";

import {RGMove} from "./RGMove.sol";
import {IPricing} from "./interfaces/IPricing.sol";
import "./errors.sol";

/// @title Pricing - A contract to price the NFTs
/// @author Magicking
/// @notice This contract is used to price the mint of the RGE NFT
contract PricingV0 is UUPSUpgradeable, IPricing {
    bytes32 private constant STORAGE_V0_LOCATION = 0x9d87395271d3df9de7534803da3336e5683fec18ecaee2e38d1318d0ae243200; //keccak256(abi.encode(uint256(keccak256("rge.v0")) - 1)) & ~bytes32(uint256(0xff))
    // bytes32 private constant STORAGE_V0_LOCATION = keccak256(abi.encode(uint256(keccak256("rge.v0")) - 1)) & ~bytes32(uint256(0xff));

    /// @custom:storage-location erc7201:rge.v0
    struct StorageV0 {
		string baseURI;
		IERC5313 rge;
    }

	/// @notice Internal function to get the storage pointer
    function _getStorageV0() private pure returns (StorageV0 storage $) {
        assembly {
            $.slot := STORAGE_V0_LOCATION
        }
    }

	/// @notice Internal function to disable the constructor
    constructor() {
        _disableInitializers();
    }

	/// @notice Initializer function to setup the upgreadable pricer
    function initialize(address rge) public initializer {
        __UUPSUpgradeable_init();
        StorageV0 storage $ = _getStorageV0();
		$.baseURI = "https://rge.6120.eu/epitaph?i=";
		$.rge = IERC5313(rge);
    }

    function _authorizeUpgrade(address newImplementation) internal override {
		if (msg.sender != _getStorageV0().rge.owner()) {
			revert NotAuthorized();
		}
	}

	function baseURI() public view override returns (string memory) {
		return _getStorageV0().baseURI;
	}

    function payment(address from, address inMemoryOf, address dao) external payable override {
        new RGMove{value: msg.value}(from, inMemoryOf, dao);
    }

    function getPrice(uint256 color) public returns (uint256, uint256) {
        return getPrice(color, "");
    }

	/// @dev kept for historical reasons
    struct Coupon {
        bytes32[] proof;
        // First 1 bits is type
        // 0: Percentage
        // 1: address max reduction
        uint256 reduction;
    }

	/// @dev kept for historical reasons, coupon has been removed
    function isValidCoupon(bytes memory) public view returns (bool, bytes32 leaf, Coupon memory coupon) {
        // Verify proof
        return (
            false,
            0x0,
            Coupon({
				proof: new bytes32[](0),
				reduction: 0
			})
        );
    }

    function getPrice(uint256 color, bytes memory) public returns (uint256, uint256) {
        uint256 r = (color & 0xFF0000) >> 16;
        uint256 g = (color & 0x00FF00) >> 8;
        uint256 b = (color & 0x0000FF);
        uint256 CMax = r;
        if (g > CMax) CMax = g;
        if (b > CMax) CMax = b;

        uint256 CMin = r;
        if (g < CMin) CMin = g;
        if (b < CMin) CMin = b;

        CMax = (CMax * 1 ether) / 255;
        CMin = (CMin * 1 ether) / 255;

        if (CMax == 0 || color > 0xFFFFFF) {
            return (0, 1); // Black // already used
        }

        uint256 value = CMax;
        uint256 sat = (((1 ether * (CMax - CMin)) / CMax) * 1 ether) / 1 ether;

        // Case 1:
        // If (value + sat) is below 100% if mainly brightness
        // pricing on that solely
        // Case 2:
        // Above the 50% brightPrice, there is more color
        uint256 price = (value + sat < 1 ether) ? value : value + sat;
        // See https://www.peko-step.com/en/tool/colorchart_en.html for vizualisation
        return (price, 0);
    }
}
