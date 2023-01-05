pragma solidity ^0.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
/**
 * @title Skew's SToken Contract
 * @notice Abstract base for STokens
 * @author Ren
 */
contract SToken is ERC20Burnable, AccessControl{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    function mint(address to, uint256 amount) external{
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller not a minter");
        _mint(to,amount);
    }
}