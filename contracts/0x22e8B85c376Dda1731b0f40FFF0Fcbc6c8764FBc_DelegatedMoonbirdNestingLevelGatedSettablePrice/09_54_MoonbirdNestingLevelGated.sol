// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import {NestingLevelLib} from "./NestingLevelLib.sol";
import {IERC721, InternallyPricedTokenGated} from "./TokenGated.sol";
import {Seller} from "../base/Seller.sol";

/**
 * @notice Introduces claimability based on signed MoonbirdNestingLevels.
 */
abstract contract MoonbirdNestingLevelGated is InternallyPricedTokenGated {
    using EnumerableSet for EnumerableSet.AddressSet;
    using NestingLevelLib for NestingLevelLib.MoonbirdNestingLevel;
    using NestingLevelLib for NestingLevelLib.SignedMoonbirdNestingLevel;

    // =================================================================================================================
    //                           Errors
    // =================================================================================================================

    /**
     * @notice Thrown if a the signer of a MoonbirdNestingLevels is not authorised.
     */
    error UnauthorisedSigner(NestingLevelLib.SignedMoonbirdNestingLevel, address recovered);

    /**
     * @notice Thrown if the nesting level of a given Moonbird is insufficient, i.e. lower than `requiredNestingLevel`.
     */
    error InsufficientNestingLevel(
        NestingLevelLib.MoonbirdNestingLevel moonbirdNestingLevel, NestingLevelLib.NestingLevel requiredNestingLevel
    );

    // =================================================================================================================
    //                           Storage
    // =================================================================================================================

    /**
     * @notice The minimum nesting level required to purchase.
     */
    NestingLevelLib.NestingLevel public immutable requiredNestingLevel;

    /**
     * @notice The set of autorised moonbirdNestingLevel signers.
     */
    EnumerableSet.AddressSet private _signers;

    constructor(IERC721 token, NestingLevelLib.NestingLevel requiredNestingLevel_) InternallyPricedTokenGated(token) {
        requiredNestingLevel = requiredNestingLevel_;
    }

    // =================================================================================================================
    //                           Purchasing
    // =================================================================================================================

    /**
     * @notice Computes the hash of a given MoonbirdNestingLevel.
     * @dev This is the raw bytes32 message that will finally be signed by one of the authorised `_signers`.
     */
    function digest(NestingLevelLib.MoonbirdNestingLevel memory moonbirdNestingLevel) public view returns (bytes32) {
        return moonbirdNestingLevel.digest();
    }

    /**
     * @notice Interface to perform purchases with signed MoonbirdNestingLevels.
     */
    function purchase(NestingLevelLib.SignedMoonbirdNestingLevel[] calldata sigs) public payable virtual {
        uint256[] memory tokenIds = new uint[](sigs.length);
        for (uint256 i; i < sigs.length; ++i) {
            address signer = sigs[i].recoverSigner();
            if (!_signers.contains(signer)) {
                revert UnauthorisedSigner(sigs[i], signer);
            }

            if (sigs[i].payload.nestingLevel < requiredNestingLevel) {
                revert InsufficientNestingLevel(sigs[i].payload, requiredNestingLevel);
            }

            tokenIds[i] = sigs[i].payload.tokenId;
        }

        InternallyPricedTokenGated._purchase(tokenIds);
    }

    // =================================================================================================================
    //                           Steering
    // =================================================================================================================

    /**
     * @notice Changes set of signers authorised to sign MoonbirdNestingLevels.
     */
    function _changeAllowlistSigners(address[] calldata rm, address[] calldata add) internal {
        for (uint256 i; i < rm.length; ++i) {
            _signers.remove(rm[i]);
        }
        for (uint256 i; i < add.length; ++i) {
            _signers.add(add[i]);
        }
    }
}