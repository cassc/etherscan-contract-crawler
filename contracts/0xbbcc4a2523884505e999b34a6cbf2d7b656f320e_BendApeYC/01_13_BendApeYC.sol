// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BendApeYC is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    bool public MintStartEnabled  = false;
    uint public MintPrice = 1000000000000000; //0.001 ETH
    string public baseURI;  
    uint public freeMint = 4;
    uint public maxMintPerTx = 40;  
    uint public maxMint = 10000;

    constructor() ERC721A("Bend Ape Yacht Club", "Bend Ape YC",100,10000){}

    function mint(uint256 qty) external payable
    {
        require(MintStartEnabled , "INFO : Minting Public Pause");
        require(qty <= maxMintPerTx, "INFO : Limit Per Transaction");
        require(totalSupply() + qty <= maxMint,"INFO : Soldout");
        _safemint(qty);
    }

    function _safemint(uint256 qty) internal
    {
        if(WalletMint[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"INFO : Claim Free NFT");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"INFO : Fund not enough");
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
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
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

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}