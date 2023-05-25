// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract AntfarmGovernanceToken is ERC20 {
    constructor() ERC20("Antfarm Governance Token", "AGT", 18) {
        _mint(msg.sender, 10_000_000 ether);
    }
}