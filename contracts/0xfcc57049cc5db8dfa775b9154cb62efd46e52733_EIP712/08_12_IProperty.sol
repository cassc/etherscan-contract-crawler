// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IProperty {
    struct CancellationPolicy {
        uint256 expireAt;
        uint256 refundAmount;
    }

    struct InsuranceInfo {
        uint256 damageProtectionFee;
        address feeReceiver;
        KygStatus kygStatus;
    }

    struct BookingInfo {
        uint256 checkIn;
        uint256 checkOut;
        uint256 balance;
        uint256 feeNumerator;
        uint256 referralFeeNumerator;
        address guest;
        address paymentToken;
        address paymentReceiver;
        address referrer;
        BookingStatus status;
        CancellationPolicy[] policies;
    }

    enum BookingStatus {
        IN_PROGRESS,
        PARTIAL_PAID,
        FULLY_PAID,
        GUEST_CANCELLED,
        HOST_CANCELLED,
        PENDING_INSURANCE_FEE
    }

    enum KygStatus {
        IN_PROGRESS,
        PASSED,
        FAILED
    }

    struct BookingSetting {
        uint256 bookingId;
        uint256 checkIn;
        uint256 checkOut;
        uint256 expireAt;
        uint256 bookingAmount;
        address paymentToken;
        address referrer;
        address guest;
        address property;
        InsuranceInfo insuranceInfo;
        CancellationPolicy[] policies;
    }

    function init(
        uint256 _propertyId,
        address _host,
        address _management,
        address _delegate
    ) external;

    function grantAuthorized(address _addr) external;

    function revokeAuthorized(address _addr) external;

    function updateHost(address _addr) external;

    function updatePaymentReceiver(address _addr) external;

    function book(BookingSetting calldata _setting, bytes calldata _signature)
        external
        payable;

    function cancel(uint256 _bookingId) external;

    function payout(uint256 _bookingId) external;

    function cancelByHost(uint256 _bookingId) external;

    function getBookingById(uint256 _id) external returns (BookingInfo memory);

    function getInsuranceInfoById(uint256 _id)
        external
        returns (InsuranceInfo memory);

    function totalBookings() external view returns (uint256);

    event NewHost(address indexed host);

    event NewPaymentReceiver(address indexed paymentReceiver);

    event NewBooking(
        address indexed guest,
        uint256 indexed bookingId,
        uint256 bookedAt
    );

    event GuestCancelled(
        address indexed guest,
        uint256 indexed bookingId,
        uint256 cancelledAt,
        uint256 guestAmount,
        uint256 hostAmount,
        uint256 treasuryAmount,
        uint256 referrerAmount
    );

    event HostCancelled(
        address indexed host,
        uint256 indexed bookingId,
        uint256 cancelledAt,
        uint256 guestAmount
    );

    event PayOut(
        address indexed guest,
        uint256 indexed bookingId,
        uint256 payAt,
        uint256 hostAmount,
        uint256 treasuryAmount,
        uint256 referrerAmount,
        BookingStatus status
    );

    event InsuranceFeeCollected(
        address indexed receiver,
        uint256 indexed bookingId,
        uint256 collectAt,
        uint256 feeAmount
    );

    event GrantAuthorized(address indexed addr);

    event RevokeAuthorized(address indexed addr);
}