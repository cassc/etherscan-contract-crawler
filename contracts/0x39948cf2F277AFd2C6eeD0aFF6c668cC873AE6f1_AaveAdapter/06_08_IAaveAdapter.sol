// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAaveAdapter {
    function doFlashLoan(address _token, uint256 _amountDesired, bytes memory _data) external;
}