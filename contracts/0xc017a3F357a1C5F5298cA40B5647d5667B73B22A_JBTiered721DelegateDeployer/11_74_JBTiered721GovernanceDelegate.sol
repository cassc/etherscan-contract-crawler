// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IJBProjects } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import { IJBOperatorStore } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol";

import { Votes } from "./abstract/Votes.sol";
import { JB721Tier } from "./structs/JB721Tier.sol";
import { JBTiered721Delegate } from "./JBTiered721Delegate.sol";

/// @title JBTiered721GovernanceDelegate
/// @notice A tiered 721 delegate where each NFT can be used for onchain governance.
contract JBTiered721GovernanceDelegate is Votes, JBTiered721Delegate {
    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @param _projects The IJBProjects that will be used to check project ownership.
    /// @param _operatorStore The operatorStore that will be used to check operator permissions.
    constructor(IJBProjects _projects, IJBOperatorStore _operatorStore)
        JBTiered721Delegate(_projects, _operatorStore)
    {}

    //*********************************************************************//
    // ------------------------ internal functions ----------------------- //
    //*********************************************************************//

    /// @notice The total voting units the provided address has from its NFTs across all tiers. NFTs have a tier-specific number of voting units.
    /// @param _account The account to get voting units for.
    /// @return units The voting units for the account.
    function _getVotingUnits(address _account) internal view virtual override returns (uint256 units) {
        return store.votingUnitsOf(address(this), _account);
    }

    /// @notice Handles voting unit accounting within a tier.
    /// @param _from The account to transfer voting units from.
    /// @param _to The account to transfer voting units to.
    /// @param _tokenId The token ID for which voting units are being transferred.
    /// @param _tier The tier that the token ID is part of.
    function _afterTokenTransferAccounting(address _from, address _to, uint256 _tokenId, JB721Tier memory _tier)
        internal
        virtual
        override
    {
        _tokenId; // Prevents unused var compiler and natspec complaints.

        if (_tier.votingUnits != 0) {
            // Transfer the voting units.
            _transferVotingUnits(_from, _to, _tier.votingUnits);
        }
    }
}