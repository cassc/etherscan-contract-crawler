// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract Moheji is
    Ownable,
    ERC20("Henohenomoheji", "MOHEJI"),
    ERC20Burnable,
    ERC20Pausable
{
    uint256 private constant _MAX_SUPPLY = 100_000_000_000 ether; // 1 Hundred billion

    constructor() {
        _mint(owner(), _MAX_SUPPLY);
    }

    function airdrop(address[] memory tos, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < tos.length; ) {
            transfer(tos[i], amount);
            unchecked {
                i++;
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function maxSupply() external pure returns (uint256) {
        return _MAX_SUPPLY;
    }

    // overrides
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }
}