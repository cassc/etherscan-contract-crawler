// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISignatures } from "./ISignatures.sol";

interface IOfferController is ISignatures {
    event LoanOfferTaken(
        bytes32 offerHash,
        uint256 lienId,
        address lender,
        address borrower,
        address currency,
        uint8 collateralType,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 borrowAmount,
        uint256 netBorrowAmount,
        uint256 rate,
        uint256 duration,
        uint256 startTime
    );

    event OfferCancelled(address indexed user, uint256 salt);

    event NonceIncremented(address indexed user, uint256 newNonce);

    function amountTaken(bytes32 offerHash) external view returns (uint256);

    function cancelOffer(uint256 salt) external;

    function cancelOffers(uint256[] calldata salts) external;

    function incrementNonce() external;
}