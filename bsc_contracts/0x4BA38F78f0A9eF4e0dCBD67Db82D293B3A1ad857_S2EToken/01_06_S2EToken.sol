// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./BEP20/BEP20Burnable.sol";

contract S2EToken is BEP20Burnable {
    constructor() BEP20("Spin2Earn Token", "S2E") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}