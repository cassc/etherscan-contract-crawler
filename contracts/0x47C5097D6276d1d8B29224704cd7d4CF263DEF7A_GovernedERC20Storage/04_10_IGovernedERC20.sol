// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IGovernedERC20 {
    function erc20Storage() external view returns (address _erc20Storage);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (bool);
}