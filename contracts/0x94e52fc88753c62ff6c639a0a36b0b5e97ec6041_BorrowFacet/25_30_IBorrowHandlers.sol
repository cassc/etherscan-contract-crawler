// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IBorrowCheckers} from "./IBorrowCheckers.sol";

/* solhint-disable-next-line no-empty-blocks */
interface IBorrowHandlers is IBorrowCheckers {
    /// @notice one loan has been initiated
    /// @param loanId id of the loan
    /// @param loan the loan created
    event Borrow(uint256 indexed loanId, bytes loan);
}