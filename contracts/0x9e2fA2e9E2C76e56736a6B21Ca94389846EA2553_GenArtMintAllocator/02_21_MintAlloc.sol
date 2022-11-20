// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
struct MintParams {
    uint256 membershipId;
    bool isGold;
    uint256 maxSupply;
    uint256 totalSupply;
}
struct MintUpdateParams {
    uint256 membershipId;
    bool isGold;
    uint256 amount;
}

library MintAlloc {
    struct State {
        uint8 reservedGoldSupply;
        uint8 allowedMintGold;
        uint8 allowedMintStandard;
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

    function getAvailableMints(State storage state, MintParams memory params)
        internal
        view
        returns (uint256)
    {
        uint256 reserved = state.reservedGoldSupply <= state._goldMints
            ? 0
            : !params.isGold
            ? (state.reservedGoldSupply - state._goldMints)
            : 0;
        uint256 availableMints = reserved >
            params.maxSupply - params.totalSupply
            ? 0
            : params.maxSupply - params.totalSupply - reserved;

        return
            availableMints > 0
                ? getAllowedMints(state, params.isGold) -
                    getMints(state, params.membershipId)
                : 0;
    }

    function init(State storage state, uint8[3] memory allocParams) internal {
        state.allowedMintStandard = allocParams[0];
        state.allowedMintGold = allocParams[1];
        state.reservedGoldSupply = allocParams[2];
    }

    function setReservedGold(State storage state, uint8 reservedGold)
        internal
    {
        state.reservedGoldSupply = reservedGold;
    }

    function update(State storage state, MintUpdateParams memory params) internal {
        unchecked {
            state._mints[params.membershipId] += params.amount;
        }
        if (params.isGold) {
            unchecked {
                state._goldMints += params.amount;
            }
        }
    }
}