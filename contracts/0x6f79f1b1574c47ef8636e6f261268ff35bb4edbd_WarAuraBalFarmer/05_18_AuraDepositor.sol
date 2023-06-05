pragma solidity ^0.8.10;

interface CrvDepositorWrapper {
  function BAL() external view returns (address);
  function BALANCER_POOL_TOKEN() external view returns (address);
  function BALANCER_VAULT() external view returns (address);
  function BAL_ETH_POOL_ID() external view returns (bytes32);
  function WETH() external view returns (address);
  function crvDeposit() external view returns (address);
  function deposit(uint256 _amount, uint256 _minOut, bool _lock, address _stakeAddress) external;
  function getMinOut(uint256 _amount, uint256 _outputBps) external view returns (uint256);
  function setApprovals() external;
}