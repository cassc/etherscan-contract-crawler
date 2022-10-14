pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../interfaces/IMarketRegistry.sol";

contract MarketRegistryMock is IMarketRegistry {
    address marketOwner;

    function initialize(TellerAS _tellerAS) external {}

    function isVerifiedLender(uint256 _marketId, address _lenderAddress)
        public
        returns (bool isVerified_, bytes32 uuid_)
    {
        isVerified_ = true;
    }

    function isMarketClosed(uint256 _marketId) public returns (bool) {
        return false;
    }

    function isVerifiedBorrower(uint256 _marketId, address _borrower)
        public
        returns (bool isVerified_, bytes32 uuid_)
    {
        isVerified_ = true;
    }

    function getMarketOwner(uint256 _marketId) public returns (address) {
        return address(marketOwner);
    }

    function getMarketFeeRecipient(uint256 _marketId) public returns (address) {
        return address(marketOwner);
    }

    function getMarketURI(uint256 _marketId) public returns (string memory) {
        return "url://";
    }

    function getPaymentCycleDuration(uint256 _marketId)
        public
        returns (uint32)
    {
        return 1000;
    }

    function getPaymentDefaultDuration(uint256 _marketId)
        public
        returns (uint32)
    {
        return 1000;
    }

    function getBidExpirationTime(uint256 _marketId) public returns (uint32) {
        return 1000;
    }

    function getMarketplaceFee(uint256 _marketId) public returns (uint16) {
        return 1000;
    }

    function setMarketOwner(address _owner) public {
        marketOwner = _owner;
    }

    function getPaymentType(uint256 _marketId)
        public
        view
        returns (V2Calculations.PaymentType)
    {}

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
    ) public returns (uint256) {}

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) public returns (uint256) {}
}