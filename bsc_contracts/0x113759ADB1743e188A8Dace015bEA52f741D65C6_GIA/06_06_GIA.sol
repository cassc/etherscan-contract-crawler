// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GIA is ERC20, Ownable {

    constructor(address account) ERC20("GCOIN", "GIA") {
        _mint(account, 21_000_000_000  * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
}