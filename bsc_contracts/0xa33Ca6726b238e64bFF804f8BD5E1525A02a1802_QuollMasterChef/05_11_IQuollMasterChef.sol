// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IRewarder.sol";

interface IQuollMasterChef {
    function poolInfo(uint256)
        external
        view
        returns (
            IERC20,
            uint256,
            uint256,
            uint256,
            IRewarder
        );

    function userInfo(uint256 _pid, address _account)
        external
        view
        returns (uint256, uint256);

    function claim(uint256 _pid, address _account) external;

    function deposit(uint256 _pid, uint256 _amount) external;
}