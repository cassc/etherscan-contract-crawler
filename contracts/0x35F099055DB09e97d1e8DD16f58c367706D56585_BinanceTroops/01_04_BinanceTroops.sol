//
// BinanceTroops token
// Website: binancetroops.io Twitter: https://twitter.com/BNBTroop

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@thirdweb-dev/contracts/token/ERC20.sol";

contract BinanceTroops is Ownable, ERC20 {
    uint256 private _totalSupply = 100000000 * (10 ** 18);

    constructor() ERC20("BinanceTroops", "BNBTP", 18, msg.sender) {
        _mint(msg.sender, _totalSupply);
    }
}