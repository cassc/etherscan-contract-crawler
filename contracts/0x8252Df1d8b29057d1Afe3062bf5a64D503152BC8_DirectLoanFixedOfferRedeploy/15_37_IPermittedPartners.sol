// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IPermittedPartners {
    function getPartnerPermit(address _partner) external view returns (uint16);
}