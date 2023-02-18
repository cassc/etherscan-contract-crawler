// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @custom:security-contact [email protected]
contract ZatMonkeySoulboundTokens is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("") {}

    mapping (uint256 => string) private _uris;

    // We can set a specific url for each item, making more flexible to update
    function setURI(string memory newuri, uint256 id) public onlyOwner {
        _uris[id] = newuri;
    }

    // Overriding the standard function
    function uri(uint256 id) public view override(ERC1155) returns (string memory) {
        return _uris[id];
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
        // Burning is allowed
        if(to != address(0x0) && from != address(0x0)){
           revert("Tokens are soulbound and can't be transferred");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}