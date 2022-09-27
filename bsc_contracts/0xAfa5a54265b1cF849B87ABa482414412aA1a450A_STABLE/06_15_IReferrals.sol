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

pragma solidity 0.6.12;

interface IReferrals {
    function getSponsor(address account) external view returns (address);
}
