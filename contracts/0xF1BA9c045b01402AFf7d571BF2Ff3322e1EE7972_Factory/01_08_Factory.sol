// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Buffer2.sol";
contract Factory {
  event ContractDeployed(address indexed deployer, address indexed group);
  address public immutable implementation;
  constructor() {
    implementation = address(new Buffer2 { salt: bytes32(uint(1)) }());
  }
  function genesis(bytes32 _root, bytes32 _cidDigest, bool _cidEncoding, uint _index) external returns (address) {
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, _index));
    address payable clone = payable(Clones.cloneDeterministic(implementation, salt));
    Buffer2 buffer = Buffer2(clone);
    buffer.initialize(_root, _cidDigest, _cidEncoding);
    emit ContractDeployed(msg.sender, clone);
    return clone;
  }
  function find(address creator, uint start, uint count) external view returns (address[] memory) {
    address[] memory addrs = new address[](count);
    for(uint i; i<count; i++) {
      bytes32 salt = keccak256(abi.encodePacked(creator, i+start));
      addrs[i] = Clones.predictDeterministicAddress(
        implementation,
        salt
      );
    }
    return addrs;
  }
}