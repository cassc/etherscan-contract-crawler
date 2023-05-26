// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ISeretanMinter.sol";

abstract contract SeretanMintableFix {
  address private minter;

  constructor(
    address minter_,
    ISeretanMinter.Phase[] memory phaseList_
  )
  {
    minter = minter_;
    ISeretanMinter(minter).setPhaseList(address(this), phaseList_);
  }

  function setMinter(
    address minter_
  )
    public
    virtual
  {
    require(msg.sender == owner());

    _setMinter(minter_);
  }

  function _setMinter(
    address minter_
  )
    internal
    virtual
  {
    minter = minter_;
  }

  function safeMint(
    address to,
    uint256 tokenId
  )
    public
    virtual
  {
    require(msg.sender == minter);

    _safeMint(to, tokenId);
  }

  function _safeMint(address to, uint256 tokenId) internal virtual;

  function owner() public view virtual returns (address);
}