// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ISocialBloxTokenDistribute {
    /**
     * Must be implemented by SocialBlox to distribute SBLX tokens.
     */
    function distribute(address[] calldata accounts, uint256[] calldata amounts) external;
}

/**
 * SocialBlox ERC20 root contract.
 *
 * @dev https://www.socialblox.io
 */
contract SBLXRootToken is
    AccessControl,
    ERC2771Context,
    ERC20,
    ERC20Snapshot,
    ERC20Pausable,
    ERC20Capped,
    ISocialBloxTokenDistribute
{
    /// This role allows an account to temporarly suspend token transfers
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    /// this role allows an account to create a snapshot
    bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTTER_ROLE");

    /// this role alles an account to mint extra tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * Install SBLX token contract and grant the given manager the ability
     * to assign or revoke roles to accounts.
     *
     * @param manager account that has the ability to grant/revoke roles
     * @param cap max tokens that can be created
     */
    constructor(address manager, uint256 cap)
        ERC20("SocialBlox", "SBLX")
        ERC20Capped(cap)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, manager);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev delete contract from state
     */
    function destroy() external onlyRole(DEFAULT_ADMIN_ROLE) {
        selfdestruct(payable(_msgSender()));
    }

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     */
    function snapshot() external onlyRole(SNAPSHOTTER_ROLE) returns (uint256) {
        return super._snapshot();
    }

    /**
     * @dev distribute creates extra tokens and distributes them to the given
     * list of accounts with corresponding amounts.
     * e.g. accounts[0] is assigned amounts[0]
     *      accounts[1] is assigned amounts[1]
     */
    function distribute(address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyRole(MINTER_ROLE)
    {
        require(accounts.length == amounts.length, "invalid lengths");
        for (uint i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    /**
     * @dev _msgSender returns the original message sender, e.g. either the
     * msg.sender or the sender as set by the forwarder in case of a
     * meta/gasless transaction.
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    /**
     * @dev _msgData returns the original transaction payload, e.g. either the
     * msg.data or the msg.data stripped with the senders address as set by the
     * forwarder in case of a meta/gasless transaction.
     */
    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev mandatory override
     */
    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }

    /**
     * @dev temporarly suspend all token actions
     */
    function pause() public onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev resume token actions
     */
    function unpause() public onlyRole(PAUSE_ROLE) {
        _unpause();
    }
}