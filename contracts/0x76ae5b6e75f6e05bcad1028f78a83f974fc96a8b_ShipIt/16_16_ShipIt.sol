// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract ShipIt is Ownable {

    mapping(address => address) public addressVault; // users can store their personal vaults for ease of use
    uint256 public usageFee = .00015 ether;          // charge a small fee for the cost savings it provides

    /*************************
    Modifiers
    **************************/

    modifier onlyIfPaid(
        address[] calldata recipients,
        uint256[] calldata tokenIndexes
    ) {
        require(tokenIndexes.length == recipients.length, "Array lengths must match.");
        require(msg.value >= tokenIndexes.length * usageFee, "Invalid usage fee sent.");
        _;
    }

    /*************************
    Admin
    **************************/

    function updateFee(uint256 amount) external onlyOwner {
        usageFee = amount;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*************************
    User
    **************************/

    function updateVault(address vaultAddress) external {
        addressVault[msg.sender] = vaultAddress;
    }

    // Expects flat list of recipients and token IDs
    function erc721BulkTransfer(
        address contractAddress,
        address[] calldata recipients,
        uint256[] calldata tokenIndexes
    ) external payable onlyIfPaid(recipients, tokenIndexes) {
        require(ERC721(contractAddress).isApprovedForAll(msg.sender, address(this)), "Contract not approved to send tokens on Sender behalf.");
        for(uint256 i; i < tokenIndexes.length; i++) {
            require(msg.sender == ERC721(contractAddress).ownerOf(tokenIndexes[i]), "Sender is not the token owner, cannot proceed with transfer.");
            ERC721(contractAddress).safeTransferFrom(msg.sender, recipients[i], tokenIndexes[i]);
        }
    }

    // Expects a tally of ERC-1155 token amounts batched beforehand for simple sending
    function erc1155BulkTransfer(
        address contractAddress,
        address[] calldata recipients,
        uint256[] calldata tokenIndexes,
        uint256[] calldata amounts
    ) external payable onlyIfPaid(recipients, tokenIndexes) {
        require(amounts.length == recipients.length, "Array lengths must match.");
        require(ERC1155(contractAddress).isApprovedForAll(msg.sender, address(this)), "Contract not approved to send tokens on Sender behalf.");
        for(uint256 i; i < tokenIndexes.length; i++) {
            require(ERC1155(contractAddress).balanceOf(msg.sender, tokenIndexes[i]) >= amounts[i], "Not enough balance owned of the given token ID.");
            ERC1155(contractAddress).safeTransferFrom(msg.sender, recipients[i], tokenIndexes[i], amounts[i], bytes(""));
        }
    }

}