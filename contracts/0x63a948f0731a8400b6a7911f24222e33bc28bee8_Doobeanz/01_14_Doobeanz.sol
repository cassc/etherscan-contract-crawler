// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Doobeanz is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public walletPublic;
    mapping (address => uint256) public walletWhitelist;
    string public baseURI;  
    bool public mintWhitelistEnabled = false;
    bool public mintPublicEnabled = false;
    bytes32 public merkleRoot;
    uint public freeNFTWL = 1;
    uint public freeNFTPublic = 0;
    uint public maxPerTxWL = 3;  
    uint public maxPerWalletWL = 3;
    uint public maxPerTxPublic = 5;  
    uint public maxPerWalletPublic = 30;
    uint public maxSupply = 3333;
    uint public pricePublic = 6000000000000000; //0.006 ETH
    uint public priceWhitelist = 3000000000000000; //0.003 ETH

    constructor() ERC721A("Doobeanz", "Doobeanz",333,3333){}

    function whitelistMint(uint256 qty, bytes32[] calldata _merkleProof) external payable
    { 
        require(mintWhitelistEnabled, "Doobeanz: Minting Whitelist Pause");
        if(walletWhitelist[msg.sender] < freeNFTWL) 
        {
           uint restFreeMint = freeNFTWL - walletWhitelist[msg.sender];
           uint _qty = qty >= restFreeMint ? qty - restFreeMint : 0;
           require(msg.value >= priceWhitelist * _qty,"Doobeanz: Insufficient Eth Claim Free");
        }
        else
        {
           require(msg.value >= qty * priceWhitelist,"Doobeanz: Insufficient Eth Whitelist");
        }
        require(walletWhitelist[msg.sender] + qty <= maxPerWalletWL,"Doobeanz: Max Per Wallet");
        require(qty <= maxPerTxWL, "Doobeanz: Limit Per Transaction");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Doobeanz: Not whitelisted");
        require(totalSupply() + qty <= maxSupply,"Doobeanz: Soldout");
        walletWhitelist[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function publicMint(uint256 qty) external payable
    {
        require(mintPublicEnabled, "Doobeanz: Minting Public Pause");
        if(walletPublic[msg.sender] < freeNFTPublic) 
        {
           uint restFreeMint = freeNFTPublic - walletPublic[msg.sender];
           uint _qty = qty >= restFreeMint ? qty - restFreeMint : 0;
           require(msg.value >= pricePublic * _qty,"Doobeanz: Insufficient Eth Claim Free");
        }
        else
        {
           require(msg.value >= qty * pricePublic,"Doobeanz: Insufficient Eth Public");
        }
        require(walletPublic[msg.sender] + qty <= maxPerWalletPublic,"Doobeanz: Max Per Wallet");
        require(qty <= maxPerTxPublic, "Doobeanz: Limit Per Transaction");
        require(totalSupply() + qty <= maxSupply,"Doobeanz: Soldout");
        walletPublic[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function isPublicWallet(address _address) public view returns (uint256){
        return walletPublic[_address];
    }

    function isWhitelistWallet(address _address) public view returns (uint256){
        return walletWhitelist[_address];
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function airdrop(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function ownerMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function isPublicMinting() external onlyOwner {
        mintPublicEnabled = !mintPublicEnabled;
    }
    
    function isWhitelistMinting() external onlyOwner {
        mintWhitelistEnabled = !mintWhitelistEnabled;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setWLPrice(uint256 price_) external onlyOwner {
        priceWhitelist = price_;
    }

    function setPublicPrice(uint256 price_) external onlyOwner {
        pricePublic = price_;
    }

    function setMaxPerTxWL(uint256 maxPerTx_) external onlyOwner {
        maxPerTxWL = maxPerTx_;
    }

    function setMaxPerWalletWL(uint256 maxPerWallet_) external onlyOwner {
        maxPerWalletWL = maxPerWallet_;
    }
    function setMaxPerTxPublic(uint256 maxPerTx_) external onlyOwner {
        maxPerTxPublic = maxPerTx_;
    }

    function setMaxPerWalletPublic(uint256 maxPerWallet_) external onlyOwner {
        maxPerWalletPublic = maxPerWallet_;
    }

    function setMaxPerFreeNFTWL(uint256 freeNFT_) external onlyOwner {
        freeNFTWL = freeNFT_;
    }

    function setMaxPerFreeNFTPublic(uint256 freeNFT_) external onlyOwner {
        freeNFTPublic = freeNFT_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
}