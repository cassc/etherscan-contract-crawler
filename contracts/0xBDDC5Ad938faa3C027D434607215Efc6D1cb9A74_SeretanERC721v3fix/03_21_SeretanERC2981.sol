// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SeretanERC2981 is Ownable, ERC2981 {
  uint96 private feeNumerator;

  constructor(
    uint96 feeNumerator_
  )
  {
    _setDefaultRoyalty(msg.sender, feeNumerator_);
    feeNumerator = feeNumerator_;
  }

  function setFeeNumerator(
    uint96 feeNumerator_
  )
    public
    virtual
    onlyOwner
  {
    _setFeeNumerator(feeNumerator_);
  }

  function _setFeeNumerator(
    uint96 feeNumerator_
  )
    internal
    virtual
  {
    _setDefaultRoyalty(owner(), feeNumerator_);
    feeNumerator = feeNumerator_;
  }

  function _transferOwnership(
    address newOwner
  )
    internal
    override
    virtual
  {
    _setDefaultRoyalty(newOwner, feeNumerator);
    super._transferOwnership(newOwner);
  }
}