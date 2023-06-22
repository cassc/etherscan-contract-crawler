// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "../Extension/Ownable.sol";
import "../Extension/Supporter.sol";
import "../Extension/OpenSea.sol";
import "../Extension/Royalty.sol";

contract ERC721EBase is ERC721, ERC721Enumerable, ERC721URIStorage, ContextMixin, HasSecondarySaleFees, Supportable, Ownable {
    using Strings for uint256;

    bool private _emergencyLock = false;
    
    constructor(string memory name_, string memory symbol_, address ownerAddress)
    ERC721(name_, symbol_)
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    Ownable(ownerAddress)
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }

    modifier emergencyMode()
    {
        require(!_emergencyLock, "Contract Locked");
        _;
    }

    modifier onlyAdmin()
    {
        require(supporter() == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the Admin");
        _;
    }

    function setCommonRoyalty(uint256 royalty)
        external
        onlyAdmin
        emergencyMode
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = royalty;
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
        virtual
        override(ERC721, ERC721Enumerable)
        emergencyMode
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721)
        emergencyMode
    {
        super.safeTransferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721)
        emergencyMode
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        public
        virtual
        override(ERC721)
        emergencyMode
    {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function burn(uint256 tokenId)
        external
        onlyAdmin
        emergencyMode
    {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
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
        emergencyMode
    {
        super._setTokenURI(tokenId, itemName);
    }

    function withdrawETH()
        external
        virtual
        onlyAdmin
        emergencyMode
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

    function emergencyLock()
        external
        onlyAdmin
    {
        _emergencyLock = true;
        transferOwnership(supporter());
    }

    function emergencyUnLock()
        external
        onlySupporter
    {
        _emergencyLock = false;
    }
    
    receive() external payable {}
}