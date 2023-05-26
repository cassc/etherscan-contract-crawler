// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract SHEIN is ERC20 {
    uint256 private Pen = 0x0BA11A;
    constructor() ERC20("SHEIN", "SHEIN") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }
}
