// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ZeroBirdge
// ZeroBridge is a first-of-its-kind hybrid zkRollup supporting both public and private smart contract execution.

// Telegram: https://t.me/zerobridgetele
// Website: https://zerobridge.space/
// Github: https://github.com/zerobridgeeth/smart-contracts

contract ZeroBridge is ERC20, Ownable {
    mapping(address => bool) public burners;

    constructor() ERC20("Zero Bridge", "ZBRIDGE") {
        burners[_msgSender()] = true;
        _mint(_msgSender(), 69_000_000 * 1e18);
    }

    function _afterTokenTransfer(
        address,
        address,
        uint256
    ) internal virtual override {
        // Do nothing
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal virtual override {
        // Do nothing
    }

    function burn(uint256 amount) public virtual {
        require(burners[msg.sender], "burners only");
        _burn(msg.sender, amount);
    }
}