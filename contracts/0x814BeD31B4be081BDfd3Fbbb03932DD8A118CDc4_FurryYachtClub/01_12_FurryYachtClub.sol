// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract FurryYachtClub is ERC721A, Ownable {
    string public baseURI = "";

    uint256 public immutable cost = 0.001 ether;
    uint32 public immutable MAX_SUPPLY = 5000;
    uint32 public immutable PER_MINT_MAX = 10;

    mapping(address => bool) public freeClaimed;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("FurryYachtClub", "FYC") {
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

    function mint(uint32 amount) public payable callerIsUser{
        if (totalSupply() + amount <= MAX_SUPPLY)
        {
            require(totalSupply() + amount <= MAX_SUPPLY,"sold out");
            require(amount <= PER_MINT_MAX,"max 10 amount");
            if(freeClaimed[msg.sender])
            {
                require(msg.value >= amount * cost,"value not correct");
            }
            else 
            {
                freeClaimed[msg.sender] = true;
                require(msg.value >= (amount-1) * cost,"value not correct");
            }
            _safeMint(msg.sender, amount);
        }
    }

    function getFreeClaimed(address addr) public view returns (bool){
        return freeClaimed[addr];
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}