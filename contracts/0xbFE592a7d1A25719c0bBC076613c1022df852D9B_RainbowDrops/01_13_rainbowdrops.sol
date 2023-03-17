// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RainbowDrops is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public tokenPrice;
    bool public saleIsActive = false;
    string private _baseTokenURI;

    Counters.Counter private _tokenIdTracker;

    constructor(string memory baseTokenURI, uint256 initialTokenPrice) ERC721("RainbowDrops", "GANFT") {
        _baseTokenURI = baseTokenURI;
        tokenPrice = initialTokenPrice;
    }

    function mint() public payable {
        require(saleIsActive, "Sale is not active.");
        require(_tokenIdTracker.current() < MAX_SUPPLY, "All tokens have been minted.");
        require(msg.value >= tokenPrice, "Insufficient payment.");

        uint256 newTokenId = _tokenIdTracker.current();
        _safeMint(msg.sender, newTokenId);
        _tokenIdTracker.increment();
    }

    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function setTokenPrice(uint256 newTokenPrice) public onlyOwner {
        tokenPrice = newTokenPrice;
    }

    function setSaleIsActive(bool isActive) public onlyOwner {
        saleIsActive = isActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist.");

        return string(abi.encodePacked(_baseURI(), "?tokenId=", uint2str(tokenId)));
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }

        return string(bstr);
    }
}