// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract CryptoSectors is ERC721A, Ownable {
    uint256 constant numSectors = 8065;
    string public baseURI =
        "https://cryptosectors-token-data.s3.amazonaws.com/metadata/";

    // hash of the string "x_0,x_1,...x_8064" where x_i is the cell ID of token i
    string public sectorOrderHash =
        "0xf9e8c65fca03d5438d85ec52bf5ac2de3763461cc92c9926af665ff03818d6be";

    uint256 private _priceBase = 0.01 ether;
    uint256 private _priceGradient = _priceBase;

    constructor() ERC721A("CryptoSectors", "CRYSEC") {}

    function mint(uint256 amount) external payable {
        require(_totalMinted() + amount <= numSectors);
        require(amount <= 20);
        require(msg.value == currentPrice() * amount);
        _mint(msg.sender, amount);
    }

    function currentPrice() public view returns (uint256) {
        uint256 bucket = (100 * _totalMinted()) / numSectors / 10;
        return _priceBase + _priceGradient * bucket;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function setPriceParams(
        uint256 priceBase,
        uint256 priceGradient
    ) external onlyOwner {
        _priceBase = priceBase;
        _priceGradient = priceGradient;
    }

    function empty() external {
        payable(owner()).call{value: address(this).balance}("");
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId));
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }
}
