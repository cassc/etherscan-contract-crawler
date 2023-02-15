// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
contract InfluentialPersons is ERC721A, ReentrancyGuard, Ownable {
    uint256 constant MAX_PER_TX = 2;
    uint256 constant MAX_SUPPLY = 330;
    uint256 private startTime;
    bool private _isPaused;
    string private _baseTokenURI;

    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC721A(_name, _symbol) {
    }
    
    function mint(uint256 quantity) external nonReentrant{
        require(_isPaused, "MINT NOT START.");
        require(msg.sender == tx.origin, "EOA ONLY.");
        require(quantity <= 2, "MAX PER TX ERROR.");
        require(_totalMinted() < MAX_SUPPLY, "MINT OVER.");
        if (_totalMinted() + quantity <= MAX_SUPPLY) {
            _mint(msg.sender, quantity);
        } else {
            _mint(msg.sender, 1);
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
}