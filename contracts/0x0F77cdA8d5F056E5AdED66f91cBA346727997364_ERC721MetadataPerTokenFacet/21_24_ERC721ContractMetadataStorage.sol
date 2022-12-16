// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC721ContractMetadataStorage {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;

    struct Layout {
        string tokenName;
        string tokenSymbol;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC721.ERC721ContractMetadata.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC721.ERC712ContractMetadata.phase")) - 1);

    /// @notice Initializes the storage with a name and symbol (immutable version).
    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Metadata.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    function constructorInit(Layout storage s, string memory tokenName, string memory tokenSymbol) internal {
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Metadata).interfaceId, true);
    }

    /// @notice Initializes the storage with a name and symbol (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Metadata.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    function proxyInit(Layout storage s, string calldata tokenName, string calldata tokenSymbol) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Metadata).interfaceId, true);
    }

    /// @notice Gets the name of the token. E.g. "My Token".
    /// @return tokenName The name of the token.
    function name(Layout storage s) internal view returns (string memory tokenName) {
        return s.tokenName;
    }

    /// @notice Gets the symbol of the token. E.g. "TOK".
    /// @return tokenSymbol The symbol of the token.
    function symbol(Layout storage s) internal view returns (string memory tokenSymbol) {
        return s.tokenSymbol;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}