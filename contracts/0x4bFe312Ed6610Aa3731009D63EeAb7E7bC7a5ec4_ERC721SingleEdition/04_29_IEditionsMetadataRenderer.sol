// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Used to interface with EditionsMetadataRenderer
 * @author [email protected], [email protected]
 */
interface IEditionsMetadataRenderer {
    /**
     * @notice Token edition info
     * @param name Edition name
     * @param description Edition description
     * @param imageUrl Edition image url
     * @param animationUrl Edition animation url
     * @param externalUrl Edition external url
     * @param attributes Edition attributes
     */
    struct TokenEditionInfo {
        string name;
        string description;
        string imageUrl;
        string animationUrl;
        string externalUrl;
        string attributes;
    }

    /**
     * @notice Updates name on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param name New name of edition
     */
    function updateName(
        address editionsAddress,
        uint256 editionId,
        string calldata name
    ) external;

    /**
     * @notice Updates description on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param description New description of edition
     */
    function updateDescription(
        address editionsAddress,
        uint256 editionId,
        string calldata description
    ) external;

    /**
     * @notice Updates imageUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param imageUrl New imageUrl of edition
     */
    function updateImageUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata imageUrl
    ) external;

    /**
     * @notice Updates animationUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param animationUrl New animationUrl of edition
     */
    function updateAnimationUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata animationUrl
    ) external;

    /**
     * @notice Updates externalUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param externalUrl New externalUrl of edition
     */
    function updateExternalUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata externalUrl
    ) external;

    /**
     * @notice Updates attributes on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param attributes New attributes of edition
     */
    function updateAttributes(
        address editionsAddress,
        uint256 editionId,
        string calldata attributes
    ) external;

    /**
     * @notice Get an edition's uri. HAS to be called by collection
     * @param editionId Edition's id to get uri for
     */
    function editionURI(uint256 editionId) external view returns (string memory);

    /**
     * @notice Get an edition's info.
     * @param editionsAddress Address of collection that edition is on
     * @param editionsId Edition's id to get info for
     */
    function editionInfo(address editionsAddress, uint256 editionsId) external view returns (TokenEditionInfo memory);
}