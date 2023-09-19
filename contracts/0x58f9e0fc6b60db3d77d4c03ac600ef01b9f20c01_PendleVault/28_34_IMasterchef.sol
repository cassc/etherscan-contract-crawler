// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IMasterchef {
    function deposit(uint256, uint256) external;

    function withdraw(uint256, uint256) external;

    function userInfo(uint256, address) external view returns (uint256, uint256);

    function poolInfo(uint256) external returns (address, uint256, uint256, uint256);

    function totalAllocPoint() external view returns (uint256);

    function sdtPerBlock() external view returns (uint256);

    function pendingSdt(uint256, address) external view returns (uint256);

    function owner() external view returns (address);

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external;

    function poolLength() external view returns (uint256);
}