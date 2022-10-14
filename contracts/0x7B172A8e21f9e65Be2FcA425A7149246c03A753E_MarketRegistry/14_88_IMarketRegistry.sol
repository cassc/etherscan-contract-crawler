// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { V2Calculations } from "../TellerV2.sol";
import "../EAS/TellerAS.sol";

interface IMarketRegistry {
    function initialize(TellerAS tellerAs) external;

    function isVerifiedLender(uint256 _marketId, address _lender)
        external
        returns (bool, bytes32);

    function isMarketClosed(uint256 _marketId) external returns (bool);

    function isVerifiedBorrower(uint256 _marketId, address _borrower)
        external
        returns (bool, bytes32);

    function getMarketOwner(uint256 _marketId) external returns (address);

    function getMarketFeeRecipient(uint256 _marketId)
        external
        returns (address);

    function getMarketURI(uint256 _marketId) external returns (string memory);

    function getPaymentCycleDuration(uint256 _marketId)
        external
        returns (uint32);

    function getPaymentDefaultDuration(uint256 _marketId)
        external
        returns (uint32);

    function getBidExpirationTime(uint256 _marketId) external returns (uint32);

    function getMarketplaceFee(uint256 _marketId) external returns (uint16);

    function getPaymentType(uint256 _marketId)
        external
        view
        returns (V2Calculations.PaymentType);

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) external returns (uint256 marketId_);

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) external returns (uint256 marketId_);
}