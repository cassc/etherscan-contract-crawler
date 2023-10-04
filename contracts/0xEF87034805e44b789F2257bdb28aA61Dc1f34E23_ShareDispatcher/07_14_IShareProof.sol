pragma solidity ^0.8.0;
interface IShareProof{
  function heightlist(uint index) external view returns(uint);
  function totalSupplyAt(uint _blockNumber) external view returns(uint);
  function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint);
  function getCheckpointLength() external view returns(uint);
}