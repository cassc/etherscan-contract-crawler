// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedPartners {
    function getPartnerPermit(address _partner) external view returns (uint16);
}