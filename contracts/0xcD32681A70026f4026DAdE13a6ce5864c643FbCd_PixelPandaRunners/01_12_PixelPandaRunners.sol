// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelPandaRunners is ERC721A, Ownable {
    string public baseURI = "";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 5555;
    uint32 public immutable perTxLimit = 10;
    mapping(address => bool) public freeClaimedMap;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "must user");
        _;
    }

    constructor()
    ERC721A ("PixelPandaRunners", "PPR") {
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

    function getFreeClaimedAddr(address addr) public view returns (bool){
        return freeClaimedMap[addr];
    }

    function pandaMint(uint32 quantity) public payable callerIsUser{
        require(totalSupply() + quantity <= maxSupply,"already sold out");
        require(quantity <= perTxLimit,"max 10 quantity");
        if(freeClaimedMap[msg.sender])
        {
            require(msg.value >= quantity * mintPrice,"insufficient value");
        }
        else 
        {
            freeClaimedMap[msg.sender] = true;
            require(msg.value >= (quantity-1) * mintPrice,"insufficient value");
        }
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}