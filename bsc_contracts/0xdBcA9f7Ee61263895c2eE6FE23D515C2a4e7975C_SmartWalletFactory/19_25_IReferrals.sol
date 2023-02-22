// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IReferrals {
    function sponsor(address) external view returns (address);

    function registerInvite(address _user, address _sponsor) external;
}