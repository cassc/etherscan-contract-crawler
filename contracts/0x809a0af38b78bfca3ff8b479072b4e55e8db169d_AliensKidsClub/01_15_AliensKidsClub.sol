// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AliensKidsClub is Ownable, ERC721Enumerable, ReentrancyGuard {

    //
    // Library
    //

    //To concatenate the URL of an NFT
    using Strings for uint256;

    //
    // CONSTANTS
    //

    // Number of NFTs in the collection
    uint private constant NUMBER_OF_NFTS = 5555;

    //The extension of the file containing the Metadatas of the NFTs
    string private constant URI_EXTENSION = ".json";

    //
    // Attributes
    //

    // Pre sale date.
    bool private _isPublic;

    //URI of the NFTs when revealed.
    string private _revealedURI;

    //URI of the NFTs when not revealed.
    string private _notRevealedURI;
    
    //Are the NFTs revealed yet ?
    bool private _revealed;

    //Merkle tree root.
    bytes32 private _root;

    constructor(
        string memory name,
        string memory symbol,
        string memory notRevealedURI,
        bytes32 root
    ) ERC721(name, symbol) {
        _isPublic = false;
        _notRevealedURI = notRevealedURI;
        _root = root;
        _revealed = false;
    }

    //
    // Public getters
    //

    function getPrice() public pure returns (uint256) {
        return 0.15 ether;
    }

    function getPublic() public view returns (bool) {
        return _isPublic;
    }

    function getMaxMintAllowed() public view returns (uint8) {
        return _isPublic ? 5 : 3;
    }

    function getNumberOfMintedNFT() public view returns (uint) {
        return totalSupply();
    }

    function getNumberOfAvailableToken() public view returns (uint) {
        return NUMBER_OF_NFTS - getNumberOfMintedNFT();
    }

    //
    // Setters to modify contract.
    //

    function setPublic(bool isPublic) external onlyOwner  {
        _isPublic = isPublic;
    }

    function setRevealed(string memory revealedURI, bool revealed) public onlyOwner {
        _revealedURI = revealedURI;
        _revealed = revealed;
    }

    //
    // Merkle tree's internal check methods
    //

    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, _root, leaf);
    }

    function isWhiteListed(address account, bytes32[] calldata proof) internal view returns(bool) {
        return _verify(_leaf(account), proof);
    }

    //
    // Sale methods
    //

    function presaleMint(uint256 ammount, bytes32[] calldata proof) external payable nonReentrant {
        uint256 price = getPrice();
        uint numberOfMintedNFT = getNumberOfMintedNFT();

        require(!_isPublic, "Pre sale has not started yet.");
        require(isWhiteListed(msg.sender, proof), "Not on the whitelist");
        require(getNumberOfAvailableToken() > ammount, "No enought NFT available");
        require(balanceOf(msg.sender) + ammount <= getMaxMintAllowed(), "You have already reach the max mint allowed");
        require(msg.value >= ammount * price, "Not enought funds");

        for(uint i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, numberOfMintedNFT + i);
        }
    }

    function saleMint(uint256 ammount) external payable nonReentrant {
        uint256 price = getPrice();
        uint numberOfMintedNFT = getNumberOfMintedNFT();

        require(_isPublic, "Public sale has not started yet.");
        require(getNumberOfAvailableToken() > ammount, "No enought NFT available");
        require(balanceOf(msg.sender) + ammount <= getMaxMintAllowed(), "You have already reach the max mint allowed");
        require(msg.value >= ammount * price, "Not enought funds");

        for(uint i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, numberOfMintedNFT + i);
        }
    }

    //
    // Withdraw money from contract
    //

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    //
    // Air drop
    //

    function sendAirDrop(address[] calldata airDrop, uint[] calldata airDropAmmount) external onlyOwner {
        uint nbNftAirDrop = getNumberOfMintedNFT();
        
        require(nbNftAirDrop + airDrop.length < NUMBER_OF_NFTS, "Can't air drop more than maximum NFT available.");
        require(airDrop.length == airDropAmmount.length, "You have to define all air drop ammount");
        
        for (uint i = 0; i < airDrop.length; i++) {
            for (uint ammount = 0; ammount < airDropAmmount[i]; ammount++) {
                nbNftAirDrop++;
                _safeMint(airDrop[i], nbNftAirDrop);
            }
        }
    }

    //
    // Metadatas management for marketplace website such as opensea
    //

    function _baseURI() internal view virtual override returns (string memory) {
        return _revealedURI;
    }

    function tokenURI(uint nftId) public view override(ERC721) returns (string memory) {
        require(_exists(nftId), "This NFT doesn't exist.");
        if(_revealed == false) {
            return _notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, nftId.toString(), URI_EXTENSION))
            : "";
    }
}