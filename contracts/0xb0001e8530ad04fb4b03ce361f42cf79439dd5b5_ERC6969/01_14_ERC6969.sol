// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract ERC6969 is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public walletPublic;
    mapping (address => uint256) public walletWhitelist;
    string public baseURI;
    bool public mintWhitelistEnabled = false;
    bool public mintPublicEnabled = false;
    bytes32 public merkleRoot;
    uint public freeNFTWhitelist = 1;
    uint public freeNFTPublic = 1;
    uint public maxPerTx = 9;
    uint public maxPerWallet = 9;
    uint public maxSupply = 6969;
    uint public priceWhitelist = 69000000000000000; //0.0069 ETH
    uint public pricePublic = 96000000000000000; //0.0096 ETH

    constructor() ERC721A("REKTWife", "REKTWife",69,6969){}

    function whitelistMint(uint256 qty, bytes32[] calldata _merkleProof) external payable
    {
        require(mintWhitelistEnabled, "RektWife: Minting Whitelist Pause");
        require(walletWhitelist[msg.sender] + qty <= maxPerWallet,"RektWife: Max Per Wallet");
        require(qty <= maxPerTx, "RektWife: Transaction Limit");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "RektWife: Not Whitelisted");
        require(totalSupply() + qty <= maxSupply,"RektWife: Soldout");
        if(walletWhitelist[msg.sender] < freeNFTWhitelist) 
        {
           uint256 claimFree = qty - freeNFTWhitelist;
           require(msg.value >= claimFree * priceWhitelist,"RektWife: Insufficient Funds for Claim Free");
        }
        else
        {
           require(msg.value >= qty * priceWhitelist,"RektWife: Insufficient Funds");
        }
        walletWhitelist[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function publicMint(uint256 qty) external payable
    {
        require(mintPublicEnabled, "RektWife: Minting Public Pause");
        require(walletPublic[msg.sender] + qty <= maxPerWallet,"RektWife: Max Per Wallet");
        require(qty <= maxPerTx, "RektWife: Transaction Limit");
        require(totalSupply() + qty <= maxSupply,"RektWife: Soldout");
        if(walletPublic[msg.sender] < freeNFTPublic) 
        {
           uint256 claimFree = qty - freeNFTPublic;
           require(msg.value >= claimFree * pricePublic,"RektWife: Insufficient Funds Claim Free");
        }
        else
        {
           require(msg.value >= qty * pricePublic,"RektWife: Insufficient Funds Normal");
        }
        walletPublic[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }
    
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setFreeForPublic(uint256 qty) external onlyOwner {
        freeNFTPublic = qty;
    }

    function setFreeForWhitelist(uint256 qty) external onlyOwner {
        freeNFTWhitelist = qty;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function airdrop(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function DevhMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function togglePublicMinting() external onlyOwner {
        mintPublicEnabled = !mintPublicEnabled;
    }

    function toggleWhitelistMinting() external onlyOwner {
        mintWhitelistEnabled = !mintWhitelistEnabled;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setWhitelistPrice(uint256 price_) external onlyOwner {
        priceWhitelist = price_;
    }

    function setPublicPrice(uint256 price_) external onlyOwner {
        pricePublic = price_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
}