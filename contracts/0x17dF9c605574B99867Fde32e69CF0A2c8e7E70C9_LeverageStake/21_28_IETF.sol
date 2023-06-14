// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IETF {
  function getController() external view returns (address);

  function adminList(address) external view returns (bool);

  function bPool() external view returns (address);

  function etype() external view returns (uint8);

  function isCompletedCollect() external view returns (bool);

  function _verifyWhiteToken(address token) external view;

  function etfStatus()
    external
    view
    returns (
      uint256 collectPeriod,
      uint256 collectEndTime,
      uint256 closurePeriod,
      uint256 closureEndTime,
      uint256 upperCap,
      uint256 floorCap,
      uint256 managerFee,
      uint256 redeemFee,
      uint256 issueFee,
      uint256 perfermanceFee,
      uint256 startClaimFeeTime
    );

  function execute(
    address _target,
    uint256 _value,
    bytes calldata _data,
    bool isUnderlying
  ) external returns (bytes memory _returnValue);
}

interface ICrpFactory {
  function isCrp(address addr) external view returns (bool);
}

interface IFactory {
  function isPaused() external view returns (bool);
}