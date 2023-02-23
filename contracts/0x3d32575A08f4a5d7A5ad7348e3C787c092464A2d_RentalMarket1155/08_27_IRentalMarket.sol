// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;
import {RentalPrice} from "../constant/RentalStructs.sol";
import {NFT} from "../constant/BaseStructs.sol";

interface IRentalMarket {
    event OrderCancelled(bytes32 hash);
    event OfferCancelled(bytes32 hash);
    event NonceIncremented(address trader, uint256 newNonce);
    event LendOrderFulfilled(
        bytes32 hash,
        NFT nft,
        RentalPrice price,
        uint256 amount,
        uint256 cycleAmount,
        address lender,
        address renter
    );
    event RentOfferFulfilled(
        bytes32 hash,
        NFT nft,
        RentalPrice price,
        uint256 amount,
        uint256 cycleAmount,
        address lender,
        address renter
    );
}