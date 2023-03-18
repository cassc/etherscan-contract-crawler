// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IGovernedERC20Storage {
    function setBalance(address _owner, uint256 _amount) external;

    function setAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) external;

    function setTotalSupply(uint256 _amount) external;

    function getBalance(address _account) external view returns (uint256 balance);

    function getAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 allowance);

    function getTotalSupply() external view returns (uint256 totalSupply);
}