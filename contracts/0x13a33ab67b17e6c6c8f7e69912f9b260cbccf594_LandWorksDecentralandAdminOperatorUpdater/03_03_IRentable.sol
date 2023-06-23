// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRentable {
    /// @notice Emitted once a referrer accrues referral fees
    event AccrueReferralFee(
        uint256 indexed _assetId,
        uint256 _rentId,
        address indexed _referrer,
        address indexed _paymentToken,
        uint256 _fee
    );

    /// @notice Emitted once a given asset has been rented
    event Rent(
        uint256 indexed _assetId,
        uint256 _rentId,
        address indexed _renter,
        uint256 _start,
        uint256 _end,
        address indexed _paymentToken,
        uint256 _rent,
        uint256 _protocolFee
    );
}