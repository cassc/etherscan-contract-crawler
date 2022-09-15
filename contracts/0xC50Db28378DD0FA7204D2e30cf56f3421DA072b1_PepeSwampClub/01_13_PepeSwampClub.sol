// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract PepeSwampClub is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    bool public StatusMinting  = true;
    uint public MintPrice = 0.0025 ether; //0.0025 ETH
    string public baseURI;  
    uint public freeMint = 2;
    uint public maxMintPerTx = 20;  
    uint public maxSupply = 6969;

    constructor() ERC721A("Pepe Swamp Club", "PPSC",88,8888){}

    function mint(uint256 qty) external payable
    {
        require(StatusMinting , "PPSC:  Minting Public Pause");
        require(qty <= maxMintPerTx, "PPSC:  Limit Per Transaction");
        require(totalSupply() + qty <= maxSupply,"PPSC:  Soldout");
        _safemint(qty);
    }

    function _safemint(uint256 qty) internal
    {
        if(WalletMint[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"PPSC: Not Enough Ethereum");
            WalletMint[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"PPSC: Not Enough Ethereum");
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
        StatusMinting  = !StatusMinting ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 qty_) external onlyOwner {
        MintPrice = qty_;
    }

    function setMintPerTx(uint256 qty_) external onlyOwner {
        maxMintPerTx = qty_;
    }

    function setFreeMint(uint256 qty_) external onlyOwner {
        freeMint = qty_;
    }

    function setMaxSupply(uint256 qty_) external onlyOwner {
        maxSupply = qty_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}