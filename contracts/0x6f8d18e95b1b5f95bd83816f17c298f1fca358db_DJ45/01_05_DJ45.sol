// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract DJ45 is ERC721A, Ownable {
    uint256 public price;
    string public baseTokenURI;

    error InvalidQuantity(uint256 quantity);
    error LimitReached();
    error NotEnoughEth();

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI,
        uint256 _price
    ) ERC721A(name, symbol) {
        price = _price;
        baseTokenURI = _baseTokenURI;
    }

    function mint(uint256 quantity) external payable {
        if (quantity > 45 || quantity == 0) {
            revert InvalidQuantity(quantity);
        }
        if (totalSupply() + quantity > 10045) {
            revert LimitReached();
        }
        if (msg.value < price * quantity) {
            revert NotEnoughEth();
        }

        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity, address _receiver) external onlyOwner {
        if (quantity > 45 || quantity == 0) {
            revert InvalidQuantity(quantity);
        }
        if (totalSupply() + quantity > 10045) {
            revert LimitReached();
        }

        _mint(_receiver, quantity);
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}