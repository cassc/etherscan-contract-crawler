// SPDX-License-Identifier: GPL-3.0
// This contract was inspired from multicall2 repo from makerdao and handles a multi-call for multiple vaults
// to get their token balances and locked amounts.
// @dev: this contract is a helper contract and should only be used for backend reads

pragma solidity 0.8.19;

import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract UniV3MultiCall {
    struct UniResult {
        bool success;
        uint256 amountOut;
    }

    address public uniQuoter;

    constructor(address _uniQuoter) {
        uniQuoter = _uniQuoter;
    }

    function getAmountsOutUniV3(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 maxAmountIn,
        uint256 numSamples
    ) public returns (uint256[] memory results) {
        uint256 currentGasCost;
        uint256 gasCost;
        results = new uint256[](numSamples);
        address uniV3Quoter = uniQuoter;
        for (uint256 i = 0; i < numSamples; ) {
            currentGasCost = gasleft();
            try
                IQuoter(uniV3Quoter).quoteExactInputSingle(
                    tokenIn,
                    tokenOut,
                    fee,
                    (maxAmountIn * (i + 1)) / numSamples,
                    0
                )
            returns (uint256 amountOut) {
                results[i] = amountOut;
            } catch {
                results[i] = 0;
            }
            unchecked {
                ++i;
            }
            gasCost = currentGasCost - gasleft();
            if (gasCost > 2_000_000 || gasleft() < 5_000_000) {
                break;
            }
        }
    }
}