// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title mintmessage.xyz
 * @author naveed.so      
 */
contract MintMessage is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event CreateMessage(address sender, address recipient, uint256 tokenId);

    /**
     * @notice Mint price set to 0 by default.
     */
    uint256 public mintPrice = 0 ether;

    constructor() ERC721("MintMessage", "MSG") {}

    /**
     * @notice Sets base URI to Infura.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://infura-ipfs.io/ipfs/";
    }

    /**
     * @notice Mints message to recipient.
     * @dev Concatenates base URI with CID to generate full URI.
     */
    function createMessage(string memory _uri, address _to) public payable {
        require(msg.value == mintPrice, "Insufficient funds");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _uri);

        emit CreateMessage(msg.sender, _to, tokenId);
    }

    /**
     * @notice Updates the mint price.
     */
    function updateMintPrice(uint _mintPrice) public payable onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @notice Withdraws funds from contract.
     */
    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Inheritance resolution.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Inheritance resolution.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}