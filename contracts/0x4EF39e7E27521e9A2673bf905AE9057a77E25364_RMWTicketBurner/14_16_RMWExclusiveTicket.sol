// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RMWExclusiveTicket is ERC1155, ERC1155Burnable, Ownable {
    uint256 public nonTradableTokenId = 0;

    constructor(string memory _uri) ERC1155(_uri) {}

    function burn(address addr, uint256 amount) public onlyOwner {
        _burn(addr, nonTradableTokenId, amount);
    }

    function mintForAirdrop(address[] memory addresses, uint256 quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], nonTradableTokenId, quantity, "");
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != address(0) && to != address(0)) {
            revert("Not tradable or transferable");
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        super.setApprovalForAll(operator, approved);
        revert("Not tradable or transferable");
    }
}