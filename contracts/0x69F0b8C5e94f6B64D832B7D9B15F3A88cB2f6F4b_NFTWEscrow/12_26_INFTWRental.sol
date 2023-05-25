// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTWRental is IERC165 {
    event WorldRented(uint256 indexed tokenId, address indexed tenant, uint256 payment);
    event RentalPaid(uint256 indexed tokenId, address indexed tenant, uint256 payment);
    event RentalTerminated(uint256 indexed tokenId, address indexed tenant);

    struct WorldRentInfo {
        address tenant;         // rented to, otherwise tenant == 0
        uint32 rentStartTime;   // timestamp in unix epoch
        uint32 rentalPaid;      // total rental paid since the beginning including the deposit
        uint32 paymentAlert;    // alert time before next rent payment in seconds (used by frontend only)
    }

    function isRentActive(uint tokenId) external view returns(bool);
    function getTenant(uint tokenId) external view returns(address);
    function rentedByIndex(address tenant, uint index) external view returns(uint);
    function isRentable(uint tokenId) external view returns(bool state);
    function rentalPaidUntil(uint tokenId) external view returns(uint paidUntil);

    function rentWorld(uint tokenId, uint32 _paymentAlert, uint32 initialPayment) external;
    function payRent(uint tokenId, uint32 payment) external;
    function terminateRental(uint tokenId) external;

}