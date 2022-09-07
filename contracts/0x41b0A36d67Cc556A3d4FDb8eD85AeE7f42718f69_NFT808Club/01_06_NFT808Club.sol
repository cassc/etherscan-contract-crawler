//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFT808Club is ERC721A, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 808;
    uint256 public constant PRICE = 0.0808 ether;

    bool public operational = true;

    constructor(
        string memory baseURI_
    ) ERC721A("808Club", "808Club") {
        _baseTokenURI = baseURI_;
    }

    function mint(uint256 _mintQty) external payable {
        uint256 supply = totalSupply();
        require(operational, "Operation is paused");
        require(_mintQty > 0, "Must mint minimum of 1 token");
        require(supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        require(msg.value == _mintQty * PRICE, "Amount of Ether sent is not correct");
        
        _mint(msg.sender, _mintQty);
    }

    function devMint(uint256 _mintQty) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        
        _mint(msg.sender, _mintQty);
    }

    function toggleOperational() external onlyOwner {
        operational = !operational;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    address private constant creatorAddress = 0x164A08A26F2a7f06387dDA1b7FE2BcB2fb1599c2;

    function withdraw() external onlyOwner {
        (bool success, ) = creatorAddress.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}