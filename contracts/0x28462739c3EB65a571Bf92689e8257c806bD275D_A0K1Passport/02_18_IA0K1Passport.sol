// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * A0K1Passport Interface
 */
interface IA0K1Passport is IERC1155Receiver {

    event Activate();
    event Deactivate();
    event TokenLevel(uint256 tokenId, uint8 level);

    struct MetadataContract {
        uint32 category;
        uint64 chainId;
        address contractAddress;
    }

    /**
     * @dev Enable token redemption period
     */
    function enableRedemption() external;

    /**
     * @dev Disable token redemption period
     */
    function disableRedemption() external;

    /**
     * @dev Get credits required for each level
     */
    function getLevelCredits() external view returns(uint16[] memory);

    /**
     * @dev Set credits required for each level
     */
    function setLevelCredits(uint16[] calldata levelCredits) external;

    /**
     * @dev Get supplementary metadata contract addresses
     */
    function getMetadataContracts() external view returns(MetadataContract[] memory);

    /**
     * @dev Set supplementary metadata contract addresses
     */
    function setMetadataContracts(MetadataContract[] calldata metadataContracts) external;

    /**
     * @dev Recover any 721's accidentally sent in.
     */
    function recoverERC721(address tokenAddress, uint256 tokenId, address destination) external;

    /**
     * @dev Merge passes
     */
    function mergePasses(uint256 tokenId, uint8 newLevel, uint256[] calldata mergeTokenIds) external;

    /**
     * @dev Get a token's level
     */
    function tokenLevel(uint256 tokenId) external view returns(uint8);

    /**
     * @dev Set the image base uri (prefix)
     */
    function setPrefixURI(string calldata uri) external;

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external;

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps);
    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients);
    function getFeeBps(uint256) external view returns (uint[] memory bps);
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256);
}

interface IA0K1Credits {
    function burn(address from, uint16 amount) external;
}