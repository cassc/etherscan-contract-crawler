pragma solidity >=0.6.6;

interface ICopycatEmergencyAllower {
  function isAllowed(bytes32 txHash) external view returns(bool);
  function beforeExecute(bytes32 txHash) external;
  function afterExecute(bytes32 txHash) external;
}