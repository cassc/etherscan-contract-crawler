// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "./IWhitelist.sol";

/// @title IWhitelistHandler

interface IWhitelistHandler {
    /**
     * @param _whitelist the contract that implements IWhitelist
     */
    function setWhitelist(IWhitelist _whitelist) external;
}