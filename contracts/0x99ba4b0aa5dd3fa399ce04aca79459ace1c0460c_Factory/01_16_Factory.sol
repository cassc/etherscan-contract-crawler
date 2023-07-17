// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.13;
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./C0.sol";
contract Factory is OwnableUpgradeable {
  address public immutable implementation;
  constructor() {
    implementation = address(new C0 { salt: bytes32(uint(1)) }());
    __Ownable_init();
  }
  function genesis(uint _index, string calldata name, string calldata symbol) external payable returns (address) {
    bytes32 salt = keccak256(abi.encodePacked(_msgSender(), _index));
    address payable clone = payable(ClonesUpgradeable.cloneDeterministic(implementation, salt));
    C0 token = C0(clone);
    token.initialize(name, symbol);
    token.transferOwnership(_msgSender());
    return clone;
  }
  function find(address creator, uint start, uint count) external view returns (address[] memory) {
    address[] memory addrs = new address[](count);
    for(uint i; i<count; i++) {
      bytes32 salt = keccak256(abi.encodePacked(creator, i+start));
      addrs[i] = ClonesUpgradeable.predictDeterministicAddress(
        implementation,
        salt
      );
    }
    return addrs;
  }
}