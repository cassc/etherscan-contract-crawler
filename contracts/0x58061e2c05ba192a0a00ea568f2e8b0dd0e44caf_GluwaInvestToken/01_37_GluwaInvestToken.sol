// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol';

import './abstracts/Blacklistable.sol';
import './abstracts/Mintable.sol';
import './abstracts/Voteable.sol';
import './abstracts/EthlessBurn.sol';
import './abstracts/EthlessReservable.sol';
import './abstracts/EthlessTransfer.sol';

contract GluwaInvestToken is ERC20PausableUpgradeable, Blacklistable, Mintable, Voteable, EthlessBurn, EthlessReservable, EthlessTransfer {
    /**
     * @dev Initialize contract with the account holding governance role, the name of the token and the symbol.
     *
     */
    function initialize(
        address governance,
        string memory name_,
        string memory symbol_
    ) external initializer {
        __Controllable_init(governance);
        __Voteable_init(name_, symbol_);
    }

    function version() public pure virtual returns (string memory) {
        return '0.2';
    }

    /**
     * @dev Override the decimals function to return the correct decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Pause transfers of the token, only the Governance role can call this function
     */
    function pause() external virtual whenNotPaused onlyGovernance {
        _pause();
    }

    /**
     * @dev Unpause transfers of the token, only the Governance role can call this function
     */
    function unpause() external virtual whenPaused onlyGovernance {
        _unpause();
    }

    /**
     * @dev allow to get version for EIP712 domain dynamically. We do not need to init EIP712 anymore
     *
     */
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(version()));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712NameHash() internal view override returns (bytes32) {
        return keccak256(bytes(name()));
    }

    /**
     * @dev Returns the amount of tokens owned by `account` deducted by the reserved amount.
     */
    function balanceOf(address account) public view virtual override(ERC20Upgradeable, EthlessReservable) returns (uint256) {
        return EthlessReservable.balanceOf(account);
    }

    /**
     * @dev Override the getVotes function to removed the reserved amount from the balance
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        return ERC20VotesUpgradeable.getVotes(account) - reservedOf(account);
    }

    /**
     * @dev Override the getPastVotes function to removed the reserved amount from the balance
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return ERC20VotesUpgradeable.getPastVotes(account, blockNumber) - _pastReservedOf(account, blockNumber);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the sender must not be blacklisted
     * - the receiver must not be blacklisted
     * * the amount sent must not be more than the sender's balance minus the reserved amount
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        require(!isBlacklisted(from) && !isBlacklisted(to), 'GluwaInvestToken: sender or receiver is blacklisted');

        _checkUnreservedBalance(from, amount);
        ERC20PausableUpgradeable._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Override the _mint function to use ERC20VotesUpgradeable._mint()
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        ERC20VotesUpgradeable._mint(account, amount);
    }

    /**
     * @dev Override the _burn function to use ERC20VotesUpgradeable._burn()
     */
    function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        emit Burn(account, amount);
        ERC20VotesUpgradeable._burn(account, amount);
    }

    /**
     * @dev Override the _afterTokenTransfer function to use ERC20VotesUpgradeable._afterTokenTransfer()
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        ERC20VotesUpgradeable._afterTokenTransfer(from, to, amount);
    }
}