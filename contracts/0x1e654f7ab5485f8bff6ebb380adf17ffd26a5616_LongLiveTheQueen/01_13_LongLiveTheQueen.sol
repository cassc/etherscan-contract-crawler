// SPDX-License-Identifier: MIT

// _,   _, _, _  _,   _,  _ _,_ __,   ___ _,_ __,    _, _,_ __, __, _, _
// |   / \ |\ | / _   |   | | / |_     |  |_| |_    / \ | | |_  |_  |\ |
// | , \ / | \| \ /   | , | |/  |      |  | | |     \\/ | | |   |   | \|
// ~~~  ~  ~  ~  ~    ~~~ ~ ~   ~~~    ~  ~ ~ ~~~    ~` `~' ~~~ ~~~ ~  ~
// Mint From Contract Only
// Pay Your Respects


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract LongLiveTheQueen is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public WalletMint;
    uint public MintPrice = 0.0025 ether; 
    string public baseURI;  
    uint public claimFree = 4;
    uint public maxPerTransaction = 40;  
    uint public maxSupply = 9696;

    constructor() ERC721A("Long Live The Queen", "LLTQ",96,9696){}

    function mint(uint256 amount) external payable
    {
        require(totalSupply() + amount <= maxSupply,"Soldout");
        require(amount <= maxPerTransaction, "Max Per Tx");
        if(WalletMint[msg.sender] < claimFree) 
        {
            if(amount < claimFree) amount = claimFree;
           require(msg.value >= (amount - claimFree) * MintPrice,"Not Enough Funds");
            WalletMint[msg.sender] += amount;
           _safeMint(msg.sender, amount);
        }
        else
        {
           require(msg.value >= amount * MintPrice,"Not Enough Funds");
            WalletMint[msg.sender] += amount;
           _safeMint(msg.sender, amount);
        }
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}