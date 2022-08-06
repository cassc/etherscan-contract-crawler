// SPDX-License-Identifier: UNLICENSED

// stay swol

// For Landon & Zane

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SwolDAO is ERC721A, Ownable, Pausable {
    uint256 public mintPrice = .01 ether;
    uint256 public maxSupply = 1000;
    uint256 public maxMint = 20;
    string public baseURI;

    constructor() ERC721A("swolDAO", "SWOL") {}

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 amount) external payable whenNotPaused {
        require(
            msg.value >= mintPrice * amount,
            "Not enough ETH for purchase."
        );
        require(amount <= maxMint, "exceeded max mint amount.");
        require(totalSupply() + amount <= maxSupply, "Not enough remaining.");
        _safeMint(msg.sender, amount);
    }

    function devMint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Not enough remaining.");
        _safeMint(to, amount);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function lowerMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(
            _newMaxSupply < maxSupply,
            "New supply must be less than current."
        );
        maxSupply = _newMaxSupply;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}