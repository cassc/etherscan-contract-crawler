//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "./mixins/FlashLoanAave.sol";

abstract contract FlashLoanAggregator is FlashLoanAave {
    function flashLoan(bytes calldata _params, uint256 _borrowAmount) internal {
        _flashLoanAave(_params, _borrowAmount);
    }
}