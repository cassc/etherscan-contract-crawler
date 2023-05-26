//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TweetDaoNft is ERC721Enumerable, Ownable {
    uint256 public MAX_PUBLIC_SUPPLY = 9950;

    string public baseUri = "https://gateway.pinata.cloud/ipfs/QmUQLowzXxNqtGqCxq2YgAxo9R31ixS4AuGFVQMU96BX3V/";

    constructor() ERC721("Tweet DAO Eggs", "TWEETDAO") {
    }

    function mint() public payable {
        require(totalSupply() < MAX_PUBLIC_SUPPLY, "Minted out");
        require(msg.value == getPrice(), "Payment low");
        _mint(msg.sender, totalSupply() + 1);
    }

    function creatorMint() public onlyOwner {
        require(totalSupply() >= MAX_PUBLIC_SUPPLY, "Public sale isn't over");
        for (uint i = 0; i < 50; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
    }

    function getPrice() public view returns (uint256) {
        return (totalSupply() / 100 + 1) * 0.1 ether;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}