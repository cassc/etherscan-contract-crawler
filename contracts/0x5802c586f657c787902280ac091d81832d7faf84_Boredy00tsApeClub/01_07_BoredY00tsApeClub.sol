// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
    
contract Boredy00tsApeClub is ERC721A, Ownable, ReentrancyGuard {
    bytes32 public merkleRoot;
    bool public isMintingStart  = false;
    uint256 public pricePublic = 5000000000000000;
    uint256 public pricey00tapelist = 3000000000000000;
    string public baseURI;  
    uint256 public maxPerTransaction = 20;  
    uint256 public maxSupply = 6969;
    uint256 public teamSupply = 69;  
    uint256 public mintSupply = 6900;
    uint256 public freey00tapelist = 2;
    mapping (address => uint256) public walletPublic;
    mapping (address => uint256) public wallety00tapelist ;
    constructor() ERC721A("Bored y00ts Ape Club", "BYAC"){}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function publicMint(uint256 qty) external payable
    {
        require(isMintingStart , "BYAC isMintingStart Not Open Yet !");
        require(qty <= maxPerTransaction, "BYAC Max Per Max Per Transaction !");
        require(totalSupply() + qty <= mintSupply,"BYAC Soldout !");
        require(msg.value >= qty * pricePublic,"BYAC Insufficient Funds !");
        walletPublic[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function y00tapelistMint(uint256 qty, bytes32[] calldata _merkleProof) external payable
    { 
        require(isMintingStart, "BYAC isMintingStart Not Open Yet !");
        if(wallety00tapelist[msg.sender] < freey00tapelist) 
        {
           uint256 claimFree = qty - freey00tapelist;
           require(msg.value >= claimFree * pricey00tapelist,"BYAC Insufficient Eth");
        }
        else
        {
           require(msg.value >= qty * pricey00tapelist,"BYAC Insufficient Eth");
        }
        require(qty <= maxPerTransaction, "BYAC Max Per Max Per Transaction !");
        require(totalSupply() + qty <= maxSupply,"BYAC Soldout !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "BYAC Not y00tapelist");
        wallety00tapelist[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] memory listedAirdrop ,uint256[] memory qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty[i]);
        }
    }

    function teamMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setPublicisMintingStart() external onlyOwner {
        isMintingStart  = !isMintingStart ;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPricePublic(uint256 price_) external onlyOwner {
        pricePublic = price_;
    }

    function setPricey00tapelist(uint256 pricey00tapelist_) external onlyOwner {
        pricey00tapelist = pricey00tapelist_;
    }

    function setmaxPerTransaction(uint256 maxPerTransaction_) external onlyOwner {
        maxPerTransaction = maxPerTransaction_;
    }

    function setMintSupply(uint256 mintSupply_) external onlyOwner {
        mintSupply = mintSupply_;
    }

    function setTeamSupply(uint256 maxTeam_) external onlyOwner {
        teamSupply = maxTeam_;
    }

    function setfreey00tapelist(uint256 freey00tapelist_) external onlyOwner {
        freey00tapelist = freey00tapelist_;
    }

    function setWalletMint(address addr_) external onlyOwner {
        walletPublic[addr_] = 0;
        wallety00tapelist[addr_] = 0;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
}