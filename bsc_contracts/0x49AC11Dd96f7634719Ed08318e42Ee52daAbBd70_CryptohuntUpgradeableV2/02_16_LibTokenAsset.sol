// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

library LibTokenAsset {
    struct TokenAsset {
        address owner;
        address token;
        uint256 amount;
        uint256 salt;
    }

    struct TokenAssetV2 {
        address owner;
        address token;
        uint256 amount;
        uint256 expirationTimestamp;
        uint256 salt;
    }

    bytes32 constant TOKEN_ASSET_TYPEHASH =
        keccak256(
            "TokenAsset(address owner,address token,uint256 amount,uint256 salt)"
        );

    bytes32 constant TOKEN_ASSET_V2_TYPEHASH =
        keccak256(
            "TokenAsset(address owner,address token,uint256 amount,uint256 expirationTimestamp,uint256 salt)"
        );

    function hash(TokenAsset calldata tokenAsset)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    TOKEN_ASSET_TYPEHASH,
                    tokenAsset.owner,
                    tokenAsset.token,
                    tokenAsset.amount,
                    tokenAsset.salt
                )
            );
    }

    function hash(TokenAssetV2 calldata tokenAsset)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    TOKEN_ASSET_V2_TYPEHASH,
                    tokenAsset.owner,
                    tokenAsset.token,
                    tokenAsset.amount,
                    tokenAsset.expirationTimestamp,
                    tokenAsset.salt
                )
            );
    }
}