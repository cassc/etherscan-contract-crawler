// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "hardhat/console.sol";

contract SoulPaintAP is ERC1155, Ownable, ERC1155Supply {
    constructor(string memory _usi) ERC1155(_usi) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        address sender = msg.sender;
        require(
            from == sender || isApprovedForAll(from, sender),
            "ERC1155: caller is not token owner or approved"
        );
        require(
            balanceOf(from, id) >= amount,
            "insufficient balance for transfer"
        );
        if (sender == owner()) {
            _safeTransferFrom(from, to, id, amount, data);
        } else {
            _safeTransferFrom(from, owner(), id, amount, data);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        address sender = msg.sender;
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner or approved"
        );
        if (sender == owner()) {
            _safeBatchTransferFrom(from, to, ids, amounts, data);
        } else {
            _safeBatchTransferFrom(from, owner(), ids, amounts, data);
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}