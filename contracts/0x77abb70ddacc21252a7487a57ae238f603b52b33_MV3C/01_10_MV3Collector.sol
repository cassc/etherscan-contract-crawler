// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error FunctionNotSupported();

contract MV3C is ERC1155, Ownable {

    string private metadataURI;
    string public name = "MV3 Collector Pass (SBT)";
    uint256 public pricePerToken;
    address treasury = 0x22DA8dd235b1aca9A3c1980C8A11bC24712F67c1;
    
    constructor(string memory metadata) ERC1155("MV3C") {
        metadataURI = metadata; 
    }

    function setURI(string calldata metadata) external onlyOwner {
        metadataURI = metadata;
    }

    function mint(uint256 quantity) external payable {
        require(msg.value >= pricePerToken*quantity, "Not enough ETH sent: check price.");
        _mint(msg.sender, 1, quantity, "");
    }

    function burnSBT(uint256 quantity) external {
        _burn(msg.sender, 1, quantity);
    }

    function uri(uint256) public view override returns (string memory) {
        return metadataURI;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        pricePerToken = price;
    }

    function updateTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function withdraw() external onlyOwner {
        payable(treasury).transfer(address(this).balance);
    }

    //SBT code
    function setApprovalForAll(
        address,
        bool
    ) public pure override {
        revert FunctionNotSupported();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert FunctionNotSupported();
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert FunctionNotSupported();
    }
}