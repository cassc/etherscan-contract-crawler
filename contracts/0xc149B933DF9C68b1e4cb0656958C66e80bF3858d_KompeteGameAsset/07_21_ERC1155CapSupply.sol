// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @dev Extension of ERC1155 that adds a max total supply per id.
 */
abstract contract ERC1155CapSupply is ERC1155Supply {
    mapping(uint256 => uint256) private _maxSupply;
    mapping(uint256 => bool) private _frozenSupply;

    /**
     * @dev Set the max supply for a tokenId
     * remark: a max amount of 0 is equal to unlimited supply
     */
    function _setMaxSupply(
        uint256 id,
        uint256 max,
        bool freeze
    ) internal {
        require(!_frozenSupply[id], "ERC1155CapSupply: supply frozen");
        require(max == 0 || max >= totalSupply(id), "ERC1155CapSupply: invalid max supply");
        if (freeze) _frozenSupply[id] = true;
        _maxSupply[id] = max;
    }

    /**
     * @dev Max amount of tokens with a given id.
     * remark: a max amount of 0 is equal to unlimited supply
     */
    function maxSupply(uint256 id) public view virtual returns (uint256) {
        return _maxSupply[id];
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(
                    _maxSupply[ids[i]] == 0 || totalSupply(ids[i]) + amounts[i] <= _maxSupply[ids[i]],
                    "ERC1155CapSupply: Above max supply"
                );
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}