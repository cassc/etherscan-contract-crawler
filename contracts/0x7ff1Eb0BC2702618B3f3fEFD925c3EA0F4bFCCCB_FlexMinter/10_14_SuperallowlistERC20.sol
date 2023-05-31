// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title SuperallowlistERC20
 * @author opnxj
 * @dev The SuperallowlistERC20 contract is an abstract contract that extends the ERC20 token functionality.
 * It adds the ability to manage a denylist and a superallowlist, allowing certain addresses to be excluded from the denylist.
 * The owner can assign a denylister, who is responsible for managing the denylist and adding addresses to it.
 * Addresses on the superallowlist are immune from being denylisted and have additional privileges.
 */
abstract contract SuperallowlistERC20 is ERC20, Ownable {
    address public denylister;
    mapping(address => bool) public denylist;
    mapping(address => bool) public superallowlist;

    event DenylisterSet(address indexed addr);
    event DenylistAdded(address indexed addr);
    event DenylistRemoved(address indexed addr);
    event SuperallowlistAdded(address indexed addr);

    modifier notDenylisted(address addr) {
        require(!denylist[addr], "Address is denylisted");
        _;
    }

    modifier onlyDenylister() {
        require(
            msg.sender == denylister,
            "Only the denylister can call this function"
        );
        _;
    }

    modifier onlySuperallowlister() {
        require(
            msg.sender == owner() || superallowlist[msg.sender],
            "Only the owner or superallowlisted can call this function"
        );
        _;
    }

    /**
     * @notice Initializes the SuperallowlistERC20 contract.
     * @dev This constructor is called when deploying the contract. It sets the 
            initial values of the ERC20 token (name, symbol, and decimals) using the 
            provided parameters. The deployer of the contract becomes the denylister.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals used for token representation.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {
        denylister = msg.sender;
        emit DenylisterSet(msg.sender);
    }

    /**
     * @notice Sets the address assigned to the denylister role.
     * @dev Only the contract owner can call this function. It updates the denylister 
            address to the provided address.
     * @param addr The address to assign as the denylister.
     * Emits a `DenylisterSet` event on success.
     */
    function setDenylister(address addr) external onlyOwner {
        denylister = addr;
        emit DenylisterSet(addr);
    }

    /**
     * @notice Adds the specified address to the denylist.
     * @dev Only the denylister can call this function. The address will be prevented
            from performing transfers if it is on the denylist. Addresses on the 
            superallowlist cannot be added to the denylist using this function.
     * @param addr The address to add to the denylist.
     * Emits a `DenylistAdded` event on success.
     */
    function addToDenylist(address addr) external onlyDenylister {
        require(
            !superallowlist[addr],
            "Cannot add superallowlisted address to the denylist"
        );
        denylist[addr] = true;
        emit DenylistAdded(addr);
    }

    /**
     * @notice Removes the specified address from the denylist.
     * @dev Internal function used to remove an address from the denylist. This 
            function should only be called within the contract.
     * @param addr The address to remove from the denylist.
     * Emits a `DenylistRemoved` event on success.
     */
    function _removeFromDenylist(address addr) internal {
        require(denylist[addr], "Address is not in the denylist");
        denylist[addr] = false;
        emit DenylistRemoved(addr);
    }

    /**
     * @notice Removes the specified address from the denylist.
     * @dev Only the denylister can call this function. The address will be allowed 
            to perform transfers again.
     * @param addr The address to remove from the denylist.
     * Emits a `DenylistRemoved` event on success.
     */
    function removeFromDenylist(address addr) external onlyDenylister {
        _removeFromDenylist(addr);
    }

    /**
     * @notice Adds the specified address to the superallowlist.
     * @dev Only the owner can call this function. Once added, the address becomes a 
            superallowlisted address and cannot be denylisted. If the address was 
            previously on the denylist, it will be removed from the denylist.
     * @param addr The address to add to the superallowlist.
     * Emits a `DenylistRemoved` event if the address was previously on the denylist.
     * Emits a `SuperallowlistAdded` event on success.
     */
    function addToSuperallowlist(address addr) external onlySuperallowlister {
        if (denylist[addr]) {
            _removeFromDenylist(addr);
        }
        superallowlist[addr] = true;
        emit SuperallowlistAdded(addr);
    }

    /**
     * @notice Transfers a specified amount of tokens from the sender's account to the specified recipient.
     * @dev Overrides the ERC20 `transfer` function. Restricts the transfer if either
            the sender or recipient is denylisted.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating the success of the transfer.
     */
    function transfer(
        address to,
        uint256 value
    )
        public
        override
        notDenylisted(msg.sender)
        notDenylisted(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /**
     * @notice Transfers a specified amount of tokens from a specified address to the 
               specified recipient, on behalf of the sender.
     * @dev Overrides the ERC20 `transferFrom` function. Restricts the transfer if 
            either the sender, recipient, or `from` address is denylisted.
     * @param from The address from which to transfer tokens.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating the success of the transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        override
        notDenylisted(msg.sender)
        notDenylisted(from)
        notDenylisted(to)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
}