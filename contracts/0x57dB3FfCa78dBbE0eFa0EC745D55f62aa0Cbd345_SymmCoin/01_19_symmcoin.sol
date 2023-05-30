// contracts/CentToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract SymmCoin is ERC20Snapshot, ERC20Burnable, AccessControl, Ownable, ERC20Permit {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
  
    constructor(string memory name_, string memory symbol_, address minting_account, address snapshot_account) public ERC20(name_, symbol_) ERC20Permit(name_) {

        // Setup an admin for all roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant MINTER_ROLE role to a specified account
        _setupRole(MINTER_ROLE, minting_account);

        // Grant SNAPSHOT_ROLE role to a specified account
        _setupRole(SNAPSHOT_ROLE, snapshot_account);
    }

    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        _mint(account, amount); 
    }

    function snapshot() public {
        require(hasRole(SNAPSHOT_ROLE, msg.sender));
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Snapshot, ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }
}