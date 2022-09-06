// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Dots is Ownable, ERC721A, ERC721AQueryable {
    // ----------------- MODIFIERS -----------------
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ----------------- VARAIBLES -----------------
    uint256 public immutable mintStartTime;
    uint256 public constant maxBatchNumber = 10;
    uint256 public constant maxMintNumber = 1000;
    uint256 public constant maxDevMintNumber = 200;
    uint256 public publicPrice = 0 ether;

    mapping(address => bool) public whitelistClaimed;

    mapping(address => uint256) public freeMints;

    constructor(uint256 _mintStartTime) ERC721A("dots", "DOTS") {
        mintStartTime = _mintStartTime;
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(
            block.timestamp >= mintStartTime,
            "dots: Mint is not started"
        );
        require(
            quantity + totalSupply() <= maxMintNumber,
            "dots: Maximum mint quantity reached"
        );
        require(
            msg.value == publicPrice * quantity,
            "dots: Wrong ETH amount"
        );
        require(
            quantity <= maxBatchNumber,
            "dots: Per TX limit exceeded"
        );
        _mint(msg.sender, quantity);
    }

    function setNewPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function devMint() external onlyOwner {
        _mint(msg.sender, maxDevMintNumber);
    }
}