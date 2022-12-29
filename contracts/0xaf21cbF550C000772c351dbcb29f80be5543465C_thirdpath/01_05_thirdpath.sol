// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./libraries/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract thirdpath is ERC721A, Ownable {
    bool public live = false;
    uint256 public price = 0.005 ether;
    uint256 public constant totalsupply = 2000;
    string public baseURI = "https://thirdpath.xyz/";
    uint256 public constant maxPerWallet = 3;

    constructor() ERC721A("Third Path", "trdPNFT") {
        _mint(msg.sender, 1);
    }

    function setTokenUri(string calldata _baseTokenUri) public onlyOwner {
        baseURI = _baseTokenUri;
    }

    function setPrice(uint256 val) public onlyOwner {
        price = val;
    }

    function toggle(bool val) external onlyOwner {
        live = val;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI,_toString(tokenId),".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function openMint(uint256 amt) external payable {
        require(live, "Sale not live yet");
        require(amt > 0 ,"Amount cannot be zero");
        require(totalsupply >= _totalMinted() + amt, "Sold out!");
        require(tx.origin == msg.sender, "Contract mint is not allowed!");
        require(maxPerWallet >= _numberMinted(msg.sender) + amt, "max 3 per wallet!");
        require(msg.value >= amt * price, "Insufficient funds");
        _mint(msg.sender, amt);
    }
}