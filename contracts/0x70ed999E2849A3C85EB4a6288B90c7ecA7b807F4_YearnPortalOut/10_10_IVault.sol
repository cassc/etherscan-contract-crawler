/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IVault {
    function deposit(uint256 _amount) external payable;

    function withdraw(uint256 _amount) external;

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);
}