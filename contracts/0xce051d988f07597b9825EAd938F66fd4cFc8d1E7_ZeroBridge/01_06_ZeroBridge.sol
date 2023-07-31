// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ZeroBirdge
// ZeroBridge is a first-of-its-kind hybrid zkRollup supporting both public and private smart contract execution.

// Telegram: https://t.me/zerobridgeeth
// Website: https://zerobridge.space/
// Github: https://github.com/zerobridgeeth/smart-contracts

contract ZeroBridge is ERC20, Ownable {
    mapping(address => bool) public burners;

    constructor(address _marketing) ERC20("ZeroNomad", "0xBridge") {
        burners[msg.sender] = true;
        burners[_marketing] = true;

        _mint(msg.sender, 1_000_000 * 1e18);
        _transfer(msg.sender, _marketing, 30_000 * 1e18);
    }

    function burn(uint256 amount) public virtual {
        require(burners[msg.sender], "burners only");
        _burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Do nothing
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Do nothing
    }
}