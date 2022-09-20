// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BoredPandaYachtClub is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public AddressMinted;
    bool public mintIsLive  = false;
    uint public MintPrice = 2500000000000000;
    string public baseURI;  
    uint public devSuppy = 50;  
    uint public maxSupply = 5000;
    uint public freeMint = 2;
    uint public maxMintPerTx = 15;  

    constructor() ERC721A("Bored Panda Yacht Club", "BPYC",50,5000){}

    function mint(uint256 qty) external payable
    {
        require(mintIsLive , "BPYC : Minting Close");
        require(qty <= maxMintPerTx, "BPYC : Limit");
        require(totalSupply() + qty <= maxSupply-devSuppy,"BPYC : Soldout");
        if(AddressMinted[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"BPYC : Fund not enough");
            AddressMinted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"BPYC : Fund not enough");
            AddressMinted[msg.sender] += qty;
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

    function setMintLive() external onlyOwner {
        mintIsLive  = !mintIsLive ;
    }

    function setmaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        maxMintPerTx = maxMintPerTx_;
    }

    function setMaxFreeMint(uint256 qty_) external onlyOwner {
        freeMint = qty_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
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