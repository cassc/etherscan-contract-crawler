// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import "./interface/IMerchNFT.sol";
import "./interface/IBAGC.sol";

contract BAGCMerch is
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    IMerchNFT
{
    address public bagcAddress;
    string public baseURI;

    modifier onlyBAGC() {
        require(msg.sender == bagcAddress, "BAGCMerch: Only BAGC can mint");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        address bagcAddress_
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Ownable_init();
        baseURI = baseURI_;
        bagcAddress = bagcAddress_;
    }

    function mint(address to, uint256 tokenId) public onlyBAGC {
        require(
            IERC721Upgradeable(bagcAddress).ownerOf(tokenId) == to,
            "BAGCMerch: not bagc owner of this token Id"
        );
        _mint(to, tokenId);
    }

    function ownerMint(address to, uint256 tokenId) public onlyOwner {
        require(!IBAGC(bagcAddress).isUserToken(tokenId), "BAGCMerch: it's a user token");
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "BAGCMerch: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI(), tokenId));
    }

    function updateBAGCAddress(address bagcAddress_) public onlyOwner {
        bagcAddress = bagcAddress_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}