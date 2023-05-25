// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract POV is ERC20 {
    constructor() ERC20("Pepes Original Vision", "POV") {
        uint256 supply = 690_000_000_000;
        _mint(msg.sender, supply * 10**18);
    }
}