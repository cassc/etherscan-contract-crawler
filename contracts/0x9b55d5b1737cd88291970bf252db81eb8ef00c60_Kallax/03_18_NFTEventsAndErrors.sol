// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17.0;

import { ERC721A } from "@erc721a/ERC721A.sol";

interface NFTEventsAndErrors {
    error InsufficientPayment();
    error MaxSupplyReached();
    error MaxForAddressForMintStageReached();
}