// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract AnonymousPunkz is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    bool public MintStartEnabled  = false;
    string public baseURI;  
    uint public freeMintSupply = 7500;
    uint public freeMint = 2;
    uint public maxMintPerTx = 20;  
    uint public maxMint = 10000;
    uint public MintPrice = 2200000000000000; //0.0022 ETH

    constructor() ERC721A("Anonymous Punkz", "Anon Punkz",100,10000){}

    function mint(uint256 qty) external payable
    {
        require(MintStartEnabled , "Notice : Minting Public Pause");
        require(qty <= maxMintPerTx, "Notice : Limit Per Transaction");
        require(totalSupply() + qty <= maxMint,"Notice : Soldout");
        _mint(qty);
    }

    function _mint(uint qty) internal {
        if(WalletMint[msg.sender] < freeMint && freeMintSupply > totalSupply()) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Notice : Claim Free NFT");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Notice : Fund not enough");
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

    function setMaxFreeMintSupply(uint256 qty_) external onlyOwner {
        freeMintSupply = qty_;
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