// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Example is Ownable, ERC721A {
    uint256 public collectionSize=777;
    string private _baseTokenURI="https://data.awakenkakusei.net/metadata/";

    constructor() ERC721A("test", "test") {
        _safeMint(msg.sender, 1);
    }  
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        _safeMint(msg.sender, quantity);
    }
    function mint(uint256 quantity)
    external
    callerIsUser
    {
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        _safeMint(msg.sender, quantity);
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance } ("");
        require(success, "Transfer failed.");
    }
    function setAmount(uint256 amount) public onlyOwner
    {
        collectionSize = amount;
    }
    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
     function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), ".json"));
    }
}