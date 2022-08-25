// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyPunkGateway {
    event Borrow(
        uint256 indexed reserveId,
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex,
        uint256 loanId
    );
    event Repay(uint256 indexed reserveId, address indexed user, uint256 punkIndex, uint256 loanId);

    event BorrowETH(
        uint256 indexed reserveId,
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex,
        uint256 loanId
    );
    event RepayETH(uint256 indexed reserveId, address indexed user, uint256 punkIndex, uint256 loanId);

    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex
    ) external;

    function repay(uint256 loanId) external;

    function borrowETH(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        uint256 punkIndex
    ) external;

    function repayETH(uint256 loanId) external payable;
}