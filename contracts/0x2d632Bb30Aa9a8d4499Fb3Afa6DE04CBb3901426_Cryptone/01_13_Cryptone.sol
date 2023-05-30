// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Cryptone is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(address => uint256) private _mintedList;

    string private _baseTokenURI;
    uint256 private _fee = 10000000000000000; // 0.01 ETH
    uint256 private _trackId = 1;

    uint256 public totalColors = 10000;
    uint256 public maxPerAddress = 20;
    bool public canMint;

    constructor() ERC721("Cryptone", "COLOR") {}

    // Mints next available
    function mintRandom() public {
        require(canMint, "Minting is currently disabled");
        require(totalSupply() <= totalColors, "All colors have been minted");
        for (uint256 i = _trackId; i <= totalColors; i++) {
            if (!_exists(i)) {
                safeMint(_msgSender(), i, 0);
                _trackId = i + 1;
                break;
            }
        }
    }

    function mintSpecific(uint256 tokenId) public payable {
        safeMint(_msgSender(), tokenId, _fee);
    }

    function mintOwner(uint256[] calldata tokenIds) public onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; i++) {
          uint256 tokenId = tokenIds[i];
          _safeMint(_msgSender(), tokenId);
        }
    }

    function safeMint(address to, uint256 tokenId, uint256 cost) private returns (uint256) {
        require(canMint, "Minting is currently disabled");
        require(_mintedList[msg.sender] < maxPerAddress, "You have reached your minting limit");
        require(tokenId > 0 && tokenId <= totalColors, "Invalid Token ID");
        require(cost <= msg.value, "Ether value sent is not correct");

        _safeMint(to, tokenId);

        _mintedList[msg.sender] += 1;

        return tokenId;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setCanMint(bool allow) public onlyOwner {
        canMint = allow;
    }

    function setMaxPerAddress(uint256 max) public onlyOwner {
        maxPerAddress = max;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        return "";
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}