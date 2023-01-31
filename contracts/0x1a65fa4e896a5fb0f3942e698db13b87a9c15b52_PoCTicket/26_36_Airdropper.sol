// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";

/**
 * @title Proof of Conference Tickets - Airdrop module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract Airdropper is AccessControlEnumerable {
    // =========================================================================
    //                          Errors
    // =========================================================================

    error ExceedingAirdropLimit();

    // =========================================================================
    //                          Constants
    // =========================================================================

    /**
     * @notice The role allowed to perform airdrops.
     */
    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");

    // =========================================================================
    //                          Storage
    // =========================================================================

    /**
     * @notice The number of tokens that have already been airdropped.
     */
    uint16 private _numAirdropped;

    /**
     * @notice The maximum number of airdrops.
     */
    uint16 private _maxAirdrops = 250;

    // =========================================================================
    //                          Getter/Setter
    // =========================================================================

    /**
     * @notice Returns the maximum number of airdroppable tickets.
     * @dev For testing.
     */
    function _maxNumAirdrops() internal view returns (uint16) {
        return _maxAirdrops;
    }

    /**
     * @notice Sets the maximum number of airdroppable tickets.
     */
    function setMaxNumAirdrops(uint16 maxNumAirdrops)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _maxAirdrops = maxNumAirdrops;
    }

    // =========================================================================
    //                          Airdrops
    // =========================================================================

    /**
     * @notice Airdrops a number of tickets to a given address.
     */
    function _doAirdrop(address to, uint256 num)
        internal
        onlyRole(AIRDROPPER_ROLE)
    {
        if (_numAirdropped + num > _maxAirdrops) {
            revert ExceedingAirdropLimit();
        }
        _numAirdropped += uint16(num);
        _mintAirdrop(to, num);
    }

    /**
     * @notice Callback that mints the airdropped tokens.
     * @dev Will be provided by `Minter`.
     */
    function _mintAirdrop(address to, uint256 num) internal virtual;
}