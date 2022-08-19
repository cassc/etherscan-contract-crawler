pragma solidity ^0.8.0;

interface IFactory {
  struct TimelockObject {
    bytes32 _id;
    uint256 _amount;
    address _creator;
    address _recipient;
    address _token;
    uint256 _lockedUntil;
    uint256 _fee;
  }

  event TimelockObjectCreated(
    bytes32 _id,
    uint256 _amount,
    address _creator,
    address _recipient,
    address _token,
    uint256 _lockedUntil,
    uint256 _fee
  );

  event TimelockProcessed(bytes32 _id);
  event TimelockCancelled(bytes32 _id);

  function _allTimelocks(uint256) external view returns (bytes32);
}