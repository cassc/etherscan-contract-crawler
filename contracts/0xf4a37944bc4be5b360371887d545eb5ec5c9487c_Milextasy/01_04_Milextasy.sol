/*
        .__.__                   __
  _____ |__|  |   ____ ___  ____/  |______    _________.__.
 /     \|  |  | _/ __ \\  \/  /\   __\__  \  /  ___<   |  |
|  Y Y  \  |  |_\  ___/ >    <  |  |  / __ \_\___ \ \___  |
|__|_|  /__|____/\___  >__/\_ \ |__| (____  /____  >/ ____|
      \/             \/      \/           \/     \/ \/

* Twitter: https://twitter.com/milextasy

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Milextasy is Ownable, ERC20 {
    uint256 private _totalSupply = 69420000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Milextasy Token", "XLADY", 18, msg.sender) {
        _mint(msg.sender, _totalSupply);
    }

    function entropy() external pure returns (uint256) {
        return 6969691337;
    }
}