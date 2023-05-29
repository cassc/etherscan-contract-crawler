// SPDX-License-Identifier: UNLICENSED
import "../openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../openzeppelin-contracts/contracts/access/AccessControl.sol";
pragma solidity 0.8.5;

/**
 * @title WombatToken
 * @dev An ERC20 token with fixed supply, minted to a given address at deployment time. Allows burning and pausing.
 */
contract WombatToken is ERC20Burnable, ERC20Pausable, AccessControl {

    /**
     * @dev The pauser can pause token transfers.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");

    /**
     * @dev Calls the {ERC20} constructor and mints the supply of tokens to the receiver. The receiver is also
     * configured as the {PAUSER_ROLE} and {DEFAULT_ADMIN_ROLE}.
     * @param name Name of the token (human readable)
     * @param symbol Ticker of the token
     * @param initialSupply Initial supply of the token in its smallest unit. Will be directly
     *  minted to `receiver`
     * @param receiver The address to mint the fixed supply to. Will also be set up to have the
     *  default admin role and pauser role.
     */
    constructor(
        string memory name, string memory symbol, uint256 initialSupply, address receiver
    ) ERC20(name, symbol) {
        _mint(receiver, initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, receiver);
        _setupRole(PAUSER_ROLE, receiver);
    }

    /**
     * @dev Needs to be overridden to select the correct base implementation to call (ERC20Pausable
     *  in this case)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Pause token transfers
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token transfers
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}