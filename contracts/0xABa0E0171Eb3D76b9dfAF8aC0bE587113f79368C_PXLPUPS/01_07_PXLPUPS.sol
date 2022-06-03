// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PXLPUPS is ERC721A, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    bool public isOpen = false;

    uint256 public price = 0.005 ether;
    uint256 public maxPerTransaction = 10;
    uint256 public maxFreePerTransaction = 5;
    uint256 public maxFreePerWallet = 10;
    uint256 public maxTotalSupply = 5555;
    uint256 public freeAdoptsLeft = 2000;

    string public baseURI;
    string public provenanceHash;

    mapping(address => uint256) public freeAdoptsPerWallet;

    address private withdrawAddress = address(0);

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function adopt(uint256 _amount) external payable nonReentrant {
        require(isOpen, "Sale not open");
        require(_amount > 0, "Must adopt at least one");
        require(totalSupply().add(_amount) <= maxTotalSupply, "Exceeds available supply");

        if (msg.value == 0 && freeAdoptsLeft >= _amount) {
            require(_amount <= maxFreePerTransaction, "Exceeds max free per transaction");
            require(freeAdoptsPerWallet[_msgSender()].add(_amount) <= maxFreePerWallet, "Exceeds max free per wallet");
            freeAdoptsPerWallet[_msgSender()] = freeAdoptsPerWallet[_msgSender()].add(_amount);
            freeAdoptsLeft = freeAdoptsLeft.sub(_amount);
        } else {
            require(_amount <= maxPerTransaction, "Exceeds max per transaction");
            require(price.mul(_amount) <= msg.value, "Incorrect amount * price value");
        }

        _safeMint(_msgSender(), _amount);
    }

    function privateAdopt(uint256 _amount, address _receiver) external onlyOwner {
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds available supply");
        _safeMint(_receiver, _amount);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setFreeAdoptsLeft(uint256 _newValue) external onlyOwner {
        freeAdoptsLeft = _newValue;
    }

    function setMaxTotalSupply(uint256 _maxValue) external onlyOwner {
        maxTotalSupply = _maxValue;
    }

    function setMaxPerTransaction(uint256 _maxValue) external onlyOwner {
        maxPerTransaction = _maxValue;
    }

    function setMaxFreePerTransaction(uint256 _maxValue) external onlyOwner {
        maxFreePerTransaction = _maxValue;
    }

    function setMaxFreePerWallet(uint256 _maxValue) external onlyOwner {
        maxFreePerWallet = _maxValue;
    }

    function setIsOpen(bool _open) external onlyOwner {
        isOpen = _open;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawAddress(address _newAddress) external onlyOwner {
        withdrawAddress = _newAddress;
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "Withdraw address not set");
        uint256 ethBalance = address(this).balance;
        payable(withdrawAddress).transfer(ethBalance);
    }
}