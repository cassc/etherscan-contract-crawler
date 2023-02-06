/**
 * @title Interface whitelist
 * @dev IWhitelist contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

interface IWhitelist {
    function isWhitelisted(address _address) external view returns (bool);
}
