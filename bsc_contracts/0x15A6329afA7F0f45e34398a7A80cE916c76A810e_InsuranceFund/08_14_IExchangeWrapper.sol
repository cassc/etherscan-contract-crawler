// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "../utils/Decimal.sol";

interface IExchangeWrapper {
    function swapInput(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata inputTokenSold,
        Decimal.decimal calldata minOutputTokenBought
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata outputTokenBought,
        Decimal.decimal calldata maxInputTokeSold
    ) external returns (Decimal.decimal memory);

    function getInputPrice(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata inputTokenSold
    ) external view returns (Decimal.decimal memory);

    function getOutputPrice(
        IERC20 inputToken,
        IERC20 outputToken,
        Decimal.decimal calldata outputTokenBought
    ) external view returns (Decimal.decimal memory);

    function getSpotPrice(IERC20 inputToken, IERC20 outputToken)
        external
        view
        returns (Decimal.decimal memory);
}