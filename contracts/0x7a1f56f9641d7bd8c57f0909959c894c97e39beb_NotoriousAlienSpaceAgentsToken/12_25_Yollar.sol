// SPDX-License-Identifier: MIT

/// @title The Notorious Alien Space Agents Utitilty Token

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YOLLAR is ERC20, ERC20Burnable, Ownable {
    uint128 public constant MAX_SUPPLY = 11_000_000_000 ether;
    address public gameTreasuaryAddress;

    constructor(address gameTreasuaryAddress_)
        ERC20("Notorious Alien Space Agent YOLLAR Token", "YOLLAR")
    {
        _mint(gameTreasuaryAddress_, MAX_SUPPLY);
        gameTreasuaryAddress = gameTreasuaryAddress_;
    }
}