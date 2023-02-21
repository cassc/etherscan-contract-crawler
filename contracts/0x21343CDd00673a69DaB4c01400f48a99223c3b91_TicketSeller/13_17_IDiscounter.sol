// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IDiscounter {
    function discount(
        address ticketAddress,
        uint256 id,
        uint256 cost,
        address buyer
    ) external view returns (uint256);

    function setDiscount(
        address ticketAddress,
        uint256 id,
        address conditionCollection,
        uint256 rate
    ) external;
}