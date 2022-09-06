// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
░▒█▄░▒█░▄▀▀▄░▄▀▀▄░█▀▀▄░█▀▀▄░░▀░░█▀▀▄░█▀▀▄░█▀▀
░▒█▒█▒█░█░░█░█░░█░█░▒█░█▀▀▄░░█▀░█▄▄▀░█▀▀▄░▀▀▄
░▒█░░▀█░░▀▀░░░▀▀░░▀░░▀░▀▀▀▀░▀▀▀░▀░▀▀░▀▀▀▀░▀▀▀
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Noonbirbs is ERC721A, Ownable {

    uint256 public MAX_SUPPLY = 10000;
    uint256 public MINT_COST = 0.0069 ether;
    uint256 public MAX_MINT = 30;

    string public uriPrefix = '';
  
    bool public saleIsActive;

    constructor() ERC721A("Noonbirbs", "NB") {
        saleIsActive = false;
    }

    function mint(uint256 _mintAmount) public payable {
        require(saleIsActive, "Noonbirbs are not on sale yet.");
        require(_mintAmount <= MAX_MINT, "Exceeded max Noonbirbs per transaction.");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough Noonbirbs remaining.");
        require(msg.value >= MINT_COST * _mintAmount, "Not enough ETH to mint.");
  
        _safeMint(msg.sender, _mintAmount);

    }

    function devMint(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough Noonbirbs remaining.");
        
        _safeMint(_receiver, _mintAmount);
        
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setMintCost(uint256 _newMintCost) public onlyOwner {
        MINT_COST = _newMintCost;
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner {
        MAX_MINT = _newMaxMint;
    }

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}