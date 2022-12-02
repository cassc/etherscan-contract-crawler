// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FloruitPass is ERC1155Supply, Ownable, Pausable {

    uint256 public constant MAX_SUPPLY = 500;
    uint256 public constant FLORUIT_PASS = 0;
    string public name;
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function mint(uint256 _mintAmount) external onlyOwner {
        require(totalSupply(FLORUIT_PASS) + _mintAmount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(_msgSender(), FLORUIT_PASS, _mintAmount, "");
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
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

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}