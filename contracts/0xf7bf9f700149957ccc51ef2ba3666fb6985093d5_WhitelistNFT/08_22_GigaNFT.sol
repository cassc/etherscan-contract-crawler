// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/AzukiNFT.sol";

contract GigaNFT is AzukiNFT {

    uint16 public constant maxSupply = 6666;
    uint8 public maxMintAmountPerWallet = 5;
    bool public paused = true;
    uint public cost = 0.0069 ether;
    mapping (address => uint8) public NFTPerAddress;

    constructor(string memory name_, string memory symbol_, uint256 initialMint, string memory blindBoxTokenURI) AzukiNFT(name_, symbol_, initialMint, blindBoxTokenURI) {}

    function mint(uint256 _mintAmount) override external payable {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        uint8 nft = NFTPerAddress[msg.sender];
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max Nft allowed per Wallet.");
    
        require(!paused, "The contract is paused!");
        if(nft >= 1 )
        {
            require(msg.value >= cost * _mintAmount , "Insufficient Fundsss");
        }
        else
        {
            require(msg.value >= cost * (_mintAmount - 1) , "Insufficient Fundsss");
        }
        _safeMint(msg.sender , _mintAmount);

        NFTPerAddress[msg.sender] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function reserve(uint16 _mintAmount, address _receiver) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Excedes max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setCost(uint _Cost) external onlyOwner {
        cost = _Cost;
    }

    function setMaxMintAmountPerWallet(uint8 _maxtx) external onlyOwner{
        maxMintAmountPerWallet = _maxtx;
    }

    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance );        
    }
}