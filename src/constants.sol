pragma solidity 0.8.21;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {OZIERC20} from "./interfaces/OZIERC20.sol";

address constant UNIV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
IUniswapV2Router02 constant uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
OZIERC20 constant RG = OZIERC20(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
address constant RGE_ADDRESS = 0x46d0d00e847ed9C2756cfD941E70D99e9152A22f;
uint256 constant AMOUNT_TO_BUY = 42_000 * 1 ether;