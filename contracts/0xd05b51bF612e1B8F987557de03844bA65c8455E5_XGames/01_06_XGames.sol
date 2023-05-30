///Website : https://x-games.io/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";

////XGames.sol

contract XGames is ERC20, Ownable{
    constructor(address _to) ERC20("XGames", "XG") {
        _mint(_to, 100000000 * 10 ** decimals());
    }

}