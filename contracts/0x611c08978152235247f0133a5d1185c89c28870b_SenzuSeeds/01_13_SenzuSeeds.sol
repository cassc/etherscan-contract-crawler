// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SenzuSeeds is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private _baseTokenURI;
    uint256 private _reserved = 100;
    uint256 private _price = 0.03 * 10**18;
    uint256 private _maxInitialTrees = 10001;
    uint256 private _maxTX = 51;
    bool public _paused = true;

    constructor() ERC721("Senzu Seeds", "SENZUSDS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mintTrees(uint256 _num) public payable {
        uint256 _supply = totalSupply();
        require(!_paused, "Sale paused");
        require(_num < _maxTX, "Exceeds maximum of Trees per transaction");
        require(
            _supply + _num < _maxInitialTrees,
            "Exceeds maximum Trees supply"
        );
        require(msg.value >= _price * _num, "Ether sent is not correct");

        for (uint256 i; i < _num; i++) {
            _safeMint(msg.sender, _supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function walletOfOwnerTokensURI(address _owner)
        public
        view
        returns (string[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        string[] memory tokensURI = new string[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            tokensURI[i] = tokenURI(tokenId);
        }
        return tokensURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setMaxInitialTrees(uint256 _newMax) public onlyOwner() {
        _maxInitialTrees = _newMax;
    }

    function getMaxInitialTrees() public view returns (uint256) {
        return _maxInitialTrees;
    }

    function setMaxTX(uint256 _newMaxTX) public onlyOwner() {
        _maxTX = _newMaxTX;
    }

    function getMaxTX() public view returns (uint256) {
        return _maxTX;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}