// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IApeToken {
    function underlying() external view returns (address);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrow(address payable borrower, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrow(address borrower, uint256 repayAmount)
        external
        returns (uint256);
}