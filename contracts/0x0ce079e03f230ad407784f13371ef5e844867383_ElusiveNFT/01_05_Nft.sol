// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElusiveNFT is ERC721A, Ownable {
    uint256 public MAX_PER_WALLET = 5;
    uint256 public MAX_SUPPLY = 8888;
    uint256 public PRICE = 0.0069 ether;
    uint256 public FREEAMOUNT = 1;
    uint256 public startTime;
    string public _baseTokenURI;

    bool public isEnable = true;

    constructor(
        uint256 _startTime,
        string memory baseURI
    ) ERC721A("Pixel Platipy", "PL") {
        startTime = _startTime;
        _baseTokenURI = baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(quantity > 0);
        require(isEnable);
        require(block.timestamp >= startTime);
        require(_totalMinted() + quantity <= MAX_SUPPLY);

        uint256 numberMinted = _numberMinted(msg.sender);

        require(numberMinted + quantity <= MAX_PER_WALLET);

        if (numberMinted > 0) {
            require(msg.value == quantity * PRICE);
        } else {
            require(msg.value == (quantity - FREEAMOUNT) * PRICE);
        }

        _mint(msg.sender, quantity);
    }

    function airdropToOwner() public onlyOwner {
        require(_totalMinted() <= MAX_SUPPLY);
        _mint(msg.sender, 1);
    }

    function setEnable(bool isCurrentEnable) public onlyOwner {
        isEnable = isCurrentEnable;
    }
  
    function setFreeAmount(uint256 freeAmount) public onlyOwner {
        FREEAMOUNT = freeAmount;
    }

    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        MAX_SUPPLY = maxSupply;
    }

    function setMintPrice(uint256 mintPrice) public onlyOwner {
        PRICE = mintPrice;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }
}