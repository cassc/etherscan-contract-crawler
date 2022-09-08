// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NamidaPass is ERC721A, Ownable {
    string public baseURI = "ipfs://QmcJJ1NGbVnW9biEWY7AgxQMKBnqETYiWjBF3MwsTbX2M1/";

    uint256 public immutable mintPrice = 0.005 ether;
    uint32 public immutable maxSupply = 2445;
    uint32 public immutable airDropSupply = 5555;
    uint32 public immutable perTxLimit = 5;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("NamidaPass", "NP") {
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

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 5 amount");
        _safeMint(msg.sender, amount);
    }

    function airDrop(address[] memory addrs,uint32[] memory amounts)  public onlyOwner {
        uint arrayLength = addrs.length;
        for (uint i=0; i<arrayLength; i++) {
            _safeMint(addrs[i], amounts[i]);
        }
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}