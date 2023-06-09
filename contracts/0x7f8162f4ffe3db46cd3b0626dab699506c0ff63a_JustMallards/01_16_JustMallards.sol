// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// https://ipfs.io/ipfs/QmWnEYforuPHFroBvzQvjjGbwGQMpg4KAmt28HosKPncuq/

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract JustMallards is ERC721, Ownable, RandomlyAssigned {
    using Strings for uint256;
    uint256 public currentSupply = 0;
    bool public paused = true;
    string private _baseURIextended;
    string public baseURI;
    mapping (address => uint) public ownerMallardCount;

    constructor () ERC721("Just Mallards", "MALLARDS") RandomlyAssigned(10000,1) {
    }

    function devMint(uint256 _mintAmount) public payable onlyOwner {
        require( tokenCount() + 1 <= totalSupply(), "Maximum supply has been reached!");
        require( availableTokenCount() - 1 >= 0, "You can't mint more than available token count!"); 
        require( tx.origin == msg.sender, "Looks like you're minting through custom contract!");

        for (uint256 a = 1; a <= _mintAmount; a++) {
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
            currentSupply++;
        }
    }

    function mint () public payable {
        require ( paused == false, "Contract is paused!");
        require( tokenCount() + 1 <= totalSupply(), "Maximum supply has been reached!");
        require( availableTokenCount() - 1 >= 0, "You can't mint more than available token count!"); 
        require( tx.origin == msg.sender, "Looks like you're minting through custom contract!");

        if (msg.sender != owner()) {  
            require (balanceOf(msg.sender) == 0, "Only 1 mint per wallet! -Quack!");
        }

        if (msg.sender != owner()) {  
            require( msg.value >= 0.000 ether);
        }

        uint256 id = nextToken();
        ownerMallardCount[msg.sender]++;
        _safeMint(msg.sender, id);
        currentSupply++;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query  nonexistant token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}