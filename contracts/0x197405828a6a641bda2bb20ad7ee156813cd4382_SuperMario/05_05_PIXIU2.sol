// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract SuperMario is ERC20 {
    uint256 private Pen = 0x0BA11A;
    constructor() ERC20("SuperMario", "SuperMario") {
        _mint(msg.sender, 8000000000000 * 10 ** decimals());
    }
}
