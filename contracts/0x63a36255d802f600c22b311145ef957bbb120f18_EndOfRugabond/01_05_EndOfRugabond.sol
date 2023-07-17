// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract EndOfRugabond is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmRLepPwfWaNkQkPs4kmhkA5vqbpjE6uRssorowBg5GigA/";

    uint256 public mintPrice = 0.001 ether;
    uint32 public earlySupply = 1000;
    uint32 public earlyAmount = 3;
    uint32 public immutable maxSupply = 3000;
    uint32 public immutable perTxLimit = 10;
    uint32 public freeTxLimit = 1;

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
        require(amount <= perTxLimit,"error");
        if (totalSupply() <= earlySupply) {
            require(msg.value >= (amount-earlyAmount) * mintPrice,"insufficient");
        }
        else
        {
            require(msg.value >= (amount-freeTxLimit) * mintPrice,"insufficient");
        }
        _safeMint(msg.sender, amount);
    }

    function setEarlySupply(uint32 supply) public onlyOwner {
        earlySupply = supply;
    }

    function setEarlyAmonunt(uint32 amount) public onlyOwner {
        earlyAmount = amount;
    }

    function setFreeTxLimit(uint32 limit) public onlyOwner {
        freeTxLimit = limit;
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