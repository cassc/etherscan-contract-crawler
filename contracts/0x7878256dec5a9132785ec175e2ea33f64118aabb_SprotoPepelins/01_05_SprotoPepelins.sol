// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SprotoPepelins is ERC721A, Ownable {

    uint256 public mintPrice = 0.003 ether;
    uint32 public FreeSupply = 333;
    uint32 public FreePerTxn = 1;
    uint32 public immutable maxSupply = 3333;
    uint32 public immutable MaxPerTxn = 100;
    string  public baseURI = "ipfs://QmcvG99Ne1enpbLCdyLzDHPrjToTLTSDE53UqcQjvbu2Na/";


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
            string memory _name,
            string memory _symbol
    )
    ERC721A (_name, _symbol) {
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
        require(amount <= MaxPerTxn,"exceed maximum");
        if (totalSupply() <= FreeSupply) {
            require(msg.value >= (amount-FreePerTxn) * mintPrice,"insufficient value");
        }
        else
        {
            require(msg.value >= amount * mintPrice,"insufficient value");
        }
        _safeMint(msg.sender, amount);
    }

    function setFreeSupply(uint32 supply) public onlyOwner {
        FreeSupply = supply;
    }

    
    function ownerBatchMint(uint256 amt) external onlyOwner
    {
        require(totalSupply() + amt < maxSupply + 1,"exceed maximum");

        _safeMint(msg.sender, amt);
     }

    function setFreePerTx(uint32 amount) public onlyOwner {
        FreePerTxn = amount;
    }

    function setPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;
        address h = payable(msg.sender);
        bool success;
        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}