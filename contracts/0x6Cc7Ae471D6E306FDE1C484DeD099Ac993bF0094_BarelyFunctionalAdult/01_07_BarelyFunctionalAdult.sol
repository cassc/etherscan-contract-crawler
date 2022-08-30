// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BarelyFunctionalAdult is Ownable, ERC721A, ReentrancyGuard {
    bool public mintEnabled = false;
    uint256 public MAX_SUPPLY = 3333;
    uint256 public price = 0.01 ether;
    uint256 public MaxPerTxn = 15;
    string public baseURI =
        "ipfs://QmfEzNVETLFe1QZnNaRgd9iMBrv9LxaZMeaXZCxNEGxuC7/";

    constructor() ERC721A("BarelyFunctionalAdult", "BFA") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        MAX_SUPPLY = amount;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(mintEnabled, "wait until sale start");
        require(quantity <= MaxPerTxn, "can't mint this many");
        require(totalSupply() + quantity <= MAX_SUPPLY_, "max supply reached");

        require(msg.value >= quantity * price, "Please send the exact amount");

        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function startSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function devMint(uint256 amount) external payable onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY_, "max supply reached!");
        _safeMint(msg.sender, amount);
    }

    function changePrice(uint256 __price) public onlyOwner {
        price = __price;
    }
}