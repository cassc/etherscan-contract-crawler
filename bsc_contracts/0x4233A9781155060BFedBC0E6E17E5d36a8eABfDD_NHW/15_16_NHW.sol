// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./utils/MinterAccessControl.sol";
import "./interfaces/ISouvenir.sol";


contract NHW is
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    MinterAccessControl
{
    uint256 public constant souvenirTokenId = 2;
    ISouvenir nftca;

    event Mint(address indexed to, uint256 indexed tokenId);
    event Redeem(address indexed redeemer, uint256 indexed tokenId);
    address souvenirNFT; // BSC Chain souvenir nft

    string private baseURI = "";
    uint256 public maxSupply = 300;

    constructor(
        address souvenirAddress
    ) ERC721("Chateau Canard Legacy Rouge", "RGE") {
        souvenirNFT = souvenirAddress;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId)))
                : "";
    }

    function redeem(uint256 tokenId) public {
        burn(tokenId);
        nftca = ISouvenir(souvenirNFT);
        nftca.mint(msg.sender, souvenirTokenId, 1);
        emit Redeem(msg.sender, tokenId);
    }

    /**
    * @notice Service function to mint mulitply nfts at once
    *
    */
    function safeBatchMint(
        address to_,
        uint256 initialId_,
        uint256 amount_
    ) public virtual onlyMinter {
        require(totalSupply() + amount_ <= maxSupply, "mint exceed maxSupply");
        for(uint256 index; index < amount_; ++index) {
            uint256 tokenId = initialId_ + index;
            _safeMint(to_, tokenId);
            emit Mint(to_, tokenId);
        }
    }

    /**
    * @notice Service function to mint nft
    *
    * @dev this function can only be called by minter
    *
    * @param to_ an address which received nft
    * @param tokenId_ a number of id to be minted
    */
    function safeMint(address to_, uint256 tokenId_) external virtual onlyMinter {
        require(totalSupply() < maxSupply, "mint exceed maxSupply");
        _safeMint(to_, tokenId_);
        emit Mint(to_, tokenId_);
    }

    /**
    * @notice Service function to add address into MinterRole
    *
    * @dev this function can only be called by Owner
    *
    * @param addr_ an address which is adding into MinterRole
    */
    function grantMinterRole(address addr_) external onlyOwner {
        _grantMinterRole(addr_);
    }

    /**
    * @notice Service function to remove address into MinterRole
    *
    * @dev this function can only be called by Owner
    *
    * @param addr_ an address which is removing from MinterRole
    */
    function revokeMinterRole(address addr_) external onlyOwner {
        _revokeMinterRole(addr_);
    }
}