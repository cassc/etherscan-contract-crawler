// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LOVE is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    uint256 public price;
    uint256 public priceWhitelist;
    uint256 public immutable maxSupply;
    uint256 public supplyCap;
    bool public mintingEnabled = true;
    mapping(address => bool) public whitelist;

    string private _baseURIPrefix;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _supplyCap,
        uint256 _price,
        uint256 _priceWhiteList,
        string memory _uri
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        supplyCap = _supplyCap;
        price = _price;
        priceWhitelist = _priceWhiteList;
        _baseURIPrefix = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function setWhitelist(address[] calldata newAddresses) external onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setPriceWhitelist(uint256 newPrice) external onlyOwner {
        priceWhitelist = newPrice;
    }

    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mintNFT(uint256 quantity) external payable {
        require(
            totalSupply().add(quantity) <= maxSupply,
            "Max supply exceeded"
        );
        require(
            totalSupply().add(quantity) <= supplyCap,
            "Supply cap exceeded"
        );
        if (_msgSender() != owner()) {
            require(mintingEnabled, "Minting has not been enabled");
        }
        require(quantity > 0, "Invalid quantity");

        if (whitelist[_msgSender()]) {
            require(
                priceWhitelist.mul(quantity) == msg.value,
                "Incorrect ETH value"
            );
        } else {
            require(price.mul(quantity) == msg.value, "Incorrect ETH value");
        }

        require(!_msgSender().isContract(), "Contracts are not allowed");

        _safeMint(_msgSender(), quantity);
    }

    function creatorMint(uint256 quantity) external onlyOwner {
        _safeMint(_msgSender(), quantity);
    }

    function airdrop(address[] calldata to) external onlyOwner {
        require(
            totalSupply().add(to.length) <= maxSupply,
            "Max supply exceeded"
        );
        require(
            totalSupply().add(to.length) <= supplyCap,
            "Supply cap exceeded"
        );

        for (uint256 i = 0; i < to.length; i++) _safeMint(to[i], 1);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}