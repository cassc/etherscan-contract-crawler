//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IVault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
        ADD_TOKEN // for Managed Pool
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;
}