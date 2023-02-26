// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/Hashflow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title HashflowHelper
 * @notice Helper that performs onchain calculation required to call a Haashflow contract and returns corresponding caller and data
 */
abstract contract HashflowHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapHashflow(
        uint256 amount,
        IQuote hashflow,
        IQuote.RFQTQuote memory quote
    ) external pure returns (address target, address sourceTokenInteractionTarget, uint256 valueLimit, bytes memory data) {
        if (amount > quote.maxBaseTokenAmount) {
            quote.effectiveBaseTokenAmount = quote.maxBaseTokenAmount;
        } else {
            quote.effectiveBaseTokenAmount = amount;
        }
        bytes memory resultData = abi.encodeCall(hashflow.tradeSingleHop, quote);
        return (address(hashflow), address(hashflow), quote.effectiveBaseTokenAmount, resultData);
    }
}