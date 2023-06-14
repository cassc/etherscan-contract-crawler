// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWorldsRental is IERC165 {
    event WorldRented(uint256 indexed tokenId, address indexed tenant, uint256 payment);
    event RentalPaid(uint256 indexed tokenId, address indexed tenant, uint256 payment);
    event RentalTerminated(uint256 indexed tokenId, address indexed tenant);

    struct WorldRentInfo {
        address tenant;         // rented to, otherwise tenant == 0
        uint32 rentStartTime;   // timestamp in unix epoch
        uint32 rentalPaid;      // total rental paid since the beginning including the deposit
        uint32 paymentAlert;    // alert time before next rent payment in seconds (used by frontend only)
    }

    function isRentActive(uint _tokenId) external view returns(bool);
    function getTenant(uint _tokenId) external view returns(address);
    function rentedByIndex(address _tenant, uint _index) external view returns(uint);
    function isRentable(uint _tokenId) external view returns(bool state);
    function rentalPaidUntil(uint _tokenId) external view returns(uint paidUntil);

    function rentWorld(uint _tokenId, uint32 _paymentAlert, uint32 initialPayment) external;
    function payRent(uint _tokenId, uint32 _payment) external;
    function terminateRental(uint _tokenId) external;
}