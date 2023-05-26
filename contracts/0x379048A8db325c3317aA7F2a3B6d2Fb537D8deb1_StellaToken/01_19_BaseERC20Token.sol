// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/@openzeppelin/contracts/access/Ownable.sol";
import "../libs/@openzeppelin/contracts/security/Pausable.sol";
import "../libs/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libs/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../blacklistable/Blacklistable.sol";
import "../metatx/EIP2771Recipient.sol";
import "../interfaces/IAdministrable.sol";
import "../interfaces/IBurnable.sol";

/**
 * @notice ERC20 token contract
 * supports pausable functions (pause/unpause)
 * supports ERC20Permit extension
 * supports EIP-2771: Secure Protocol for Native Meta Transactions
 * supports blacklist management
 * supports burn/burnFrom
 */
abstract contract BaseERC20Token is
    ERC20,
    Pausable,
    Ownable,
    ERC20Permit,
    EIP2771Recipient,
    Blacklistable,
    IAdministrable,
    IBurnable
{
    /**
     * @dev constructor
     * @param name ERC20 token name
     * @param symbol ERC20 token symbol
     * @param admin the address which has owner privilege
     * @param forwarder the address of EIP-2771 trusted forwarder for meta transaction
     */
    constructor(
        string memory name,
        string memory symbol,
        address admin,
        address forwarder
    ) ERC20(name, symbol) ERC20Permit(name) EIP2771Recipient(forwarder) {
        _transferOwnership(admin);
    }

    /**
     * @dev set new trusted forwarder of EIP2771Recipient
     * @param forwarder new address of trusted forwarder
     */
    function setTrustedForwarder(address forwarder) external override nonEIP2771 onlyOwner {
        // nonEIP2771 modifier is needed
        // modifying configuration needs direct access from administrator account
        _setTrustedForwarder(forwarder);
    }

    /**
     * @dev pause all transfer
     */
    function pause() external override nonEIP2771 onlyOwner {
        _pause();
    }

    /**
     * @dev unpause all transfer
     */
    function unpause() external override nonEIP2771 onlyOwner {
        _unpause();
    }

    /**
     * @dev add accounts to blacklists
     * @param accounts the list of accounts to add to blacklists
     */
    function addBlacklists(address[] calldata accounts) external override nonEIP2771 onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _addBlacklist(accounts[i]);
        }
    }

    /**
     * @dev remove accounts from blacklists
     * @param accounts the list of accounts to remove from blacklists
     */
    function removeBlacklists(address[] calldata accounts) external override nonEIP2771 onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _removeBlacklist(accounts[i]);
        }
    }

    /**
     * @dev override function from Ownable, not to allow meta transaction
     */
    function renounceOwnership() public override nonEIP2771 {
        super.renounceOwnership();
    }

    /**
     * @dev override function from Ownable, not to allow meta transaction
     */
    function transferOwnership(address newOwner) public override nonEIP2771 {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev implementation for IBurnable, destroys `amount` tokens from the caller.
     * @param amount the amount of the token will be burned
     */
    function burn(uint256 amount) external override {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev implementation for IBurnable
     * @dev destroys `amount` tokens from `account`, deducting from the caller's allowance.
     * @dev the caller must have allowance for ``accounts``'s tokens of at least `amount`.
     * @param amount the amount of the token will be burned
     */
    function burnFrom(address account, uint256 amount) external override {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev the contract must not be paused
     * @dev the _msgSender, to, from addresses must not be blacklisted
     * @param from the account the token transferred from
     * @param to the account the token transferred to
     * @param amount the amount of token transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override
        notBlacklisted(from)
        notBlacklisted(to)
        notBlacklisted(_msgSender())
    {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Stella: token transfer while paused");
    }

    /**
     * @dev override for EIP-2771
     * @return sender the address of sender, one of msg.sender or meta transaction signer
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, EIP2771Recipient)
        returns (address sender)
    {
        return EIP2771Recipient._msgSender();
    }

    /**
     * @dev override for EIP-2771
     * @return calldata the calldata of called function
     */
    function _msgData()
        internal
        view
        virtual
        override(Context, EIP2771Recipient)
        returns (bytes calldata)
    {
        return EIP2771Recipient._msgData();
    }
}