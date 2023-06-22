// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract vHIGH is ERC20 {

    constructor(address minter) ERC20("voucher HIGH", "vHIGH"){
        uint256 amount = 300000 * 1e18; //decimals 18
        _mint(minter, amount);
    }

}