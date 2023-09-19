// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IStanceRKLCollection} from "./interfaces/IStanceRKLCollection.sol";
import {IMinterController} from "./interfaces/IMinterController.sol";

import {Ownable} from "./common/Ownable.sol";
import {Constants} from "./common/Constants.sol";

contract MinterController is IMinterController, Ownable, Constants {
    IStanceRKLCollection public STANCE_RKL_COLLECTION;
    mapping(address minter => IMinterController.MinterAllowedTokenIds allowedTokenIdRange) public registeredMinters;

    constructor() {
        admin = msg.sender;
    }

    /// @dev we start minting from token id = 1. so checking for lower bound to be
    //       equal to zero is essentially checking if minter has been registered
    function _checkMinterIsRegistered(address minter) private view {
        if (registeredMinters[minter].lowerBound == 0) {
            revert MinterNotRegistered();
        }
    }

    function _checkMinterIsNotRegistered(address minter) private view {
        if (registeredMinters[minter].lowerBound != 0) {
            revert MinterAlreadyRegistered();
        }
    }

    function _checkMintersBounds(IMinterController.MinterAllowedTokenIds calldata bounds) private pure {
        if (bounds.lowerBound > bounds.upperBound) {
            revert InvalidBounds(bounds.lowerBound, bounds.upperBound);
        }
    }

    /// @dev 1. checks if minter is registered for mint with StanceRKLCollection
    //       2. checks if minter is allowed to mint those specific tokenIds
    function checkMinterAllowedForTokenIds(address minter, uint256[] memory tokenIds) external view override {
        if (minter == ZERO_ADDRESS) {
            revert MinterZeroAddressNotAllowed();
        }
        _checkMinterIsRegistered(minter);
        IMinterController.MinterAllowedTokenIds memory bounds = registeredMinters[minter];
        for (uint256 i = 0; i < tokenIds.length;) {
            if (tokenIds[i] < bounds.lowerBound || tokenIds[i] > bounds.upperBound) {
                revert MinterNotAllowedForTokenId(tokenIds[i], bounds.lowerBound, bounds.upperBound);
            }
            unchecked {
                ++i;
            }
        }
    }

    // =====================================================================//
    //                              Admin                                   //
    // =====================================================================//

    function setStanceRKLCollection(address stanceRklCollection) external onlyOwner {
        STANCE_RKL_COLLECTION = IStanceRKLCollection(stanceRklCollection);
    }

    function registerMinter(address minter, IMinterController.MinterAllowedTokenIds calldata bounds)
        external
        onlyOwner
    {
        if (minter == ZERO_ADDRESS) {
            revert MinterZeroAddressNotAllowed();
        }
        _checkMinterIsNotRegistered(minter);
        _checkMintersBounds(bounds);
        registeredMinters[minter] = bounds;
    }
}