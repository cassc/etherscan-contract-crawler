//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GloomersVoucherSigner is Ownable {

  address private _voucherSigner;

  event SetVoucherSigner(address prevVoucherSigner, address newVoucherSigner);

  function setVoucherSigner(address newVoucherSigner) public onlyOwner {
    require(newVoucherSigner != address(0), "Setting voucher signer to 0 address");
    _voucherSigner = newVoucherSigner;
    emit SetVoucherSigner(_voucherSigner, newVoucherSigner);
  }

  function getVoucherSigner() public view returns (address) {
    return _voucherSigner;
  }

  constructor(address voucherSigner) {
    setVoucherSigner(voucherSigner);
  }

}