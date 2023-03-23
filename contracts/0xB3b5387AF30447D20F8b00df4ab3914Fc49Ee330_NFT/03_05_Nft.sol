// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 2200;
    uint256 public constant MAX_PER_WALLET = 2;
    uint256 public startTime;
    uint256 public mint_price = 0.005 ether;
    string public _baseTokenURI;

    constructor(
        uint256 _startTime,
        string memory baseURI
    ) ERC721A("Spectrum", "SP") {
        startTime = _startTime;
        _baseTokenURI = baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Quantity cannot be zero");
        require(block.timestamp >= startTime, "Sale not started");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max supply hit");
        require(
            _numberMinted(msg.sender) + quantity <= MAX_PER_WALLET,
            "Max count per wallet hit"
        );
        require(msg.value == quantity * mint_price, "Insufficient funds");

        _mint(msg.sender, quantity);
    }

    function ownerAirdrop() public onlyOwner {
        require(_totalMinted() <= MAX_SUPPLY, "Max supply hit");
        _mint(msg.sender, 1);
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setMintPrice(uint256 _mint_price) public onlyOwner {
        mint_price = _mint_price;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }
}