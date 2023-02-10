// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OrdinalLoot is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmU6114evnHGBzVLgcRges471KTnbmUF9fpogNMDMF23Rn/";
    uint256 public immutable price = 0.01 ether;
    uint32 public immutable lootSupply = 500;
    uint32 public immutable maxLootPerTx = 5;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Ordinal Loot", "OLoot") {
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

    function mintLoot(uint32 quantity) public payable callerIsUser{
        require(totalSupply() + quantity <= lootSupply,"sold out");
        require(quantity <= maxLootPerTx,"max 5 quantity");
        require(msg.value >= quantity * price,"insufficient value");
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