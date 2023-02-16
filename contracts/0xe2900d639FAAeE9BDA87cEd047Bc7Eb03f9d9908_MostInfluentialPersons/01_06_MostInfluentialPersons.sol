// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
contract MostInfluentialPersons is ERC721A, ReentrancyGuard, Ownable {
    uint256 constant MAX_PER_TX = 4;
    uint256 constant PER_PRICE = 0.15 ether;
    uint256 constant MAX_SUPPLY = 330;
    uint256 private startTime;
    bool private _isPaused;
    string private _baseTokenURI;

    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC721A(_name, _symbol) {}
    
    function mint(uint256 quantity) external payable nonReentrant{
        require(_isPaused, "MINT NOT START.");
        require(msg.value == quantity * PER_PRICE, "ERROR MINT FEE.");
        require(msg.sender == tx.origin, "EOA ONLY.");
        require(quantity <= MAX_PER_TX, "MAX PER TX ERROR.");
        require(_totalMinted() < MAX_SUPPLY, "MINT OVER.");
        if (_totalMinted() + quantity <= MAX_SUPPLY) {
            _mint(msg.sender, quantity);
        } else {
            uint256 amount = MAX_SUPPLY - _totalMinted();
            _mint(msg.sender, amount);
            payable(msg.sender).transfer(msg.value - (quantity - amount) * PER_PRICE);

        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPaused() external onlyOwner {
        _isPaused = !_isPaused;
    }

    function withdraw(address to) external onlyOwner {
        require(to != address(0), "ZERO ADDRESS");
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);

    }
}