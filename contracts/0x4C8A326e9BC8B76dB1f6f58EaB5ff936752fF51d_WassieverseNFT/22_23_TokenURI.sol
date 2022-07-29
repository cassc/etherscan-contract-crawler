// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract TokenURI is AccessControl {
    //
    // Constants
    //

    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE");

    //
    // Errors
    //

    error AnimatedURINotYetCommited();
    error CannotChangeURI();
    error InvalidURI();

    //
    // State
    //

    string public regularBaseURI;
    string public animatedBaseURI;
    string public unrevealedURI;
    bool public animatedURICommited;

    mapping(uint256 => bool) flippedURI;

    constructor() {
        _grantRole(METADATA_ROLE, msg.sender);
    }

    /// Allows the metadata role to set a new URI for metadata containing animated assets
    /// After setting this, `commitAnimateURI` still must be called for the value to take any effect
    /// @param _animatedBaseURI The new animatedBaseURI to use
    function setAnimatedURI(string memory _animatedBaseURI)
        external
        onlyRole(METADATA_ROLE)
    {
        if (animatedURICommited) {
            revert CannotChangeURI();
        }

        bytes memory b = bytes(_animatedBaseURI);
        if (b[b.length - 1] != bytes1("/")) {
            revert InvalidURI();
        }

        animatedBaseURI = _animatedBaseURI;
    }

    /// Commits a previously set animatedBaseURI
    /// @dev This is the point of no return. After this, animatedBaseURI becomes immutable
    function commitAnimatedURI() external onlyRole(METADATA_ROLE) {
        if (bytes(animatedBaseURI).length == 0) {
            revert InvalidURI();
        }

        animatedURICommited = true;
    }

    /// Opt-in function for holders to switch to/from animated metadata for their NFT
    /// @param _id The id of the token to flip
    /// @param _v The new value. `true` means the animatedURI will be used instead
    /// @dev Can only be called once animatedBaseURI has been commited
    function _flipURI(uint256 _id, bool _v) internal {
        if (!animatedURICommited) {
            revert AnimatedURINotYetCommited();
        }

        flippedURI[_id] = _v;
    }

    function baseURIFor(uint256 _id) public view returns (string memory) {
        if (flippedURI[_id]) {
            return animatedBaseURI;
        } else {
            return regularBaseURI;
        }
    }

    function _updateRegularBaseURI(string memory _newRegularBaseURI) internal {
        bytes memory b = bytes(_newRegularBaseURI);

        if (b[b.length - 1] != bytes1("/")) {
            revert InvalidURI();
        }

        regularBaseURI = _newRegularBaseURI;
    }

    function _updateUnrevealedURI(string memory _newUnrevealedURI) internal {
        unrevealedURI = _newUnrevealedURI;
    }
}