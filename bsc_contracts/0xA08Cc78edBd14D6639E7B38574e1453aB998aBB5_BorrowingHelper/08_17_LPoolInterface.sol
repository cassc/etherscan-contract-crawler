// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface LPoolInterface {
    function underlying() external view returns (address);

    function totalBorrows() external view returns (uint);

    function borrowBalanceCurrent(address account) external view returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function borrowBehalf(address borrower, uint borrowAmount) external;

    function repayBorrowBehalf(address borrower, uint repayAmount) external;

    function repayBorrowEndByOpenLev(address borrower, uint repayAmount) external;
}