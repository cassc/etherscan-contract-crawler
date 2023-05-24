// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RaiseToken is ERC20, ERC20Burnable {
    uint256 private immutable _cap = 1_000_000_000 * 10**18;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, _cap);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }
}