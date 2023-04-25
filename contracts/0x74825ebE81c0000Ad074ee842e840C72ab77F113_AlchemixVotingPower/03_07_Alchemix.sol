// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IAlchemixToken {
    /* --- IERC20 --- */
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address recipient, uint256 amount) external;
    /* --- AccessControl --- */
    function MINTER_ROLE() external pure returns (bytes32);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}

interface IStakingPool {
    function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256);
    function deposit(uint256 _poolId, uint256 _depositAmount) external;
}

interface IgALCX {
    function balanceOf(address account) external view returns (uint256);
    function exchangeRate() external view returns (uint256);
    function exchangeRatePrecision() external view returns (uint256);
    function stake(uint256 amount) external;
}