pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PSYOPToken is ERC20, ERC20Burnable, AccessControl {
    constructor() ERC20("PSYOP Token", "PSYOP") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}