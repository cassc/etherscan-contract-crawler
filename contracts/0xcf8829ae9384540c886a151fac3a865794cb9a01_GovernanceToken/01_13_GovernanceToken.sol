// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';


/**
 * @title Implementation of the GovernanceToken.
 *
 */
contract GovernanceToken is AccessControl, ERC20Pausable, ERC20Burnable {

    uint256 public constant INITIALSUPPLY = 2000000000 * (10 ** 18);

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    constructor(address adminAddress_)
            ERC20('SyncDAO Governance', 'SDG') {

        _mint(_msgSender(), INITIALSUPPLY);
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress_);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20, ERC20Pausable) {

        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}