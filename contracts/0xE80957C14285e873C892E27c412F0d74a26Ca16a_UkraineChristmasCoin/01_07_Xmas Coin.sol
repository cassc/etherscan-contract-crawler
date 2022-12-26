// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract UkraineChristmasCoin is ERC20{
    constructor() ERC20 ('Ukraine Christmas Coin', 'UXC') {
        _mint(0xBf95194Ca4a633B929d1E534cFb7D94c64f5FC1a, 100000000000000000000000000);
    }
}