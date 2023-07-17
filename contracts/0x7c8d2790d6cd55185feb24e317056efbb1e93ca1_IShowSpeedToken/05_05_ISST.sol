// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract IShowSpeedToken is ERC20 {
    constructor() ERC20("IShowSpeedToken", "ISST") {
        _mint(msg.sender, 123456789 * 10 ** decimals());
    }
}