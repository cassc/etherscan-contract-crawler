// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PEPEGAME is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("PEPEGAME", "PEPEGAME") {
        _mint(msg.sender, 200_000_000_000_000 * 10 ** 18); // 200 trillion tokens, 18 decimal places
    }

    function burn(uint256 amount) public override onlyOwner {
        super.burn(amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}