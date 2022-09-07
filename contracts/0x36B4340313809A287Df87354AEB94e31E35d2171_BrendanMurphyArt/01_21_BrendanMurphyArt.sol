// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC1155Tradable.sol";

/**
 * @dev Brendan Murphy Art collection
  */
contract BrendanMurphyArt  is  ERC1155PresetMinterPauser, ERC1155Supply, ERC1155Tradable {
    
    constructor(address _proxyRegistryAddress, string memory _metadataRepo) 
        ERC1155PresetMinterPauser(_metadataRepo) 
        ERC1155Tradable(_proxyRegistryAddress)
    {}
    
    /**
     * @dev opensea required to load metadata
     * @param _tokenId the token number
     */
    function tokenURI(uint256 _tokenId) public virtual view returns (string memory) {
        return string(abi.encodePacked(uri(_tokenId), Strings.toString(_tokenId)));
    }       
    

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PresetMinterPauser, ERC1155, ERC1155Supply){
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155PresetMinterPauser, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view  override (ERC1155Tradable, ERC1155) returns (bool isOperator) {
        return ERC1155Tradable.isApprovedForAll(_owner, _operator);
    }
}