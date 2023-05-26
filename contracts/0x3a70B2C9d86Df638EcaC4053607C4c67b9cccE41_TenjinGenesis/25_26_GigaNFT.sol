// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/AzukiNFT.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GigaNFT is AzukiNFT {

    uint16 public constant maxSupply = 6666;
    uint8 public maxMintAmountPerWallet = 5;
    bool public paused = true;
    uint public cost = 0.0069 ether;
    bytes32 public merkleTreeRoot;
    uint8 public maxMintAmountPerMint = 50;
    bool public isPublicLive = false;
    mapping (address => uint8) public NFTPerAddress;

    constructor(string memory name_, string memory symbol_, uint256 initialMint, string memory blindBoxTokenURI) AzukiNFT(name_, symbol_, initialMint, blindBoxTokenURI) {}

    function mint(uint256 _mintAmount) override virtual external payable {
        require(isPublicLive, "Sale not live");
        require(!paused, "The contract is paused!");
        require(_mintAmount <= maxMintAmountPerMint, "Exceeds max amount per mint.");
        uint16 totalSupply = uint16(totalSupply());

        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        uint8 nft = NFTPerAddress[msg.sender];
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max NFT allowed per Wallet.");
        _safeMint(msg.sender , _mintAmount);

        NFTPerAddress[msg.sender] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function mintWhitelist(uint256 _mintAmount, bytes32[] calldata merkleProof) external payable {
        require(!paused, "The contract is paused!");
        require(_mintAmount <= maxMintAmountPerMint, "Exceeds max amount per mint.");
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");

        uint8 nft = NFTPerAddress[msg.sender];
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max NFT allowed per Wallet.");
        require(MerkleProof.verify(merkleProof, merkleTreeRoot, toBytes32(msg.sender)) == true, "Invalid merkle proof");

        _safeMint(msg.sender , _mintAmount);

        NFTPerAddress[msg.sender] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function reserve(uint16 _mintAmount, address _receiver) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Excedes max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setCost(uint _Cost) external onlyOwner {
        cost = _Cost;
    }

    function setMaxMintAmountPerWallet(uint8 _maxtx) external onlyOwner{
        maxMintAmountPerWallet = _maxtx;
    }

    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance );        
    }

    function setMerkleTreeRoot(bytes32 _merkleTreeRoot) external onlyOwner {
        merkleTreeRoot = _merkleTreeRoot;
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function togglePublicLive() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function setMaxMintAmountPerMint(uint8 _maxtx) external onlyOwner{
        maxMintAmountPerMint = _maxtx;
    }
}