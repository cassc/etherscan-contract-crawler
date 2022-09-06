pragma solidity >=0.4.21 <0.6.0;
contract OwnerProxyInterface{
  function ownerOf(bytes32 hash) public view returns(address);
  function initOwnerOf(bytes32 hash, address owner) external returns(bool);
}