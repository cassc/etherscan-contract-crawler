// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ChinggisKhaanDAO is ERC20 {

    constructor() ERC20("Chinggis Khaan DAO", "CGKDAO") {
        _mint(msg.sender, 21971126 * 1e18);
    }

}