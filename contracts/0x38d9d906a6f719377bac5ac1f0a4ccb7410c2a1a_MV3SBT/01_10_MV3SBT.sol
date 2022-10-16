// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error FunctionNotSupported();

contract MV3SBT is ERC1155, Ownable {

    string private metadataURI;
    string public name = "MV3 OG Access Pass (SBT)";
    
    constructor(string memory metadata) ERC1155("MV3SBT") {
        metadataURI = metadata; 
    }

    function setURI(string calldata metadata) external onlyOwner {
        metadataURI = metadata;
    }

    function airdropSBT(address [] calldata addresses) external onlyOwner {
        for(uint i = 0; i < addresses.length; i++){
            _mint(addresses[i], 1, 1, "");
        }
    }

    function burnSBT() external {
        _burn(msg.sender, 1, 1);
    }

    function uri(uint256) public view override returns (string memory) {
        return metadataURI;
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