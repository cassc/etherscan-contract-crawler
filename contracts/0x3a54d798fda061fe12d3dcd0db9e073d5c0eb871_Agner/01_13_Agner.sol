// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Agner is ERC721A, Ownable, ReentrancyGuard {

    bool public Minting  = false;
    uint256 public MintPrice = 3000000000000000;
    string public baseURI;  
    uint256 public maxPerTx = 30;  
    uint256 public maxSupply = 7000;
    uint256[] public freeMintArray = [3,2,1];
    uint256[] public supplyMintArray = [2000,4000,6000];
    mapping (address => uint256) public minted;

    constructor() ERC721A("Agner", "Agner",maxPerTx,maxSupply){}

    function mint(uint256 qty) external payable
    {
        require(Minting , "Agner Minting Close !");
        require(qty <= maxPerTx, "Agner Max Per Tx !");
        require(totalSupply() + qty <= maxSupply,"Agner Soldout !");
        _safemint(qty);
    }
    function _safemint(uint256 qty) internal  {
        uint freeMint = FreeMintBatch(totalSupply());
        if(minted[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Agner Insufficient Funds !");
            minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Agner Insufficient Funds !");
            minted[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
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

    function setmaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setsupplyMintArray(uint256[] calldata supplyMintArray_) external onlyOwner {
        supplyMintArray = supplyMintArray_;
    }
    
    function setfreeMintArray(uint256[] calldata freeMintArray_) external onlyOwner {
        freeMintArray = freeMintArray_;
    }

    function setMaxSupply(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}