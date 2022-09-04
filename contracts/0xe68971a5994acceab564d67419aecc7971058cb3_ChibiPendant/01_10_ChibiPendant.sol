// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChibiPendant is ERC1155, Ownable {
    constructor(string memory uri_) ERC1155(uri_) {}

    function mintBatch(address[] calldata recipients, uint256 id, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], id, amount, "");
        }
    }

    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }
}