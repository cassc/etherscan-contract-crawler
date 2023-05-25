// contracts/RealmToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RealmToken is ERC20Burnable, Pausable , AccessControlEnumerable {
    using SafeERC20 for IERC20;
    uint256 constant STARTING_SUPPLY = 10**9;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(address safeAddress) ERC20("REALM", "REALM") {
        _setupRole(PAUSER_ROLE, safeAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, safeAddress);
        _mint(
            msg.sender,
            STARTING_SUPPLY * (10**decimals())
        );
    }

    function pause() public{
         require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause the contract");
        _pause();
    }

    function unpause() public{
         require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to unpause the contract");
        _unpause();
    }
    
    /**
    * @dev See {ERC20-_beforeTokenTransfer}.
    *
    * Requirements:
    * - the contract must not be paused.
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}