// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IcySpicy is ERC721A, Ownable {
    
    uint256 public constant MAX_SUPPLY = 1111;
    bool public saleIsActive = false;

    uint256 public price;
    uint256 public maxMintPerTx;

    string public baseUri;

    constructor() ERC721A("Icy Spicy", "IS") {
        price = 0.1 ether;
        maxMintPerTx = 5;
    }

    // Minting
    function mint(uint256 amount) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(amount <= maxMintPerTx, "Amount is too large");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply.");
        require(msg.value >= price * amount, "Sent Ether is too low");
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseUri = _newBaseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function whitelistMint(uint256 amount, address[] memory recipients) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Airdrop would exceed max supply.");
        uint256 amountPerAddress = amount / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], amountPerAddress);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}