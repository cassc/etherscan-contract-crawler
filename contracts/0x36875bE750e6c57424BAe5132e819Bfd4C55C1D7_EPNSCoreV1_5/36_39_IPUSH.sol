pragma solidity >=0.6.0 <0.7.0;

interface IPUSH {
  function born() external view returns(uint);
  function totalSupply() external view returns(uint);
  function resetHolderWeight(address holder) external;
  function returnHolderUnits(address account, uint atBlock) external view returns (uint);
}