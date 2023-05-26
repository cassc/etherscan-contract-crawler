// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract EtherChess is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmUes4mEsT9j558iWP5hNsbzyxRw3qsVHQUbpjPvz1DrEA/";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 5555;
    uint32 public immutable perTxLimit = 10;

    mapping(address => bool) public freeMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("EtherChess", "EC") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 10 amount");
        require(msg.value >= (amount-1) * mintPrice,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}