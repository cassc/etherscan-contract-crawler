// SPDX-License-Identifier: MIT
// Creator: @jessefriedland

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total and max supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified.
 */
abstract contract ERC1155MaxSupply is ERC1155 {
    struct Supply {
        uint80 totalSupply;
        uint80 maxSupply;
        uint80 numberBurned;
        bool retired;
    }

    string public _name;
    string public _symbol;
    mapping(uint256 => Supply) private _supplyInfo;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require(totalMinted(id) + amount <= maxSupply(id), "Max supply reached");
        super._mint(to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(totalMinted(ids[i]) + amounts[i] <= maxSupply(ids[i]), "Max supply reached");
        }
        super._mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _supplyInfo[id].totalSupply;
    }

    /**
     * @dev Total amount of tokens minted for a given id.
     */
    function totalMinted(uint256 id) public view virtual returns (uint256) {
        return _supplyInfo[id].totalSupply + _supplyInfo[id].numberBurned;
    }

    /**
     * @dev Max supply for a given id.
     */
    function maxSupply(uint256 id) public view virtual returns (uint256) {
        return uint256(_supplyInfo[id].maxSupply);
    }

    /**
     * @dev Is a given id retired?
     */
    function retired(uint256 id) public view virtual returns (bool) {
        return _supplyInfo[id].retired;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155MaxSupply.totalSupply(id) > 0;
    }

    function _setMaxSupply(
        uint256 id,
        uint256 supply,
        bool _retired
    ) internal virtual {
        require(!exists(id) || !_supplyInfo[id].retired, "ERC1155: Cannot adjust the max supply");
        require(supply > _supplyInfo[id].maxSupply, "ERC1155: Cannot lower the max supply");
        _supplyInfo[id].maxSupply = uint80(supply);
        _supplyInfo[id].retired = _retired;
    }

    function _retire(uint256 id) internal virtual {
        require(_supplyInfo[id].maxSupply > 0 && !_supplyInfo[id].retired, "ERC1155: Cannot retire");
        _supplyInfo[id].retired = true;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
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
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _supplyInfo[ids[i]].totalSupply += uint80(amounts[i]);
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _supplyInfo[id].totalSupply;
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _supplyInfo[id].totalSupply = uint80(supply - amount);
                    _supplyInfo[id].numberBurned += uint80(amount);
                }
            }
        }
    }
}