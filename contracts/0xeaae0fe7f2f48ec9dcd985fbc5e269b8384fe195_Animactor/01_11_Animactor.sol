//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Animactor is ERC721A, Ownable {
    uint256 public MaxMint = 5;
    uint256 public maxSupply = 6969;
    uint256 public price = 0.01 * 10**18;
    string public baseURI =
        "ipfs://QmXnMeZrgpdBhVyWfb5qsaLUZ4QCy6hcc1GBkZPGNS3Nx1/";

    uint256 public startTime = 1652022000;

    constructor() ERC721A("Animactor", "ACER") {}

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function devMint(uint256 amount) external payable onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(block.timestamp >= startTime, "Sale is not active.");
        require(
            amount <= MaxMint,
            "Amount should not exceed max mint number"
        );
        require(
            totalSupply() + amount <= maxSupply,
            "Amount should not exceed max supply."
        );

        if (numberMinted(msg.sender) == 0)
            require(
                msg.value >= price * (amount - 1),
                "Ether value sent is incorrect."
            );
        else
            require(
                msg.value >= price * amount,
                "Ether value sent is incorrect."
            );

        _safeMint(msg.sender, amount);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}