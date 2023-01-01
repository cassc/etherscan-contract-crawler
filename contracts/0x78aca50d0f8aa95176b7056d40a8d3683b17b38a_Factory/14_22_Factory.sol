// SPDX-License-Identifier: BUSL-1.1
// Factory v0.4.0
//
// 8888888888                888
// 888                       888
// 888                       888
// 8888888  8888b.   .d8888b 888888 .d88b.  888d888 888  888
// 888         "88b d88P"    888   d88""88b 888P"   888  888
// 888     .d888888 888      888   888  888 888     888  888
// 888     888  888 Y88b.    Y88b. Y88..88P 888     Y88b 888
// 888     "Y888888  "Y8888P  "Y888 "Y88P"  888      "Y88888
//                                                       888
//                                                  Y8b d88P
//                                                   "Y88P"

pragma solidity ^0.8.4;

import "./Archetype.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Factory is OwnableUpgradeable {
  event CollectionAdded(address indexed sender, address indexed receiver, address collection);
  address public archetype;

  function initialize(address archetype_) public initializer {
    archetype = archetype_;
    __Ownable_init();
  }

  /// @notice config is a struct in the shape of {string placeholder; string base; uint64 supply; bool permanent;}
  function createCollection(
    address _receiver,
    string memory name,
    string memory symbol,
    Archetype.Config calldata config
  ) external payable returns (address) {
    address clone = ClonesUpgradeable.clone(archetype);
    Archetype token = Archetype(clone);
    token.initialize(name, symbol, config, _receiver);

    token.transferOwnership(_receiver);
    if (msg.value > 0) {
      (bool sent, ) = payable(_receiver).call{ value: msg.value }("");
      require(sent, "1");
    }
    emit CollectionAdded(_msgSender(), _receiver, clone);
    return clone;
  }

  function setArchetype(address archetype_) public onlyOwner {
    archetype = archetype_;
  }
}