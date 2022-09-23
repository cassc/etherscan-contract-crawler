// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../structs/FTNFTData.sol";

abstract contract IFTNFT is AccessControlEnumerable, ERC721, FTNFTData
{
    /**
     * Get templates
     */
    function getTemplates() public virtual view returns (TemplateStruct[] memory);

    /**
     * Get template
     */
    function getTemplateById(uint256 templateId) public virtual view returns (TemplateStruct memory);

    /**
     * Get template id by tokenId
     */
    function getTemplateIdByTokenId(uint256 tokenId) public virtual view returns (uint256);

    /**
     * Get template by tokenId
     */
    function getTemplateByTokenId(uint256 tokenId) public virtual view returns (TemplateStruct memory);

    /**
     * @dev Mint
     */
    function mint(address to, uint256 templateId) public virtual returns (uint256);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}