// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC1155/ERC1155.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155Supply.sol";

contract NFKingsxBryteHall is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    string public contractURI;

    constructor() ERC1155("https://api.brytehall.com/api/v1/contract3/token/{id}") {
        contractURI = "https://api.brytehall.com/api/v1/contract/3";
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractURI = newuri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}