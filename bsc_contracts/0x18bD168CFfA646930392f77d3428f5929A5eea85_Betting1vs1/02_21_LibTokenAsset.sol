// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library LibTokenAsset {
    struct TokenAsset {
        address token;
        uint256 amount;
    }

    bytes32 constant TOKEN_ASSET_TYPEHASH =
        keccak256("TokenAsset(address token,uint256 amount)");

    function hash(TokenAsset calldata tokenAsset)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    TOKEN_ASSET_TYPEHASH,
                    tokenAsset.token,
                    tokenAsset.amount
                )
            );
    }
}