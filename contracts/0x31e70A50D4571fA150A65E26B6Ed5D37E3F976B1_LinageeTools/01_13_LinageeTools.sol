// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILinagee {
  function transfer (bytes32 nameId, address receiver) external;
  function reserve (bytes32 nameId) external;
  function owner (bytes32 nameId) view external returns(address);
}

interface ILinageeWrapper {
  function nameToId(bytes32) external returns (uint256);
  function wrap(bytes32) external;
  function transferFrom(address,address,uint256) external;
  function createWrapper(bytes32) external;
}

contract LinageeTools is Ownable {

  ILinagee public constant linagee = ILinagee(0x5564886ca2C518d1964E5FCea4f423b41Db9F561);
  ILinageeWrapper public constant erlw = ILinageeWrapper(0x2Cc8342d7c8BFf5A213eb2cdE39DE9a59b3461A7);
  address public dev;
  uint256 public tip = 0.002 ether;
  mapping (bytes32 => address) public namesToOwners;

  constructor(address _dev) {
    super.transferOwnership(msg.sender);
    dev = _dev;
  }

  function reserveAndMintErc721(bytes32 _name) public payable {
    require(msg.value >= tip, ":(");
    require(linagee.owner(_name) == address(0), "taken");
    linagee.reserve(_name);
    erlw.createWrapper(_name);
    linagee.transfer(_name, address(erlw));
    erlw.wrap(_name);
    erlw.transferFrom(address(this), msg.sender, erlw.nameToId(_name));
  }

  function recordOwnership(bytes32[] calldata _names) public {
    uint256 numNames = _names.length;
    require(numNames <= 10, "max 10 names");
    uint i;
    for (;i < numNames;) {
      require(linagee.owner(_names[i]) == msg.sender);
      namesToOwners[_names[i]] = msg.sender;
      unchecked {++i;}
    }
  }

  function bulkMintToERC721(bytes32[] calldata _names) public payable {
    require(msg.value >= tip * _names.length, ":(");
    uint256 numNames = _names.length;
    require(numNames <= 10, "max 10 names");
    uint i;
    for (;i < numNames;) {
      bytes32 _name = _names[i];
      require(namesToOwners[_name] == msg.sender, "not recorded as owner");
      delete namesToOwners[_name];
      require(linagee.owner(_name) == address(this), "not transferred yet");
      erlw.createWrapper(_name);
      linagee.transfer(_name, address(erlw));
      erlw.wrap(_name);
      erlw.transferFrom(address(this), msg.sender, erlw.nameToId(_name));
      unchecked {++i;}
    }
  }

  function payout() external {
    uint256 bal = address(this).balance;
    payable(owner()).transfer(bal/2);
    payable(dev).transfer(bal/2);
  }

  function updateDevAddress(address _dev) external {
    require(msg.sender == dev, "shoo");
    dev = _dev;
  }

  function setTip(uint256 _tip) external {
    require(msg.sender == owner() || msg.sender == dev, "shoo");
    tip = _tip;
  }
}