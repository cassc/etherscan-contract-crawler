// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

interface IPositionTracker {

    struct Entry {
        bytes32 id;
        bytes32 prev;
        bytes32 next;
        address user;
        address pool;
    }

    error PositionIsAlreadyOpen();
    error PositionNotFound();
    error ZeroAddress();
    error NotAPool();
    error NotFactoryOrPool();
    
    function openBorrowPosition(address _borrower, address _pool) external;
    function openLendPosition(address _lender, address _pool) external;
    function closeBorrowPosition(address _borrower) external;
    function closeLendPosition(address _lender) external;
}