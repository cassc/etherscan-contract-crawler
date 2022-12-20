//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ShadowPassAuthority is Ownable {

  address private _shadowSigner;

  event SetShadowSigner(address prevShadowSigner, address newShadowSigner);

  function setShadowSigner(address newShadowSigner) public onlyOwner {
    require(newShadowSigner != address(0), "Not Allowed");
    _shadowSigner = newShadowSigner;
    emit SetShadowSigner(_shadowSigner, newShadowSigner);
  }

  function getShadowSigner() public view returns (address) {
    return _shadowSigner;
  }

  constructor(address shadowSigner) {
    setShadowSigner(shadowSigner);
  }

}