// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Nani is ERC721A, Ownable, ReentrancyGuard {
    bool public saleOpen = false;
    uint256 public mintPrice = 0.001 ether;
    uint256 public maxTotalSupply = 1000;
    address private withdrawAddress = address(0);
    string public baseURI;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    function mint(uint256 _amount) external payable nonReentrant {
        require(saleOpen, "Not open");
        require(_amount > 0, "Cannot mint zero");
        require(mintPrice * _amount <= msg.value, "Not enough ETH");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds max supply");
        _safeMint(_msgSender(), _amount);
    }

    function mintSingle() external payable nonReentrant {
        require(saleOpen, "Not open");
        require(mintPrice <= msg.value, "Not enough ETH");
        require(totalSupply() + 1 <= maxTotalSupply, "Exceeds max supply");
        _safeMint(_msgSender(), 1);
    }

    function mintWithFakeProof(uint256 _amount, bytes32[] memory _proof) external payable nonReentrant {
        require(saleOpen, "Not open");
        require(_amount > 0, "Cannot mint zero");
        require(mintPrice * _amount <= msg.value, "Not enough ETH");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds max supply");
        _safeMint(_msgSender(), _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdrawETH() external onlyOwner {
        require(withdrawAddress != address(0), "No withdraw address set");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function flipSaleOpen() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function setSaleOpen(bool _saleOpen) external onlyOwner {
        saleOpen = _saleOpen;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
}