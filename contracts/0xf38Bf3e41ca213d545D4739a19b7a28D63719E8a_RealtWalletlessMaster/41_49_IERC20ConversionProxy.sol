// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20ConversionProxy {
    function transferFromWithReferenceAndFee(
    address _to,
    uint256 _requestAmount,
    address[] calldata _path,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress,
    uint256 _maxToSpend,
    uint256 _maxRateTimespan
  ) external;
}