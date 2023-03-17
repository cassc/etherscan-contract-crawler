// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../EAS/TellerAS.sol";
import { PaymentType, PaymentCycleType } from "../libraries/V2Calculations.sol";

interface IMarketRegistry {
    function initialize(TellerAS tellerAs) external;

    function isVerifiedLender(uint256 _marketId, address _lender)
        external
        view
        returns (bool, bytes32);

    function isMarketClosed(uint256 _marketId) external view returns (bool);

    function isVerifiedBorrower(uint256 _marketId, address _borrower)
        external
        view
        returns (bool, bytes32);

    function getMarketOwner(uint256 _marketId) external view returns (address);

    function getMarketFeeRecipient(uint256 _marketId)
        external
        view
        returns (address);

    function getMarketURI(uint256 _marketId)
        external
        view
        returns (string memory);

    function getPaymentCycle(uint256 _marketId)
        external
        view
        returns (uint32, PaymentCycleType);

    function getPaymentDefaultDuration(uint256 _marketId)
        external
        view
        returns (uint32);

    function getBidExpirationTime(uint256 _marketId)
        external
        view
        returns (uint32);

    function getMarketplaceFee(uint256 _marketId)
        external
        view
        returns (uint16);

    function getPaymentType(uint256 _marketId)
        external
        view
        returns (PaymentType);

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        PaymentType _paymentType,
        PaymentCycleType _paymentCycleType,
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