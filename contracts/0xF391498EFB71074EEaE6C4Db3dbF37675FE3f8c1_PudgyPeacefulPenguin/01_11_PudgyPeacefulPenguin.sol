// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PudgyPeacefulPenguin is ERC721A, Ownable {
    uint256 public MaxPerTxn = 5;
    uint256 public MaxFreePerWallet = 5;
    bool public mintEnabled = false;
    uint256 public maxSupply = 5555;
    uint256 public price = 0.002 ether;
    string public baseURI =
        "ipfs://QmTqJ9ZzUt2gmM7zKfneds1EQPxFGUx8AzaKw4fwVtKvLj/";

    constructor() ERC721A("PudgyPeacefulPenguin", "PPP") {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(uint256 amount) external payable {
        require(mintEnabled, "Minting is not live yet, hold on");
        require(totalSupply() + amount <= maxSupply, "sold out");

        uint256 count = amount;
        if (numberMinted(msg.sender) < MaxFreePerWallet) {
            if (numberMinted(msg.sender) + amount <= MaxFreePerWallet)
                count = 0;
            else count = numberMinted(msg.sender) + amount - MaxFreePerWallet;
        }

        require(msg.value >= count * price, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function changePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        MaxFreePerWallet = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}