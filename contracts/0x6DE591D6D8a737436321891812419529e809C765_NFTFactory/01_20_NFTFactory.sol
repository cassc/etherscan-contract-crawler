// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./OriginNFT.sol";
import "./CloneFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTFactory is Ownable, CloneFactory {
  address public target;

  event OriginNFTCreated(address newOriginNFT);

  constructor(address _target) {
    target = _target;
  }

  function setTarget(address _target) public onlyOwner {
    target = _target;
  }

  function createOriginNFT(
    string memory _name,
    string memory _token,
    string memory _baseURI,
    address _owner
  ) public onlyOwner returns (address) {
    address clone = createClone(target);
    string memory _fullURI = string(
      abi.encodePacked(_baseURI, Strings.toHexString(uint160(clone), 20), "/")
    );
    OriginNFT(clone).init(_name, _token, _fullURI, _owner);
    emit OriginNFTCreated(clone);
    return clone;
  }
}