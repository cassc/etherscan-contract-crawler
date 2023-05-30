// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {    
    event CreatorUpdated(uint256 indexed creatorId, address indexed creator);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event CreatorRoyaltiesUpdated(uint256 indexed creatorId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ImportedToken(address indexed to, uint256 indexed eventId, uint256 indexed tokenId, string linkedAccount);
    event ExportedToken(address indexed to, uint256 indexed eventId, uint256 indexed tokenId, string linkedAccount);
    
    function mintCreator(address to, uint256 creatorId, uint256 templateId) external returns (uint256);
    function mintCreatorURI(address to, uint256 creatorId, uint256 templateId, string calldata uri ) external returns (uint256);
    function mintBridge(address to, uint256 creatorId, uint256 tokenId, string calldata linkedAccount) external returns (uint256);
    function mintBridgeURI(address to, uint256 creatorId, uint256 tokenId, string calldata linkedAccount, string calldata uri) external returns (uint256);

    function mintCreatorBatch(address to, uint256 creatorId, uint256 templateId, uint256 count) external returns (uint256[] memory);
    function mintCreatorBatchURI(address to, uint256 creatorId, uint256 templateId, string[] calldata uris) external returns (uint256[] memory);
    function mintBridgeBatch(address to, uint256 creatorId, uint256[] memory tokenIds, string calldata linkedAccount) external returns (uint256[] memory);
    function mintBridgeBatchURI(address to, uint256 creatorId, uint256[] memory tokenIds, string calldata linkedAccount, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev set the baseTokenURI for tokens.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common uri for tokens with a creator.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "commonURI+tokenId"
     */
    function setBaseTokenURICreator(uint256 creatorId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;    

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an creator
     */
    function setRoyaltiesCreator(uint256 creatorId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;
    
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value, bytes calldata data) external view returns (address, uint256, bytes memory);

}