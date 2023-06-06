/**

Name: SpaceBucks
Website: https://spaceballs.app/
Twitter: https://twitter.com/spaceballs_app

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract SpaceBalls is ERC20, Ownable {
    constructor() ERC20("SpaceBalls", "SpaceBalls") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}