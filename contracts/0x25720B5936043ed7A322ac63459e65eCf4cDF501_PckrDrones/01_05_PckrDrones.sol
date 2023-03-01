// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PckrDrones is ERC721A, Ownable {
    uint256 public maxSupply;
    string public baseURI;

    mapping(address => bool) public controllers;

    constructor(
        uint256 _maxSupply
    ) ERC721A("PCKR DRONES", "PCKR-DRNS") {
        maxSupply = _maxSupply;
    }

    function getBlock() external view returns (uint256) {
        return block.timestamp;
    }

    function setSettings(
        uint256 _maxSupply
    ) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function airdrop(address receiver, uint256 amount) external onlyController
    {
        require(maxSupply >= amount + _totalMinted(), "Supply limit");
        _mint(receiver, amount);
    }

    function minted() external view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Wrong caller");
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}