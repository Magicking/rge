// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "forge-std/Script.sol";
import { BMPImage } from "../src/BMPEncoder.sol";
import { ReaperGambitEpitaph } from "../src/ReaperGambitEpitaph.sol";
import { IPricing, Pricing } from "../src/Pricing.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// Import IERC20.sol from OpenZeppelin contracts repo
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IWETH } from "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

interface IERC20ReaperGambit is IERC20 {
    // Return block death number or 0 if immortal or unknown
    function KnowDeath(address account) external view returns (uint256);
}
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is Script {
    using console2 for string;
    using console2 for bytes;


	function printDAOStats(ReaperGambitEpitaph rge) public {
		IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		IERC20 RG = IERC20(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
		IERC20 LPTOKEN = IERC20(0x8aB0fF3106Bf37b2dB685aafD458BAee2128D648);
		IERC20 WETH = IERC20(uniswapRouter.WETH());
		address dao = rge.owner();
		console.log("DAO address", dao);
		// Print WETH balance
		console.log("WETH balance", WETH.balanceOf(dao));
		// Print LP Uni token
		console.log("LP Uni token", LPTOKEN.balanceOf(dao));
		// Print RG balance
		console.log("RG balance", RG.balanceOf(dao));
		// Print RGE balance
		console.log("RGE balance", rge.balanceOf(dao));
		// Print RGE total supply
		console.log("RGE total supply", rge.totalSupply());

	}
    function run() public {
		// Multisig DAO
		address DAO = 0x89261878977B5a01C4fD78Fc11566aBe31BBc14e;
        //uint256 deployerPrivateKey0 = vm.envUint("PRIVATE_KEY0");
        vm.startBroadcast();
		// Deploy implementation of Pricing
		// root with 10_000 reduction coupon and 2K BB board
		bytes32 root = 0x8868584bcca5b092e0c5f5819664ae2ff1d779b6bf6f9575d7478a082d39c262;

		Pricing pricer = new Pricing(root);
		BMPImage renderer = new BMPImage();
        ReaperGambitEpitaph rge = new ReaperGambitEpitaph();
		// Deploy && Initialize proxy
		ERC1967Proxy proxy = new ERC1967Proxy(address(rge), abi.encodeCall(ReaperGambitEpitaph.initialize, (renderer, pricer)));

        console.log("Deployed ReaperGambitEpitaph implementation at", address(rge));
        
        rge = ReaperGambitEpitaph(address(proxy));

		rge.transferOwnership(DAO);
        console.log("Deployed ReaperGambitEpitaph NFT at", address(proxy));

        vm.stopBroadcast();
    }
}
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract UpdateRGE is Script {
    using console2 for string;
    using console2 for bytes;
	address public deployedContract = address(0xE0F13bF07e57ceBa12a4AaB90fb51c77932014FD);

    function run() public {
       vm.startBroadcast();
       ReaperGambitEpitaph rge = ReaperGambitEpitaph(deployedContract);
       (IPricing pricer, BMPImage renderer) = rge.getStorage();
       console.log("Renderer values", address(renderer));
       console.log("Pricer values", address(pricer));
       console.log("DAO values", rge.owner());
       console.log("Changing DAO value");
	   address DAO = 0x89261878977B5a01C4fD78Fc11566aBe31BBc14e;
	   rge.transferOwnership(DAO);
       (pricer, renderer) = rge.getStorage();
       console.log("DAO values", rge.owner());
       vm.stopBroadcast();
    }
}
/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployPricer is Script {
    using console2 for string;
    using console2 for bytes;

    function run() public {
      vm.startBroadcast();
      bytes32 root = 0x8868584bcca5b092e0c5f5819664ae2ff1d779b6bf6f9575d7478a082d39c262;

      Pricing pricer = new Pricing(root);
      console.log("Deployed Pricer at", address(pricer));
      vm.stopBroadcast();
    }
}
