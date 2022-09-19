// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./LibDiamond.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "hardhat/console.sol";

library CoinSwapper {
    uint256 constant ethereumId = 1;
    uint256 constant rinkebyId = 4;
    uint256 constant goerliId = 5;
    uint256 constant polygonId = 137;
    uint256 constant mumbaiId = 80001;

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Same on all Nets SwapRouter address

    // Returns the appropriate WETH9 token address for the given network id.
    function getWETH9Address()
        internal
        view
        returns (address priceFeedAddress)
    {
        if (block.chainid == ethereumId) {
            console.log("USDT");
            return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == rinkebyId) {
            return 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        } else if (block.chainid == goerliId) {
            return 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        } else if (block.chainid == polygonId) {
            return 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        } else if (block.chainid == mumbaiId) {
            return 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
        }
    }

    // Returns the appropriate USDC token address for the given network id.
    function getUSDCAddress() internal view returns (address priceFeedAddress) {
        if (block.chainid == ethereumId) {
            return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
            // return 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        } else if (block.chainid == rinkebyId) {
            return 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
        } else if (block.chainid == goerliId) {
            return 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C;
        } else if (block.chainid == polygonId) {
            return 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        } else if (block.chainid == mumbaiId) {
            return 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
        }
    }

    /** @dev Shortcut function to swap ETH for USDC */
    function convertEthToUSDC() internal {
        wrapMsgEth();
        convertWETHtoUSDC();
    }

    /** @dev Wraps the entire balance of the contract in WETH9 */
    function wrapEth() internal {
        address WETH9 = getWETH9Address();
        IWETH9(WETH9).deposit{value: address(this).balance}();
    }

    /** @dev Wraps the entire balance of the contract in WETH9 */
    function wrapMsgEth() internal {
        address WETH9 = getWETH9Address();
        IWETH9(WETH9).deposit{value: msg.value}();
    }

    /** @dev Converts all WETH owned by contract to USDC */
    function convertWETHtoUSDC() internal {
        address USDC = getUSDCAddress();
        address WETH9 = getWETH9Address();
        uint256 currentBlance = IWETH9(WETH9).balanceOf(address(this));

        // For this example, we will set the pool fee to 0.3%.
        uint24 poolFee = 3000;

        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            address(this),
            currentBlance
        );

        TransferHelper.safeApprove(WETH9, address(swapRouter), currentBlance);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: currentBlance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swapRouter.exactInputSingle(params);
    }
}