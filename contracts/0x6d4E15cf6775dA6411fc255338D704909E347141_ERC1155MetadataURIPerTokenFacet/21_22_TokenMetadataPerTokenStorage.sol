// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library TokenMetadataPerTokenStorage {
    using TokenMetadataPerTokenStorage for TokenMetadataPerTokenStorage.Layout;

    struct Layout {
        mapping(uint256 => string) uris;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.metadata.TokenMetadataPerToken.storage")) - 1);

    /// @notice Sets the metadata URI for a token.
    /// @param id The token identifier.
    /// @param uri The token metadata URI.
    function setTokenURI(Layout storage s, uint256 id, string calldata uri) internal {
        s.uris[id] = uri;
    }

    /// @notice Sets the metadata URIs for a batch of tokens.
    /// @param ids The token identifiers.
    /// @param uris The token metadata URIs.
    function batchSetTokenURI(Layout storage s, uint256[] calldata ids, string[] calldata uris) internal {
        uint256 length = ids.length;
        require(length == uris.length, "Metadata: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.uris[ids[i]] = uris[i];
            }
        }
    }

    /// @notice Gets the token metadata URI for a token.
    /// @param id The token identifier.
    /// @return tokenURI The token metadata URI.
    function tokenMetadataURI(Layout storage s, uint256 id) internal view returns (string memory tokenURI) {
        return s.uris[id];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}