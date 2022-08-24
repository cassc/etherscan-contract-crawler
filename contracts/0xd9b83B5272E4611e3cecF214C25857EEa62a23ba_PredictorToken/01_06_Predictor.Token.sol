// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract PredictorToken is ERC20, ERC20Burnable {
    constructor() ERC20("Predictor Token", "PRTK") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}