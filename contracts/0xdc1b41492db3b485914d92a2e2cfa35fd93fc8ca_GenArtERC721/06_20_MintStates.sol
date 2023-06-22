// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStates {
    struct State {
        uint256 reservedGoldSupply;
        uint256 allowedMintGold;
        uint256 allowedMintStandard;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
        uint256 _goldMints;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state.allowedMintGold : state.allowedMintStandard);
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 collectionSupply,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 reserved = state.reservedGoldSupply <= state._goldMints
            ? 0
            : !isGold
            ? (state.reservedGoldSupply - state._goldMints)
            : 0;
        uint256 availableMints = collectionSupply - currentSupply - reserved;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
    }

    function init(State storage state, uint256 reservedGold) internal {
        state.reservedGoldSupply = reservedGold;
        state.allowedMintGold = 1;
        state.allowedMintStandard = 1;
    }

    function setReservedGold(State storage state, uint256 reservedGold)
        internal
    {
        state.reservedGoldSupply = reservedGold;
    }

    function update(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 value
    ) internal {
        unchecked {
            state._mints[membershipId] += value;
        }
        if (isGold) {
            unchecked {
                state._goldMints += value;
            }
        }
    }
}