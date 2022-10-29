// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/Hashflow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Errors.sol";

/**
 * @title HashflowHelper
 * @notice Helper that performs onchain calculation required to call a Haashflow contract and returns corresponding caller and data
 */
abstract contract HashflowHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event AmountExceedsQuote(uint256, uint256);

    function swapHashflow(
        uint256 amount,
        IQuote hashflow,
        IQuote.RFQTQuote memory quote
    ) external returns (address target, bytes memory data) {
        if (amount > quote.maxBaseTokenAmount) {
            emit AmountExceedsQuote(amount, quote.maxBaseTokenAmount);
        }
        quote.effectiveBaseTokenAmount = amount;
        bytes memory resultData = abi.encodeWithSelector(hashflow.tradeSingleHop.selector, quote);
        return (address(hashflow), resultData);
    }
}