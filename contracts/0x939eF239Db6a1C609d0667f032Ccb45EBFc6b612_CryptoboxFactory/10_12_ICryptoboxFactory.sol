// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICryptobox} from "./ICryptobox.sol";

/**
    @title ICryptoboxFactory 
    @author iMe Lab
    @notice Factory iMe Cryptoboxes
 */
interface ICryptoboxFactory {
    event RulesChanged();
    event CryptoboxCreated(address addr);

    error NotEnoughParticipants();
    error FactoryIsDisabled();
    error CryptoboxFundingFailed();

    function create(ICryptobox.Info memory, address) external payable;

    function getFeeToken() external view returns (address);

    function setFeeToken(address) external;

    function getFeeDestination() external view returns (address);

    function setFeeDestination(address) external;

    function getParticipantFee() external view returns (uint256);

    function setParticipantFee(uint256) external;

    function getCreationFee() external view returns (uint256);

    function setCreationFee(uint256) external;

    function getMinimalCapacity() external view returns (uint32);

    function setMinimalCapacity(uint32) external;

    function isEnabled() external view returns (bool);

    function enable() external;

    function disable() external;
}