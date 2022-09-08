//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract AIAM is ERC721AQueryable, Pausable, Ownable {
    string public baseTokenURI;

    uint public mintPrice = 0.01 ether;
    uint public whitelistPrice = 0;
    uint16 public maxSupply = 222;
    uint16 public minted = 0;
    bool public mintStarted = false; // is mint started flag
    bool public mintWhitelistStarted = false; // is mint for white list started flag

    bytes32 public whiteListMerkleRoot; // root of Merkle tree only for white list minters
    mapping(address => bool) public whitelistMinted; // store if sender is already minted from white list
    constructor() ERC721A("AIAM Genesis", "AIAMG") { }

    /**
    @notice mint tokens to sender 
    */
    function mint() public payable {
        require(mintStarted, "Mint is not started");
        require(minted < maxSupply, "Too much tokens to mint");
        require(mintPrice == msg.value, "Wrong amount of ETH");

        _safeMint(msg.sender, 1);
        minted += 1;
    }

    /**
    @notice tokens from whitelist to sender
    @param _merkleProof Merkle proof to verify if address in whitelist
    */
    function whitelistMint(bytes32[] calldata _merkleProof) public payable {
        require(mintWhitelistStarted, "Mint for whitelist is not started");
        require(minted < maxSupply, "Too much tokens to mint");
        require(whitelistPrice == msg.value, "Wrong amount of ETH");
        require(!whitelistMinted[msg.sender], "Already minted from whitelist.");
        require(
            MerkleProof.verify(
                _merkleProof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Failed to verify proof."
        );

        _safeMint(msg.sender, 1);
        minted += 1;
        whitelistMinted[msg.sender] = true;
    }

    function setPrices(uint _publicPrice, uint _whitelistPrice) public onlyOwner {
        mintPrice = _publicPrice; // convert to WEI
        whitelistPrice = _whitelistPrice;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintState(bool _state) external onlyOwner {
        mintStarted = _state;
    }

    function setWhitelistMintState(bool _state) external onlyOwner {
        mintWhitelistStarted = _state;
    }

    function setWhitelistRoot(bytes32 _merkleRoot) public onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
}