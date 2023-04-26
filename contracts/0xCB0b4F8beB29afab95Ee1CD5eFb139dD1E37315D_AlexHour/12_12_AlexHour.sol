// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlexHour is ERC1155, Ownable {
    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenPrices;

    constructor(string memory baseURI) ERC1155(baseURI) {}

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function setURI(uint256 tokenId, string memory _uri) public onlyOwner {
        require(!_exists(tokenId), "AlexHour: token URI already exists");
        _tokenURIs[tokenId] = _uri;
    }

    function price(uint256 tokenId) public view returns (uint256) {
        return _tokenPrices[tokenId];
    }

    function setPrice(uint256 tokenId, uint256 price) public onlyOwner {
        require(_exists(tokenId), "AlexHour: token not minted yet");
        _tokenPrices[tokenId] = price;
    }

    function mint(
        address account,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        require(account != address(0), "AlexHour: mint to the zero address");
        require(_exists(tokenId), "AlexHour: token does not exist");

        _mint(account, tokenId, amount, "");
    }

    function purchase(uint256 tokenId, uint256 amount) public payable {
        require(_exists(tokenId), "AlexHour: token does not exist");
        require(
            msg.value >= _tokenPrices[tokenId] * amount,
            "AlexHour: insufficient payment"
        );

        _mint(msg.sender, tokenId, amount, "");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "AlexHour: no balance to withdraw");
        payable(owner()).transfer(balance);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return bytes(_tokenURIs[tokenId]).length > 0;
    }
}