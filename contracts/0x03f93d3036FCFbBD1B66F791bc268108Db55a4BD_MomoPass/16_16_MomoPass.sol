// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {OperatorFilterer} from "../OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// Errors
error ArrayLengthMismatch();

/**
 * @title  MomoPass Contract
 */
contract MomoPass is
    ERC1155,
    ERC1155Burnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    bool public operatorFilteringEnabled;
    address public priorityOperatorAddress =
        0x1E0049783F008A0085193E00003D00cd54003c71;

    event DefaultRoyaltySet(address receiver, uint96 feeNumerator);
    event OperatorFilterSet(bool value);
    event BaseURISet(string uri);
    event PriorityOperatorSet(address operator);

    constructor()
        ERC1155(
            "https://momoguro-holoself.nyc3.cdn.digitaloceanspaces.com/momopass/"
        )
    {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(0xeA803944E87142d44b945b3f5a0639f442ba361B, 500);
    }

    function airdrop(
        address[] memory accounts,
        uint256[] memory amounts,
        uint256 tokenId
    ) external onlyOwner {
        if (accounts.length != amounts.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], tokenId, amounts[i], "");
        }
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _setURI(baseUri);
        emit BaseURISet(baseUri);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }

    function setPriorityOperator(address operator) external onlyOwner {
        priorityOperatorAddress = operator;
        emit PriorityOperatorSet(operator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC1155: 0xd9b67a26
        // - IERC1155MetadataURI: 0x0e89341c
        // - IERC2981: 0x2a55205a
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) external onlyOwner {
        operatorFilteringEnabled = value;
        emit OperatorFilterSet(value);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal view override returns (bool) {
        // Default OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(priorityOperatorAddress);
    }
}