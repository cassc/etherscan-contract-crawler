// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//community token since these virgins keep on timerugging
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract POOToken is ERC20, Ownable {
    constructor() ERC20("POO Token", "POO") {
        _mint(msg.sender, 8000000000000 * 10 ** decimals());
    }
}