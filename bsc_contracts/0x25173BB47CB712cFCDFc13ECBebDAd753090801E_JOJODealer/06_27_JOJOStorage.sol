/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/EIP712.sol";
import "../lib/Types.sol";
import "../utils/Errors.sol";

/// @notice All storage variables of JOJODealer
abstract contract JOJOStorage is Ownable, ReentrancyGuard {
    Types.State public state;
    bytes32 public immutable domainSeparator;

    constructor() Ownable() {
        domainSeparator = EIP712._buildDomainSeparator(
            "JOJO",
            "1",
            address(this)
        );
    }

    modifier onlyFundingRateKeeper() {
        require(
            msg.sender == state.fundingRateKeeper,
            Errors.INVALID_FUNDING_RATE_KEEPER
        );
        _;
    }

    modifier onlyRegisteredPerp() {
        require(
            state.perpRiskParams[msg.sender].isRegistered,
            Errors.PERP_NOT_REGISTERED
        );
        _;
    }
}