// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol';
import 'operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract TypeBlocks721 is ERC721AQueryableUpgradeable, ERC2981Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable {
    
    function __ERC721_init(string memory _name, string memory _symbol) initializerERC721A initializer internal {
        ERC721AUpgradeable.__ERC721A_init(_name, _symbol);
        __ERC2981_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        _setDefaultRoyalty(msg.sender, 330);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) 
        public
        virtual
        override (IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public
        payable
        virtual
        override (IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperatorApproval(operator) 
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public
        payable
        virtual
        override 
        (IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public
        payable
        virtual
        override (IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override (IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view
        virtual 
        override(ERC721AUpgradeable, ERC2981Upgradeable, IERC721AUpgradeable) returns (bool) 
    {
        return 
            ERC721AUpgradeable.supportsInterface(interfaceId) || 
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}