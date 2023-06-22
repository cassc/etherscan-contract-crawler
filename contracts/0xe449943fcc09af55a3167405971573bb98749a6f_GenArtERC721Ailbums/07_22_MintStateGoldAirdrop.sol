// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MintStateGoldAirdrop {
    struct State {
        uint8 _allowedMintGold;
        uint8 _allowedMintStandard;
        uint256 _goldMints;
        // maps membershipIds to the amount of mints
        mapping(uint256 => uint256) _mints;
    }

    function init(
        State storage state,
        uint8 allowedMintStandard,
        uint8 allowedMintGold
    ) internal {
        state._allowedMintStandard = allowedMintStandard;
        state._allowedMintGold = allowedMintGold;
    }

    function getMints(State storage state, uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        return state._mints[membershipId];
    }

    function getGoldMints(State storage state) internal view returns (uint256) {
        return state._goldMints;
    }

    function getAllowedMints(State storage state, bool isGold)
        internal
        view
        returns (uint256)
    {
        return (isGold ? state._allowedMintGold : state._allowedMintStandard);
    }

    function getAvailableMints(
        State storage state,
        uint256 membershipId,
        bool isGold,
        uint256 maxMints,
        uint256 currentSupply
    ) internal view returns (uint256) {
        uint256 availableMints = maxMints - (currentSupply - state._goldMints);

        return
            availableMints > 0
                ? getAllowedMints(state, isGold) - getMints(state, membershipId)
                : 0;
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