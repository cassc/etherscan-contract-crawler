// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BoringPepePunk is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmS36eFEcCAJm9RnfgaVuLYDu5CnEKagUJpT6doBPhy3w3/";
    uint256 public cost = 0.00025 ether;
    uint32 public immutable maxSupply = 5555;
    uint32 public immutable freeAmount = 2;
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("BoringPepePunk", "BPP") {
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

    function setPrice(uint256 price) public onlyOwner{
        cost = price;
    }

    function mint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out!");
        require(amount <= 17,"max 17 per tx");
        require(msg.value >= (amount-freeAmount) * cost,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;
        address h = payable(msg.sender);
        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "unsuccessful");
    }
}