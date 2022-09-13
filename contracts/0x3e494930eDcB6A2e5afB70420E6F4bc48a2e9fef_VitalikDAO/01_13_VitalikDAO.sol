// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract VitalikDAO is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    string public baseURI;  
    uint public freeMint = 2;
    uint public maxPerTx = 5;  
    uint public maxSupply = 1509;
    uint public reserveSupply = 20;
    uint public MintPrice = 3000000000000000; 
    bool public mintStatus  = false;

    constructor() ERC721A("VitalikDAO 2.0", "VitalikDAO 2.0",1509,1509){}

    function mint(uint256 qty) external payable
    {
        require(mintStatus , "Minting Pause");
        require(qty <= maxPerTx, "Limit Per Transaction");
        require(totalSupply() + qty <= maxSupply-reserveSupply,"Soldout");
         
        if(WalletMint[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Fund not enough");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Fund not enough");
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
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }

    function setmaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxFreeMint(uint256 qty_) external onlyOwner {
        freeMint = qty_;
    }

    function setmaxMint(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }

    function setReserveSupply(uint256 reserveSupply_) external onlyOwner {
        reserveSupply = reserveSupply_;
    }

    function setPublicMinting() external onlyOwner {
        mintStatus  = !mintStatus ;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}