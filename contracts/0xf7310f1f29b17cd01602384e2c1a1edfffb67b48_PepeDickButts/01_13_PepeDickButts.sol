// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract PepeDickButts is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    bool public MintStartEnabled  = false;
    uint public MintPrice = 3000000000000000; //0.003 ETH
    string public baseURI;  
    uint public devSuppy = 20;  
    uint public maxMint = 6969;
    uint public freeMint = 3;
    uint public maxMintPerTx = 20;  

    constructor() ERC721A("PepeDickButts", "PepeDickButts",69,6969){}

    function mint(uint256 qty) external payable
    {
        require(MintStartEnabled , "PepeDickButts Minting Close");
        require(qty <= maxMintPerTx, "PepeDickButts : Limit");
        require(totalSupply() + qty <= maxMint-devSuppy,"PepeDickButts : Soldout");
        if(WalletMint[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"PepeDickButts : Fund not enough");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"PepeDickButts : Fund not enough");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdropNFT(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setPublicMinting() external onlyOwner {
        MintStartEnabled  = !MintStartEnabled ;
    }

    function setmaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        maxMintPerTx = maxMintPerTx_;
    }

    function setMaxFreeMint(uint256 qty_) external onlyOwner {
        freeMint = qty_;
    }

    function setmaxMint(uint256 maxMint_) external onlyOwner {
        maxMint = maxMint_;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }


    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}