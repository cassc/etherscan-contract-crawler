// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StarTraveller is ERC721A, Ownable {
    string public baseURI = "ipfs://QmSgDCearwRuX4FbMJWsH7yyo9FzXPXqrHEQyC2DVWjaED/";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 3333;
    uint32 public immutable perTxLimit = 10;
    mapping(address => bool) public freeMap;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("StarTraveller", "ST") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function travel(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 10 amount");
        if(freeMap[msg.sender])
        {
            require(msg.value >= amount * mintPrice,"insufficient value");
        }
        else 
        {
            freeMap[msg.sender] = true;
            require(msg.value >= (amount-1) * mintPrice,"insufficient value");
        }
        _safeMint(msg.sender, amount);
    }

    function getMintedFree(address addr) public view returns (bool){
        return freeMap[addr];
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}