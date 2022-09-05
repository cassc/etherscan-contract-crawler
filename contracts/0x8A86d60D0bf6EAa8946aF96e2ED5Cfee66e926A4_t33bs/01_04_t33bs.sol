// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './openzeppelin/Ownable.sol';
import './openzeppelin/ERC721A.sol';


/*
  $$\      $$$$$$\   $$$$$$\  $$\                 
  $$ |    $$ ___$$\ $$ ___$$\ $$ |                
$$$$$$\   \_/   $$ |\_/   $$ |$$$$$$$\   $$$$$$$\ 
\_$$  _|    $$$$$ /   $$$$$ / $$  __$$\ $$  _____|
  $$ |      \___$$\   \___$$\ $$ |  $$ |\$$$$$$\  
  $$ |$$\ $$\   $$ |$$\   $$ |$$ |  $$ | \____$$\ 
  \$$$$  |\$$$$$$  |\$$$$$$  |$$$$$$$  |$$$$$$$  |
   \____/  \______/  \______/ \_______/ \_______/ 
*/                                               
                                                  
                                                  
contract t33bs is ERC721A, Ownable {

    uint256 public maxSupply = 7500;
    uint256 public maxFree = 2;
    uint256 public maxPerTxn = 20;
    uint256 public cost = 0.0001 ether;

    address public y33ts;

    bool public mintLive = false;

    string public URI = "ipfs/Qmb5f9Wbj5WNrGG19e1jeoEHgGnqQJn4AhDiG7o8ot9nGv";

    mapping(address => bool) public freeMinted;

    constructor() ERC721A("t33bs", "T33B") {}

    function _baseURI() internal view virtual override returns (string memory) {
		return URI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return URI;
    }

    function mintFree() public {
        require(mintLive == true, "Minting is not active");
        require(totalSupply() + 2 <= maxSupply, "Exceeds max supply");
        require(freeMinted[msg.sender] == false, "Exceeds max free amount");

        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 2);
    }

    function mintPaid(uint256 _mintAmount) public payable {
        require(mintLive == true, "Minting is not active");
        require(totalSupply() + _mintAmount <= maxSupply, "Exceeds max supply");
        require(_mintAmount <= maxPerTxn, "Exceeds max transaction amount");
        require(msg.value >= _mintAmount * cost, "Not enough ether sent");

        _safeMint(msg.sender, _mintAmount);
    }

    function devMint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");

        _safeMint(_to, _amount);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxTxn(uint256 _newMax) public onlyOwner {
        maxPerTxn = _newMax;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
		URI = _newURI;
	}

    function flipMinting() public onlyOwner {
		mintLive = !mintLive;
	}

    function y33t(uint256 _tokenId) external {
        require(msg.sender == y33ts, "Not authorized");

        _burn(_tokenId);
    }
}