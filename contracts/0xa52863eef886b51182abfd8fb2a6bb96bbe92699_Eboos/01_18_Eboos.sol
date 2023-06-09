// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "erc721a/contracts/ERC721A.sol";

import "./Boo.sol";

contract Eboos is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;

    string public provenance;
    uint256 public startIndex;
    
    uint256 public immutable collectionSize;
    uint256 public immutable reserveSize;
    uint256 public reserved = 0;

    uint256 public immutable premintStartTime;
    uint256 public premintEndTime = 0;

    uint256 startPrice = 0.001 ether;
    uint256 public constant maxPremintQuantity = 8;
    uint256 public constant maxMintQuantity = 5;

    // TODO remettre les bons addresses
    address public constant devAddress       = 0xb499bbD20c9EE5bfB3a7cdd30c55f8C8bF774e8f;
    address public constant designer1Address = 0x9F07938D05fe5E942Cab73E58e3162eB3530Bb8B;
    address public constant designer2Address = 0x6db8BD745acebD5d4B861AF4C549585af95b8560;
    address public constant designer3Address = 0xd74787F4D24C0Dd8A88Cf7D19e5fd1fB093b0074;
    address public constant designer4Address = 0x4A0Df69dB95751cA6F879EB9da2635F33E93a50d;

    bool public paused = false;

    Boo boo;

    constructor(uint256 _collectionSize, uint256 _reserveSize, uint256 _premintStartTime, address _boo) ERC721A("Eboos", "EBOO") {
        collectionSize      = _collectionSize;
        premintStartTime    = _premintStartTime;
        reserveSize         = _reserveSize;
        boo = Boo(_boo);
    }

    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function getPrice() public view returns (uint256) {     
        uint256 time = getTime();

        if (premintStartTime >= time) {
            return startPrice;
        }

        if (premintEndTime == 0) {
            return (1 + (time - premintStartTime) / 86400) * startPrice;
        }

        return (1 + (premintEndTime - premintStartTime) / 86400) * startPrice;
    }

    function premint(uint256 quantity) external payable {
        uint256 boos = gasleft() * tx.gasprice * 10 ** 9;
        uint256 price = getPrice();
        uint256 time = getTime();
        uint256 ts = totalSupply() + quantity - reserved;
        uint256 totalPrice = price * quantity;
        
        require(!paused,                                            "premint paused");
        require(premintStartTime <= time,                           "premint has not begun yet");
        require(premintEndTime == 0,                                "premint is already over");
        require(quantity <= maxPremintQuantity,                     "quantity exceeds premint limit");
        require(ts <= collectionSize - reserveSize,                 "quantity exceeds collection size");
        require(ts <= (1 + (time - premintStartTime) / 86400) * 16, "quantity exceeds availability");
        require(msg.value >= totalPrice,                            "need to send more ETH");

        _safeMint(msg.sender, quantity);

        boo.mint(msg.sender, boos);
        
        refundIfOver(totalPrice);
    }

    function mint(uint256 quantity) external payable {
        uint256 boos = gasleft() * tx.gasprice * 10 ** 9;
        uint256 price = getPrice();
        uint256 totalPrice = price * quantity;

        require(!paused,                                                                "mint paused");
        require(premintEndTime != 0,                                                    "premint has not ended yet");
        require(quantity <= maxMintQuantity,                                            "quantity exceeds mint limit");
        require(totalSupply() + quantity - reserved <= collectionSize - reserveSize,    "quantity exceeds collection size");
        require(msg.value >= totalPrice,                                                "need to send more ETH");

        _safeMint(msg.sender, quantity);

        boo.mint(msg.sender, boos);

        refundIfOver(totalPrice);
    }

    function reserve(address to, uint256 quantity) external onlyOwner {
        uint256 boos = gasleft() * tx.gasprice * 10 ** 9;
        require(quantity <= reserveSize - reserved, "reserve is empty");
        
        reserved += quantity;

        _safeMint(to, quantity);

        boo.mint(to, boos);
    }

    function stopPremint() external onlyOwner {
        uint256 time = getTime();

        require(premintStartTime < time,    "premint has not begun yet");
        require(premintEndTime == 0,        "premint is already over");

        premintEndTime = time;
    }

    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

      // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "There's nothing to withdraw");

        _widthdraw(msg.sender,      balance.mul(82).div(100));

        // pay contributors
        _widthdraw(devAddress,       balance.mul(8).div(100));
        _widthdraw(designer1Address, balance.mul(4).div(100));
        _widthdraw(designer2Address, balance.mul(4).div(100));
        _widthdraw(designer3Address, balance.mul(1).div(100));
        _widthdraw(designer4Address, balance.mul(1).div(100));
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setProvenance(string calldata _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function setStartIndex(uint256 _startIndex) public onlyOwner {
        startIndex = _startIndex;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }
}