// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IFeeCollector } from "./IFeeCollector.sol";
import { Address } from "../library/Address.sol";
import { IFees } from "./IFees.sol";
import { OwnableV2 } from "../Control/OwnableV2.sol";

abstract contract FeeCollector is IFeeCollector, OwnableV2 {
  using Address for address payable;

  IFees internal _fees;

  uint256 internal _feePercentDenominator = 10 ** 18;

  modifier takeFee(string memory feeType) {
    bool exempt = _fees.isAddressExemptFromFees(_msgSender());
    require(exempt || _fees.getFeeAmountForType(feeType) == msg.value, "Incorrect fee");
    if (!exempt)
      payable(address(_fees)).sendValue(msg.value);
    _;
  }

  function feesContract() external view override returns (address) {
    return address(_fees);
  }

  function _setFeesContract(address contractAddress) internal virtual {
    _fees = IFees(contractAddress);
  }

  function setFeesContract(address contractAddress) external override onlyOwner {
    _setFeesContract(contractAddress);
  }

  function feePercentDenominator() external view override returns (uint256) {
    return _feePercentDenominator;
  }

  function setFeePercentDenominator(uint256 value) external virtual override onlyOwner {
    _feePercentDenominator = value;
  }

  function _getFeePercentInRange(
    string memory minFeeType,
    string memory maxFeeType,
    uint256 input,
    uint256 percent
  ) internal virtual view returns (uint256) {
    uint256 feeMin = _fees.getFeeAmountForType(minFeeType);
    uint256 feeMax = _fees.getFeeAmountForType(maxFeeType);

    uint256 feeAmount = feeMin;
    feeAmount += (feeMax - feeMin) * percent / _feePercentDenominator;

    return input * feeAmount / _feePercentDenominator;
  }

  function getFeePercentInRange(
    string memory minFeeType,
    string memory maxFeeType,
    uint256 input,
    uint256 percent
  ) external view override returns (uint256) {
    return _getFeePercentInRange(minFeeType, maxFeeType, input, percent);
  }

  function _takeFeePercentInRange(
    string memory minFeeType,
    string memory maxFeeType,
    uint256 amount,
    uint256 percent
  ) internal virtual {
    require(
      _getFeePercentInRange(minFeeType, maxFeeType, amount, percent) == msg.value,
      "Incorrect fee"
    );

    if (!_fees.isAddressExemptFromFees(_msgSender()))
      payable(address(_fees)).sendValue(msg.value);
  }
}