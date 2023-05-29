// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateDefault {
    struct State {
        uint8 allowedMintGold;
        uint8 allowedMintStandard;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
    }

    function init(
        State storage state,
        uint8 allowedMintStandard,
        uint8 allowedMintGold
    ) internal {
        state.allowedMintStandard = allowedMintStandard;
        state.allowedMintGold = allowedMintGold;
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
        uint256 availableMints = collectionSupply - currentSupply;

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
    }

    function update(
        State storage state,
        uint256 membershipId,
        uint256 value
    ) internal {
        unchecked {
            state._mints[membershipId] += value;
        }
    }
}