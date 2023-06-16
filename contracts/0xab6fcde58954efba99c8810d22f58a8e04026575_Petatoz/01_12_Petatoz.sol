// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Petatoz is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmQcwMQnFEX1wAYntzWfmW3wQWb59ACxfUjr3xtFSRGEAR/";
    uint32 public fAmount = 5;
    uint256 public price = 0.001 ether;
    uint32 public immutable maxSupply = 6969;
    mapping(address => bool) public freeMinted;
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Petatoz", "Petatoz") {
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

    function mintPetatoz(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"Sold Out");
        require(amount <= 20,"Max 20 Per");
        if(freeMinted[msg.sender])
        {
            require(msg.value >= amount * price,"Insufficient Eth");
        }
        else 
        {
            freeMinted[msg.sender] = true;
            require(msg.value >= (amount-fAmount) * price,"Insufficient Eth");
        }
        _safeMint(msg.sender, amount);
    }

    function setFreeAndPrice(uint32 f,uint256 p) public onlyOwner {
        fAmount = f;
        price = p;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;
        address h = payable(msg.sender);
        bool success;
        (success, ) = h.call{value: sendAmount}("");
        require(success, "Unsuccessful");
    }
}