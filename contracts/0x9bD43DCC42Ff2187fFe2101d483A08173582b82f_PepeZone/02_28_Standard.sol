// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";

contract StandardZone is BaseZone {
  string public baseURI;

  constructor(
    address admin,
    bytes32 origin,
    string memory name,
    string memory symbol,
    string memory baseTokenURI
  ) BaseZone(admin, origin, name, symbol) {
    _setBaseURI(baseTokenURI);
  }

  function setBaseURI(string memory base) public {
    require(
      _isApprovedOrOwner(_msgSender(), uint256(getOrigin())),
      "must own zone"
    );
    _setBaseURI(base);
  }

  // function contractURI() public view returns (string memory) {
  //   return tokenURI(uint256(getOrigin()));
  // }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _setBaseURI(string memory base) internal virtual {
    baseURI = base;
  }
}