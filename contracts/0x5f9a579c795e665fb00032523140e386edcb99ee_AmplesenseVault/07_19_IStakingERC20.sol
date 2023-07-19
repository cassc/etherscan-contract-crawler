// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

interface IStakingERC20  {
    function staking_contract_token() external returns (address);
    function distribute_eth() payable external;
    function distribute(uint256 amount) external;
    function stake(uint256 amount, bytes calldata data) external;
    function stakeFor(address account, uint256 amount, bytes calldata data) external;
    function unstake(uint256 amount, bytes calldata data) external;
    function withdraw(uint256 amount) external;
    function totalStakedFor(address account) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function token() external view returns (address);
    function supportsHistory() external pure returns (bool);
    function getReward(address account) external view returns (uint256 _eth, uint256 _token);
}