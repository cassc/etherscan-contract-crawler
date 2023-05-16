pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Locker.sol";

contract Token is ERC20, Ownable {
    Locker locker;

    constructor() ERC20("Mother I'd like to...", "MILF") {
        // Create locker contract
        locker = new Locker(this, owner(), block.timestamp + 24 hours);

        // Mint initial supply
        _mint(address(this), 696_696_696_696 * 10 ** decimals());

        // Transfer tokens to locker
        _transfer(address(this), address(locker), balanceOf(address(this)) / 100 * 20);

        // Transfer remaining tokens to deployer
        _transfer(address(this), owner(), balanceOf(address(this)));
    }
}