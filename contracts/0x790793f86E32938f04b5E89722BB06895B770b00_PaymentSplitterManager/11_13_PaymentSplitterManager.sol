// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./access/AdminControl.sol";
import "./PaymentSplitterCloneable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract PaymentSplitterManager is AdminControl {
  address public immutable splitterImplementationAddress;
  address[] public splitters;

  event SplitterRegistered (
    address splitterAddress,
    address[] recipients,
    uint256[] shares
  );

  constructor(address _splitterImplementationAddress) {
    splitterImplementationAddress = _splitterImplementationAddress;
    splitters = new address[](0);
  }

  function cloneSplitter (
    address[] calldata _recipients,
    uint256[] calldata _shares
  ) public onlyAdmin returns (address) {
      address _clonedSplitter = Clones.clone(splitterImplementationAddress);
      IPaymentSplitterCloneable(payable(_clonedSplitter)).initialize(_recipients, _shares);
      splitters.push(_clonedSplitter);

      emit SplitterRegistered(_clonedSplitter, _recipients, _shares);

      return _clonedSplitter;
  }

  function registerExistingSplitter (
    address _splitterAddress,
    address[] calldata _recipients,
    uint256[] calldata _shares
  ) public onlyAdmin {
    splitters.push(_splitterAddress);

    emit SplitterRegistered(_splitterAddress, _recipients, _shares);
  }
}