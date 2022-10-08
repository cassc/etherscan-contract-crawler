// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Multitest is ERC721A, Ownable {

    uint256 public MAX_PER_WALLET = 2;
    uint256 public MAX_PER_TX = 1;
    uint256 public mintRate = 0 ether;

    constructor() ERC721A("Multitest", "MT") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity) external payable  {
        require(quantity <= MAX_PER_TX, "Exceeded the limit tx");
        require(quantity + _numberMinted(msg.sender) <= MAX_PER_WALLET, "Exceeded the limit");
        require(msg.value >= mintRate * quantity, "Insufficient funds!");
        _safeMint(msg.sender, quantity);
    }

    function mintAT(uint256 quantity) external payable  {
        require(quantity + balanceOf(msg.sender) <= MAX_PER_WALLET, "Exceeded the limit");
        require(msg.value >= mintRate * quantity, "Insufficient funds!");
        _safeMint(msg.sender, quantity);
    }

    function mintCD(uint256 quantity, address _to) external payable  {
        require(quantity + _numberMinted(msg.sender) <= MAX_PER_WALLET, "Exceeded the limit");
        require(quantity + _numberMinted(_to) <= MAX_PER_WALLET, "Exceeded the limit");
        require(msg.value >= mintRate * quantity, "Insufficient funds!");
        _safeMint(_to, quantity);
    }

    function ownerMint(address addr, uint quantity) external onlyOwner {
        _safeMint(addr, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setMaxPerWallet(uint256 _MAX_MINTS) public onlyOwner {
        MAX_PER_WALLET = _MAX_MINTS;
    }

    function setMaxPerTx(uint256 _MAX_MINTS) public onlyOwner {
        MAX_PER_TX = _MAX_MINTS;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }
}