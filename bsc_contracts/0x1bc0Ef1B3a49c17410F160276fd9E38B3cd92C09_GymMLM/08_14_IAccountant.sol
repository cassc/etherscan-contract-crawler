// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAccountant {
    function updateBorrowedAmount(
        address _userAddress,
        uint256 _amount,
        uint256 _type,
        bool _increase
    ) external;

    function getUserBorrowedAmount(address _userAddress, uint256 _type)
        external
        view
        returns (uint256);
}