// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";

contract Frog is ERC20 {

    constructor() ERC20("Frog", "FROG") {

        _mint(msg.sender,420000000000000*10**18);

}

}
