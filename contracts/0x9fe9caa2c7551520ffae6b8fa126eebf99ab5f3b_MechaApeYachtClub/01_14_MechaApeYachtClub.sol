// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./erc721/ERC721A.sol";
import "./IBAYC.sol";

contract MechaApeYachtClub is ERC721A, Ownable, ReentrancyGuard {

    IBAYC private BAYCHolder;
    mapping (address => uint256) public MechaApeList;
    mapping (address => uint256) public BAYCList;
    bool public Minting  = false;
    uint256 public MintPrice = 3300000000000000;
    string public baseURI;  
    uint256 public maxPerTransaction = 30;  
    uint256 public maxSupply = 10000;
    uint256 public publicSupply = 8900;
    uint256 public reserveSupply = 100;
    uint256 public BAYCMAYCHolderSupply = 1000;
    uint256[] public freeMintArray = [3,2,1];
    uint256[] public supplyMintArray = [3000,5000,7000];

    constructor(address baycContract) ERC721A("Mecha Ape Yacht Club", "MechaApeYC",maxPerTransaction,maxSupply)
    {
        BAYCHolder = IBAYC(baycContract);
    }

    function mint(uint256 qty) external payable
    {
        uint freeMint = FreeMintBatch(totalSupply());
        require(Minting , "MechaApeYC Minting Close !");
        require(qty <= maxPerTransaction, "MechaApeYC Max Per Tx !");
        require(totalSupply() + qty <= publicSupply,"MechaApeYC Soldout !");
        if(MechaApeList[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"MechaApeYC Insufficient Funds !");
            MechaApeList[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"MechaApeYC Insufficient Funds !");
            MechaApeList[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function BAYCHolderClaim() external payable
    {
        require(Minting , "MechaApeYC Minting Close !");
        require(totalSupply() + 1 <= maxSupply,"MechaApeYC Soldout !");
        require(BAYCHolder.balanceOf(_msgSender()) > 0, "Not BAYC Holder");
        require(BAYCList[msg.sender] == 0,"MechaApeYC Claimed");
        BAYCList[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function FreeMintBatch(uint qty) public view returns (uint256) {
        if(qty < supplyMintArray[0])
        {
            return freeMintArray[0];
        }
        else if (qty < supplyMintArray[1])
        {
            return freeMintArray[1];
        }
        else if (qty < supplyMintArray[2])
        {
            return freeMintArray[2];
        }
        else
        {
            return 0;
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] calldata listedAirdrop ,uint256 qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty);
        }
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setPublicMinting() external onlyOwner {
        Minting  = !Minting ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }

    function setmaxPerTransaction(uint256 maxPerTransaction_) external onlyOwner {
        maxPerTransaction = maxPerTransaction_;
    }

    function setsupplyMintArray(uint256[] calldata supplyMintArray_) external onlyOwner {
        supplyMintArray = supplyMintArray_;
    }
    
    function setfreeMintArray(uint256[] calldata freeMintArray_) external onlyOwner {
        freeMintArray = freeMintArray_;
    }

    function setPublicSupply(uint256 maxMint_) external onlyOwner {
        publicSupply = maxMint_;
    }

    function setMaxSupply(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }

    function setContractBAYC(address contract_) external onlyOwner {
        BAYCHolder = IBAYC(contract_);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}