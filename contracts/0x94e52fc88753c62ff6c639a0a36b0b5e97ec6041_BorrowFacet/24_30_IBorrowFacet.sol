// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IBorrowHandlers} from "./IBorrowHandlers.sol";

import {BorrowArg} from "../DataStructure/Objects.sol";

interface IBorrowFacet is IBorrowHandlers, IERC721Receiver {
    function borrow(BorrowArg[] calldata args) external;
}