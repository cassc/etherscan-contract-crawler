// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Snapshot} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract NetworkToken is
    ERC20,
    ERC20Snapshot,
    Ownable,
    ERC20Permit,
    ERC20Votes
{
    uint256 private deadBlocks = 3;
    uint256 private launchBlock;
    bool private tradingOpen = false;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(_msgSender(), totalSupply_);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function openTrading() public onlyOwner {
        require(launchBlock == 0, "Already launched");
        launchBlock = block.number + deadBlocks;
        tradingOpen = true;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        if (!tradingOpen) {
            //allow the owner to transfer tokens before launch
            if (from != owner() && to != owner()) {
                require(block.number < launchBlock, "Trading closed");
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}