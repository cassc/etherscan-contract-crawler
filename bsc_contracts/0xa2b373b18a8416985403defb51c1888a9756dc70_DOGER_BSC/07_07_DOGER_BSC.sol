pragma solidity ^0.5.17;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract DOGER_BSC is Context, ERC20, ERC20Detailed {

    constructor () public ERC20Detailed("DogeRift", "DOGER", 8) {
        _mint(_msgSender(), 10000000000000000000000); // Same initial supply as on NEO N3
    }
}