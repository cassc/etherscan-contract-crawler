pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract EGGS is Context, AccessControlEnumerable, ERC20, ERC20Burnable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor () ERC20("Chicken DAO", "EGGS") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role.");
        _mint(to, amount);
    }
}