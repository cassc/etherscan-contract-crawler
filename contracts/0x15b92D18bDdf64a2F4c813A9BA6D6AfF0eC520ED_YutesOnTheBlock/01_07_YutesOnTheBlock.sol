// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract YutesOnTheBlock is ERC721A, Ownable {
    using Strings for uint256;

    string private baseTokenURI;
    string public hiddenMetadataUri;

    uint256 public whitelistMintPrice;
    uint256 public publicMintPrice;
    uint256 public collectionSize;
    uint256 public maxMintPerWallet;

    bool public whitelistSale;
    bool public publicSale;
    bool public revealed;

    bytes32 private merkleRoot;

    mapping(address => uint256) public walletMints;


    constructor() ERC721A("YutesOnTheBlock", "YOTB"){
        setHiddenMetadataUri("ipfs://Qmc3TpSvXSxAwqgmzxnmmXGUaRmv6JqmjqEr9t36cLvnWB/clubcard.json");
        // Slightly cheaper to initialize here
        publicMintPrice = 0.08 ether;
        whitelistMintPrice = 0.06 ether;
        collectionSize = 10000;
        maxMintPerWallet = 3;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(tx.origin == msg.sender, "Can't mint from a contract");
        require(_mintAmount > 0 && _mintAmount <= maxMintPerWallet, "Invalid mint amount!");
        require(walletMints[msg.sender] + _mintAmount <= maxMintPerWallet, "Exceeded max mint per wallet!");
        require(totalSupply() + _mintAmount <= collectionSize, "Max supply exceeded!" );
        _;
    }

    function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
        require(publicSale, "Public Mint is not yet Active!");
        require(msg.value >= (publicMintPrice * _mintAmount), "Insufficient funds!");
        walletMints[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
        require(whitelistSale, "Minting is on pause");
        require(msg.value >= (whitelistMintPrice * _mintAmount), "Insufficient funds!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not whitelisted");

        walletMints[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    // Returns an array of the token ids that someone owns
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= collectionSize) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if(currentTokenOwner == _owner){
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "ERC721Metada: URI query for nonexistent token");

        if(revealed == false){
            return hiddenMetadataUri;
        }

        string memory currentBaseTokenURI = _baseURI();
        return bytes(currentBaseTokenURI).length > 0 ? string(abi.encodePacked(currentBaseTokenURI, Strings.toString(_tokenId), ".json")) : "";
    }


    // Update functions below
    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
        whitelistSale = false;
        maxMintPerWallet = 10;
    }

    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setWhitelistMintPrice(uint256 _whitelistMintPrice) external onlyOwner {
        whitelistMintPrice = _whitelistMintPrice;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setHiddenMetadataUri(string memory _hiddenMetaDataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetaDataUri;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleProof) external onlyOwner{
        merkleRoot = _merkleProof;
    }

    function withdraw() external onlyOwner {
        // 40% of the Contract balance
        uint256 withdrawAmount_40 = address(this).balance * 40 / 100;
        // This will pay 40% of the initial sale.
        (bool artistSuccess, ) = payable(0x8df8316044EB02702aAB98736d3c5796F04fD452).call{value: withdrawAmount_40}("");
        require(artistSuccess);

        // This will transfer the remaining balance of the contract to the owner;
        (bool ownerSuccess, ) = payable(owner()).call{value: address(this).balance}("");
        require(ownerSuccess);
    }
}