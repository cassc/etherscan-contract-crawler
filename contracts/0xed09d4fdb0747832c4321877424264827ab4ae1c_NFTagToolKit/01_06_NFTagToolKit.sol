// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NFTagToolKit is Initializable {  
    address public owner;
    mapping(address => bool) public approvedUsers;

    function initialize() public initializer {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "not approved");
        _;
    }

    modifier onlyOwnerAndApprovedUsers { 
        require(owner == msg.sender || approvedUsers[msg.sender], "not approved");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setApprovalForUser(address user, bool isApproved) external onlyOwner {
        approvedUsers[user] = isApproved;
    }

    function batchSendERC721 (
        IERC721 token,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwnerAndApprovedUsers {
        require(recipients.length == tokenIds.length, "length mismatch");

        for (uint256 i = 0; i < recipients.length;) {
            token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
            unchecked { i++; }
        }
    }

    function batchSendERC1155 (
        IERC1155 token,
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external onlyOwnerAndApprovedUsers {
        require(recipients.length == tokenIds.length && recipients.length == amounts.length && recipients.length == data.length, "length mismatch");

        for (uint256 i = 0; i < recipients.length;) {
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], amounts[i], data[i]);
            unchecked { i++; }
        }
    }  
}