// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../IERC1155MetadataURIFormatter.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error AlreadyInitializedURI();

/**
 * @title InitializableReadOnlyURIFormatter
 * @author Limit Break, Inc.
 * @notice Cloneable version of the most basic ERC-1155 Metadata URI formatter that points to an off-chain URI
 */
contract InitializableReadOnlyURIFormatter is ERC165, IERC1155MetadataURIFormatter {

    /// @notice Specifies whether or not the contract is initialized
    bool public initializedURI; 

    /// @dev The read-only off-chain URI
    string private readOnlyURI;

    constructor() {}

    /// @dev Initializes the URI.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    /// Throws if already initialized
    function initializeURI(string calldata readOnlyURI_) public {
        if(initializedURI) {
            revert AlreadyInitializedURI();
        }

        readOnlyURI = readOnlyURI_;

        initializedURI = true;
    }
    
    /// @notice Returns the off-chain URI
    function uri() external override view returns (string memory) {
        return readOnlyURI;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return 
        interfaceId == type(IERC1155MetadataURIFormatter).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}