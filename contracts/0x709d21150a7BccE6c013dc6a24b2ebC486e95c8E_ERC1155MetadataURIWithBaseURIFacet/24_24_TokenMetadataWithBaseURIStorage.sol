// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library TokenMetadataWithBaseURIStorage {
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;
    using Strings for uint256;

    struct Layout {
        string baseURI;
    }

    bytes32 public constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.metadata.TokenMetadataWithBaseURI.storage")) - 1);

    event BaseMetadataURISet(string baseMetadataURI);

    /// @notice Sets the base metadata URI.
    /// @dev Emits a {BaseMetadataURISet} event.
    /// @param baseURI The base metadata URI.
    function setBaseMetadataURI(Layout storage s, string calldata baseURI) internal {
        s.baseURI = baseURI;
        emit BaseMetadataURISet(baseURI);
    }

    /// @notice Gets the base metadata URI.
    /// @return baseURI The base metadata URI.
    function baseMetadataURI(Layout storage s) internal view returns (string memory baseURI) {
        return s.baseURI;
    }

    /// @notice Gets the token metadata URI for a token as the concatenation of the base metadata URI and the token identfier.
    /// @param id The token identifier.
    /// @return tokenURI The token metadata URI as the concatenation of the base metadata URI and the token identfier.
    function tokenMetadataURI(Layout storage s, uint256 id) internal view returns (string memory tokenURI) {
        return string(abi.encodePacked(s.baseURI, id.toString()));
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}