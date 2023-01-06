// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";

abstract contract AbstractERC1155Factory is
    Pausable,
    ReentrancyGuard,
    ERC1155Supply,
    Ownable
{
    string name_;
    string symbol_;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
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
    }
}