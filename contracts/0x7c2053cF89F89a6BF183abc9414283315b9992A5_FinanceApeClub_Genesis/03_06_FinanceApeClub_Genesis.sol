// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import {MerkleProof} from "./MerkleProof.sol";

contract FinanceApeClub_Genesis is ERC721A, Ownable {

    // unchangeable collection size
    uint256 public constant collectionSize = 1000;

    // mint price for each whitelist category
    mapping(uint8 => uint256) public mintPrice;

    // max mint per whitelist and merkle root for each whitelist category
    mapping(uint8 => uint256) public maxMintPerWhitelist;
    mapping(uint8 => bytes32) public merkleRoot;

    // constructor setting NFT name and symbol
    constructor() ERC721A("FinanceApeClub-Genesis", "FAPEC-G") {}

    // function for minting NFT tokens
    function whitelistMint(uint256 quantity, uint8 wlCategory, bytes32[] calldata proof) external payable {
        // require that the caller is not a contract
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        // require that the caller is whitelisted
        require(merkeltreeVerify(msg.sender, wlCategory, proof), "Not whitelisted");
        // require that the collection size has not been reached
        require(_totalMinted() < collectionSize, "Collection Size reached!");
        // require that the total mint quantity of the caller is not more than the max mint per whitelist
        require((_numberMinted(msg.sender) + quantity) <= maxMintPerWhitelist[wlCategory], 
                "Whitelist mint limit exceeds");

        // if quantity to mint causes collection size to be reached, set quantity to the remaining collection size
        if (_totalMinted() + quantity > collectionSize) {
            quantity = collectionSize - _totalMinted();
        }

        // require that the caller has sent enough ETH to cover the mint price
        uint256 requiredPayment = quantity * mintPrice[wlCategory];
        require(msg.value >= requiredPayment, "ETH insufficient.");
        
        // mint the NFT tokens
        _safeMint(msg.sender, quantity);
        
        // if the caller has sent more than the required payment, send the excess back to the caller,
        // this may happen when the mint request reaches the collection size.
        if (msg.value > requiredPayment) {
            payable(msg.sender).transfer(msg.value - requiredPayment);
        }
    }
    
    // function for verifying the caller's address against the merkle root for the whitelist category
    function merkeltreeVerify(address account, uint8 wlCategory, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot[wlCategory], leaf);
    }
    
    // define function for setting the max mint per whitelist
    function setMaxMintPerWhitelist(uint8[] calldata wlCategories, uint256[] calldata maxMints) external onlyOwner{
        require(wlCategories.length == maxMints.length, "Array lengths do not match.");
        for (uint256 i = 0; i < wlCategories.length; i++) {
            maxMintPerWhitelist[wlCategories[i]] = maxMints[i];
        }
    }

    // function for setting the merkle root for each whitelist category
    function setMerkleRoots(uint8[] calldata wlCategories, bytes32[] calldata rootHashes) external onlyOwner{
        require(wlCategories.length == rootHashes.length, "Array lengths do not match.");
        for (uint256 i = 0; i < wlCategories.length; i++) {
            merkleRoot[wlCategories[i]] = rootHashes[i];
        }
    }

    // function for setting the merkle root for each whitelist category
    function setMintPrices(uint8[] calldata wlCategories, uint256[] calldata mintPrices) external onlyOwner {
        require(wlCategories.length == mintPrices.length, "Array lengths do not match.");
        for (uint256 i = 0; i < wlCategories.length; i++) {
            mintPrice[wlCategories[i]] = mintPrices[i];
        }
    }

    // function for getting the number of minted NFT tokens 
    function mintedNumberOf(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    // functions for baseTokenURI and unrevealedURI
    string private _baseTokenURI;
    string private _unrevealedURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // function for setting baseTokenURI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // function for getting tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : _unrevealedURI;
    }

    // function for setting unrevealedURI
    function setUnrevealedURI(string calldata unrevealedURI) external onlyOwner {
        _unrevealedURI = unrevealedURI;
    }

    //  function for withdrawing ETH from the contract to the owner's address
    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}