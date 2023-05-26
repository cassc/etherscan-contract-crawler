// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./OpenSea.sol";
import "./Royalty.sol";

contract StellarBase is ERC721, ERC721Enumerable, ERC721URIStorage, ContextMixin, HasSecondarySaleFees, Ownable {
    using Strings for uint256;
    
    constructor(string memory name_, string memory symbol_)
    ERC721(name_, symbol_)
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function tokenOwnerIsCreator(uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return ownerOf(tokenId) == owner();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        override
        view
        returns(bool isOperator)
    {
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721)
    {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    function _mint(string memory itemName)
        public
        virtual
        onlyOwner
    {
        uint256 currentNumber = totalSupply() + 1;

        _safeMint(_msgSender(), currentNumber);
        _setTokenURI(currentNumber, itemName);
    }
       
    function _burn(uint256 tokenId)
        internal
        onlyOwner
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory itemName)
        internal
        virtual
        override(ERC721URIStorage)
    {
        super._setTokenURI(tokenId, itemName);
    }

    function withdrawETH()
        external
        virtual
    {
        uint256 royalty = address(this).balance;
        Address.sendValue(payable(owner()), royalty);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, HasSecondarySaleFees)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
    
    receive() external payable {}
}