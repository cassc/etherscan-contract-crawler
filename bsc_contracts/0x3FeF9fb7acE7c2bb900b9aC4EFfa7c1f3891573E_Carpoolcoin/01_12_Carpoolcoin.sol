// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AccessControl.sol";
import "Context.sol";
import "ERC20.sol";
import "ERC20Burnable.sol";
import "ERC20Pausable.sol";

contract Carpoolcoin is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    address admin;
    uint256 private value;

    constructor(uint256 initialSupply) ERC20("Carpoolcoin", "CARPOOL") {
        admin = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) public virtual {
        require(msg.sender == admin);
        _mint(msg.sender, amount);
    }

    function pause() public virtual {
        require(msg.sender == admin);
        _pause();
    }

    function unpause() public virtual {
        require(msg.sender == admin);
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

}