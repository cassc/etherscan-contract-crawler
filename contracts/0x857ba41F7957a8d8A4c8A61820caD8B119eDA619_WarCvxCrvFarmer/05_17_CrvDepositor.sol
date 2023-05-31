pragma solidity ^0.8.10;

interface CrvDepositor {
  function FEE_DENOMINATOR() external view returns (uint256);
  function crv() external view returns (address);
  function deposit(uint256 _amount, bool _lock, address _stakeAddress) external;
  function deposit(uint256 _amount, bool _lock) external;
  function depositAll(bool _lock, address _stakeAddress) external;
  function escrow() external view returns (address);
  function feeManager() external view returns (address);
  function incentiveCrv() external view returns (uint256);
  function initialLock() external;
  function lockCurve() external;
  function lockIncentive() external view returns (uint256);
  function minter() external view returns (address);
  function setFeeManager(address _feeManager) external;
  function setFees(uint256 _lockIncentive) external;
  function staker() external view returns (address);
  function unlockTime() external view returns (uint256);
}