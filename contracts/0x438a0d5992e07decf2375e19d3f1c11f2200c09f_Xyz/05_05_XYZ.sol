// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Xyz is ERC20 {
    constructor() ERC20("Xyz", "XYZ") {
        _mint(msg.sender, 123456789 * 10 ** decimals());
    }
}