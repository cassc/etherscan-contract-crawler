// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity ^0.8.11;

import "./ReserveableA.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/// @title RoyaltiesA
/// @author Chain Labs
/// @notice Module that adds functionality of royalties as required by EIP-2981.
/// @dev Core functionality inherited from OpenZeppelin's ERC2981
contract RoyaltiesA is ReserveableA, ERC2981Upgradeable {
    /// @notice event that logs updated royalties info
    /// @dev emits updated royalty receiver and royalty share fraction
    /// @param receiver address that should receive royalty
    /// @param royaltyFraction fraction that should be sent to receiver
    event DefaultRoyaltyUpdated(address receiver, uint96 royaltyFraction);

    //------------------------------------------------------//
    //
    //  Setup
    //
    //------------------------------------------------------//

    /// @notice set royalties, only one address can receive the royalties, considers 10000 = 100%
    /// @dev only owner can set royalties
    /// @param _royalties a struct with royalties receiver and royalties share
    function setRoyalties(RoyaltyInfo memory _royalties) public onlyOwner {
        _setRoyalties(_royalties);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @inheritdoc	ERC721AUpgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //------------------------------------------------------//
    //
    //  Internal function
    //
    //------------------------------------------------------//

    /// @notice set default royalties, considers 10000 = 100%
    /// @dev internl method to set royalties
    /// @param _royalties a struct with royalties receiver and royalties share
    function _setRoyalties(RoyaltyInfo memory _royalties) internal {
        _setDefaultRoyalty(_royalties.receiver, _royalties.royaltyFraction);
        emit DefaultRoyaltyUpdated(
            _royalties.receiver,
            _royalties.royaltyFraction
        );
    }
}