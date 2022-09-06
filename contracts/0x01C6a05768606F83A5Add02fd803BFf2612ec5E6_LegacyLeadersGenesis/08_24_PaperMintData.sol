// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

library PaperMintData {
    struct MintData {
        address recipient;
        uint256 quantity;
        uint256 tokenId;
        bytes32 nonce;
        bytes signature;
        bytes data;
    }

    /// @notice Returns a hash of the given MintData, prepared using EIP712 typed data hashing rules.
    /// @param _data is the MintData to hash.
    function hashData(MintData calldata _data) internal pure returns (bytes32) {
        bytes memory encoded = abi.encode(
            keccak256(
                "MintData(address recipient,uint256 quantity,uint256 tokenId,bytes32 nonce,bytes data)"
            ),
            _data.recipient,
            _data.quantity,
            _data.tokenId,
            _data.nonce,
            keccak256(_data.data)
        );
        return keccak256(encoded);
    }
}