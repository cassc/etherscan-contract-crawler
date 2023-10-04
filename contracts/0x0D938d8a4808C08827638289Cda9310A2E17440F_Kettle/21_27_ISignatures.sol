// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LoanOffer, BorrowOffer } from "../lib/Structs.sol";

interface ISignatures {
    function information()
        external
        view
        returns (string memory version, bytes32 domainSeparator);

    function getLoanOfferHash(
        LoanOffer calldata offer
    ) external view returns (bytes32);

    function getBorrowOfferHash(
        BorrowOffer calldata offer
    ) external view returns (bytes32);

    function cancelledOrFulfilled(
        address user,
        uint256 salt
    ) external view returns (uint256);

    function nonces(address user) external view returns (uint256);
}