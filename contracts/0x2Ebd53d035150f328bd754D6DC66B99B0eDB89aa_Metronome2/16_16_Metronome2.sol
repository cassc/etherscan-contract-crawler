// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metronome2 is ERC20Votes, Ownable {
    constructor() ERC20Permit("Metronome2") ERC20("Metronome2", "MET") {}

    /**
     * See {ERC20 _mint}.
     */
    function mint(address account_, uint256 _amount) external onlyOwner {
        _mint(account_, _amount);
    }
}