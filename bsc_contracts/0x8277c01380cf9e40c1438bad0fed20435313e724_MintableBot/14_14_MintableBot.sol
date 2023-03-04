// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MintableBot is Ownable, ERC721Enumerable {
    uint256 public immutable mintPrice = 10 ** 16;
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    /**
     * @dev Mint NFTs for mintPrice of native token (ETH|MATIC|BNB)
     *
     * @param amount  amount of tokens to mint
     */
    function mint(uint256 amount) public payable {
        require(msg.value == amount * mintPrice, "Wrong amount");
        uint id = totalSupply();
        uint goalSupply = id + amount;
        for (; id < goalSupply; ) {
            _safeMint(msg.sender, id++);
        }
    }

    /**
     * @dev Changes NFTs metadata uri
     *
     * @param uri  new contract baseURI
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Withdraw native token
     */
    function withdraw() external onlyOwner {
        bool success;
        address to = msg.sender;
        uint256 amount = address(this).balance;
        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "Withdraw failed");
    }
}