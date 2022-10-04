/**
 * @title Interface Referrals
 * @dev IReferrals contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity =0.8.11;

interface IReferrals {
    function getSponsor(address account) external view returns (address);

    function membersList(uint256) external view returns (address);
}
