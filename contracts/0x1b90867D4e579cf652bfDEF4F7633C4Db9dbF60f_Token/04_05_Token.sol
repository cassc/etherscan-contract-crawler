// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    bool private active;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_, 18) {
        _mint(msg.sender, 1_000_000e18);
        active = false;
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {
        if (sender_ != owner()) {
            require(active);
        }

        super._transfer(sender_, recipient_, amount_);
    }
}