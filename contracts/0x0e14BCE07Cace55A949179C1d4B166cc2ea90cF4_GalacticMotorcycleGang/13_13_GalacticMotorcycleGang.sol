// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GalacticMotorcycleGang is ERC1155, Ownable, Pausable {
    /// @notice Collection name
    string public constant name = "Galactic Motorcycle Gang";
    /// @notice Collection symbol
    string public constant symbol = "GMG";

    constructor(string memory uri_) ERC1155(uri_) {
        // pause contract until entirely distributed
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function allocate(address[] calldata recipients, uint256[] calldata balances, uint256 id) external onlyOwner {
        require(recipients.length == balances.length, "recipients/balances length mismatch");
        for (uint256 it; it < recipients.length; it++) {
            uint256 currentBalance = balanceOf(recipients[it], id);
            if (currentBalance > balances[it]) {
                _burn(recipients[it], id, currentBalance - balances[it]);
            } else if (currentBalance < balances[it]) {
                _mint(recipients[it], id, balances[it] - currentBalance, "");
            }
        }
    }

    /**
     * @notice Returns the URI for a given token ID
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        return string.concat(super.uri(id), Strings.toString(id), ".json");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from != address(0) && to != address(0)) {
            // this is a regular transfer
            require(!paused(), "Cannot transfer GMG tokens yet");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}