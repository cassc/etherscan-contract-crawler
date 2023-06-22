// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev extendable interface
 */
interface IBaseERC721Extendable is IERC165 {
    event ExtensionRegistered(
        address indexed extension,
        address indexed sender
    );
    event ExtensionUnregistered(
        address indexed extension,
        address indexed sender
    );

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(
        address extension,
        string calldata baseURI
    ) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev executes a batch mint by an extension
     */
    function batchMintExtension(
        address[] calldata _tos,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris
    ) external;

    /**
     * @dev executes a single mint by an extension
     */
    function mintExtension(
        address _to,
        uint256 _tokenId,
        string calldata _tokenUri
    ) external;

    /**
     * @dev executes a base uri update by an extension
     */
    function updateBaseURIExtension(
        string memory _baseURI,
        bool _emitBatchMetadataUpdatedEvent
    ) external;

    /**
     * @dev executes a batch update of token uris by an extension
     */
    function batchUpdateTokenUriExtension(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris,
        bool _emitBatchMetadataUpdatedEvent
    ) external;
}