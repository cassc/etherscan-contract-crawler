//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LIXILPOANFT is ERC1155, ERC1155Supply, Ownable {
    // Variables
    uint256 constant TOKEN_ID = 1;

    // Project
    string public name;
    string public symbol;
    string public tokenUri;


    constructor(
        string memory name_,
        string memory symbol_
    ) 
        ERC1155("")
    {
        //Project
        name = name_;
        symbol = symbol_;
    }

    // AIRDROP
    function airdropProofOfAttendance(address to_, uint256 amount_) isAirdropAvailable public onlyOwner { 
        _mint(to_, TOKEN_ID, amount_, "");
    }
    function airdropProofOfAttendances(address[] memory tos_, uint256[] memory amounts_) isAirdropAvailable external onlyOwner { 
        require(tos_.length == amounts_.length, "Length mismatch!");
        for (uint256 i = 0; i < tos_.length; i++) {
            _mint(tos_[i], TOKEN_ID, amounts_[i], "");
        }
    }

    // OWNER
    function setTokenUri(string calldata newUri_) external onlyOwner {
        tokenUri = newUri_;
    }
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // AIRDROP WINDOW
    bool public airdropFinished;
    modifier isAirdropAvailable { require(airdropFinished == false, "Airdrop finished"); _; }
    function setAirdropFinished(bool finished_) external onlyOwner {
        airdropFinished = finished_;
    }

    // OVERRIDE
    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}