// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Y33ts is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public ListWallet;
    bool public MintStartEnabled  = false;
    uint public MintPrice = 3000000000000000; //0.003 ETH
    string public baseURI;  
    uint public threeFreeMint = 1;
    uint public twoFreeMint = 2;
    uint public oneFreeMint = 3;
    uint public maxMintPerTx = 20;  
    uint public maxMint = 6969;
    uint public FreeMintBatchOne = 4000;
    uint public FreeMintBatchTwo = 5500;
    uint public FreeMintBatchThree = 6000;

    constructor() ERC721A("Y33ts", "Y33ts",100,6969){}

    function mint(uint256 qty) external payable
    {
        uint freeMint = FreeMintBatch(totalSupply());
        require(MintStartEnabled , "Warning : Minting Pause");
        require(qty <= maxMintPerTx, "Warning : Max Per Transaction");
        require(totalSupply() + qty <= maxMint,"Warning : Soldout");
        if(ListWallet[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Warning : Insufficient Funds");
            ListWallet[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Warning : Insufficient Funds");
            ListWallet[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function FreeMintBatch(uint qty) public view returns (uint256) {
        if(qty < FreeMintBatchOne)
        {
            return oneFreeMint;
        }
        else if (qty < FreeMintBatchTwo)
        {
            return twoFreeMint;
        }
        else if (qty < FreeMintBatchThree)
        {
            return threeFreeMint;
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

    function setMaxFreeMintOne(uint256 qty_) external onlyOwner {
        oneFreeMint = qty_;
    }
    
    function setMaxFreeMintTwo(uint256 qty_) external onlyOwner {
        twoFreeMint = qty_;
    }

    function setMaxFreeMintThree(uint256 qty_) external onlyOwner {
        threeFreeMint = qty_;
    }

    function setBatchMintOne(uint256 qty_) external onlyOwner {
        FreeMintBatchOne = qty_;
    }
    
    function setBatchMintTwo(uint256 qty_) external onlyOwner {
        FreeMintBatchTwo = qty_;
    }

    function setBatchMintThree(uint256 qty_) external onlyOwner {
        FreeMintBatchThree = qty_;
    }

    function setmaxMint(uint256 maxMint_) external onlyOwner {
        maxMint = maxMint_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}