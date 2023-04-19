// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTRental is IERC165 {
    event Rented(
        uint256 indexed tokenId,
        address indexed tenant,
        uint256 payment
    );
    event RentPaid(
        uint256 indexed tokenId,
        address indexed tenant,
        uint256 payment
    );
    event RentTerminated(uint256 indexed tokenId, address indexed tenant);

    struct RentInformation {
        address tenant; // rented to, otherwise tenant == 0
        uint32 rentStartTime; // timestamp in unix epoch
        uint256 rentalPaid; // total rental paid since the beginning including the deposit
    }

    function isRentActive(uint256 _tokenId) external view returns (bool);

    function getRentInformation(
        uint256 _tokenId
    ) external view returns (RentInformation memory);

    function isRentable(uint256 _tokenId) external view returns (bool state);

    function rentalPaidUntil(
        uint256 _tokenId
    ) external view returns (uint256 paidUntil);

    function startRent(uint256 _tokenId, uint256 _initialPayment) external;

    function payRent(uint256 _tokenId, uint256 _payment) external;

    function terminateRent(uint256 _tokenId) external;
}