/**
 * @title Interface Sale
 * @dev ISale.sol contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity =0.6.12;

interface ISale {
    function getTokens(address account, address sponsor) external;
}