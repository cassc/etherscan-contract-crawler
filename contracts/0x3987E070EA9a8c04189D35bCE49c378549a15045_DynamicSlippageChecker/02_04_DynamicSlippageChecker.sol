// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.17;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import {IPriceChecker} from "./interfaces/IPriceChecker.sol";
import {IExpectedOutCalculator} from "./interfaces/IExpectedOutCalculator.sol";

// Like the `FixedSlippageChecker` except the user can pass in their desired
// allowed slippage % dynamically in the _data field. The rest of the _data
// is passed to the price checker.
contract DynamicSlippageChecker is IPriceChecker {
    using SafeMath for uint256;

    string public NAME;
    IExpectedOutCalculator public immutable EXPECTED_OUT_CALCULATOR;

    uint256 internal constant MAX_BPS = 10_000;

    constructor(string memory _name, address _expectedOutCalculator) {
        NAME = _name;
        EXPECTED_OUT_CALCULATOR = IExpectedOutCalculator(_expectedOutCalculator);
    }

    function checkPrice(
        uint256 _amountIn,
        address _fromToken,
        address _toToken,
        uint256,
        uint256 _minOut,
        bytes calldata _data
    ) external view override returns (bool) {
        (uint256 _allowedSlippageInBps, bytes memory _data) = abi.decode(_data, (uint256, bytes));

        uint256 _expectedOut = EXPECTED_OUT_CALCULATOR.getExpectedOut(_amountIn, _fromToken, _toToken, _data);

        return _minOut > _expectedOut.mul(MAX_BPS.sub(_allowedSlippageInBps)).div(MAX_BPS);
    }
}