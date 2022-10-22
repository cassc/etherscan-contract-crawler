pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT
/// @title Galeria Rodrigo Art
/// @author El Cid Rodrigo
/// @dev El Cid Rodrigo
// All artwork within the collection; Copyright© 2022, Galeria Rodrigo, LLC, All rights reserved.
// Learn more about our collections at galeriarodrigo.com.

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//todo modify receiver for update

contract GaleriaRodrigo is ERC721, IERC2981, Ownable {

    uint256 public immutable MAXIMUM_SUPPLY;

    uint256 public constant ROYALTY_DIVISOR = 10000;

    //Royalty is locked
    uint256 public immutable ROYALTY_PERCENTAGE;

    address public royaltyAddress;

    address public mintAddress;
    // Keeps track of the total supply of tokens
    uint256 public totalSupply;
    // The base uri for the token uri
    string public baseTokenURI;


    constructor(
        string memory name,
        string memory symbol,
        uint256 maximumSupply,
        address royaltyReceiver,
        uint256 royaltyPercentage

    ) ERC721(name, symbol) {
        MAXIMUM_SUPPLY = maximumSupply;
        require(royaltyReceiver != address(0), "receiver is zero address");
        require(royaltyPercentage <= ROYALTY_DIVISOR, "royalty is too high");
        royaltyAddress = royaltyReceiver;
        ROYALTY_PERCENTAGE = royaltyPercentage;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (royaltyAddress, (salePrice * ROYALTY_PERCENTAGE) / ROYALTY_DIVISOR);
    }
    function setRoyaltyAddress(address newRoyaltyAddress) external onlyOwner {
        royaltyAddress = newRoyaltyAddress;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata updateBaseTokenURI) external onlyOwner {
        baseTokenURI = updateBaseTokenURI;
    }

    function mint(address receiver) external {
        require(mintAddress == msg.sender, "Only the minter can mint.");
        uint256 currentSupply = totalSupply;
        require(currentSupply < MAXIMUM_SUPPLY, "Max supply achieved.");
        _safeMint(receiver, currentSupply);
    }

    function setMintAddress(address newMintAddress) external onlyOwner {
        mintAddress = newMintAddress;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        totalSupply += 1;
    }



}