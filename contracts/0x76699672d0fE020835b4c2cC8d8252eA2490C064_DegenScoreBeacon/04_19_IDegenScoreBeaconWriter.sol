// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../structs/Submit.sol";

interface IDegenScoreBeaconWriter {
    /**
     * @dev Emitted when a user has successfully submitted traits
     * @param beaconId the ID of the Beacon
     * @param createdAt the timestamp of the signature
     */
    event SubmitTraits(uint256 beaconId, uint64 createdAt);

    /**
     * @dev Emitted when a Beacon is burned
     * @param beaconId the ID of the burned Beacon
     */
    event Burn(uint256 beaconId);

    /**
     * @dev Is used to submit Trait data signed by `signer`
     * @param payload contains Trait data of a user
     * @param signature is the signature for `payload`
     */
    function submitTraits(UserPayload calldata payload, bytes memory signature) external payable;

    /**
     * @dev burns the Beacon of the caller
     */
    function burn() external;
}