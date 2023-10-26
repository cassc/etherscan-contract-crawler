// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IBorrowHandlers} from "./IBorrowHandlers.sol";

import {BorrowArg} from "../DataStructure/Objects.sol";

interface IBorrowFacet is IBorrowHandlers, IERC721Receiver {
    /// @notice `from` transferred its borrow rights on loan of id `loanId` to `to`
    /// @param loanId id of the loan
    /// @param from account that transferred its rights
    /// @param to account that received the rights
    event TransferBorrowRights(uint256 indexed loanId, address indexed from, address indexed to);

    function borrow(BorrowArg[] calldata args) external returns (uint256[] memory loanIds);

    function transferBorrowerRights(uint256 loanId, address newBorrower) external;
}