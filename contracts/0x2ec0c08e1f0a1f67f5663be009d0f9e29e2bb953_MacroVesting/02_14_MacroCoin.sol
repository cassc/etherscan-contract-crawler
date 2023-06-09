//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MacroCoin is ERC20, Pausable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");
    uint256 constant public INITIAL_SUPPLY = 100_000_000;
    uint256 constant public GRACE_PERIOD = 24 hours;
    uint256 public dueDate;
    address public newMacroCoin;
    bool public permanent;

    /// @notice Initial supply of 100 million MACRO tokens is minted to the multisig
    /// Multisig is given the default admin role
    /// Token is non-transferable
    /// @param owner address of the multisig
    constructor(address owner) ERC20("0xMacro", "MACRO") {
        _mint(owner, INITIAL_SUPPLY * (10 ** decimals()));
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _pause();
    }

    /// @notice Once the contract is permanent, pause and unpausing the token will be disabled
    modifier notPermanent() {
        require(!permanent, "CONTRACT_IS_PERMANENT");
        _;
    }

    /// @notice If the contract is permanently paused, minting and transferring will be disallowed
    modifier notPermanentlyPaused() {
        require(!(permanent && paused()), "PERMANENTLY_PAUSED");
        _;
    }

    /// @notice Pauses the token to make it non-transferable
    // Can only be called by the default admin
    /// Must be not permanent
    function pause() 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        notPermanent 
    {
        _pause();
    }

    /// @notice Unpauses the token to make it transferable 
    /// Can only be called by the default admin
    /// Must be not permanent
    function unpause() 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
        notPermanent 
    {
        _unpause();
    }

    /// @notice Makes the contract permanent with a grace period of 24 hours
    /// Can only be called by the default admin
    /// @dev Used when token contract needs to be upgraded 
    function makePermanent() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!permanent, "ALREADY_PERMANENT");
        permanent = true;
        dueDate = block.timestamp + GRACE_PERIOD;
    }

    /// @notice Undos permanence of the contract if grace period hasn't passed
    /// Can only be called by the default admin
    function undoPermanance() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(permanent, "NOT_PERMANENT");
        require(block.timestamp < dueDate, "CANNOT_UNDO_PERMANENCE");
        permanent = false;
        dueDate = 0;
    }

    /// @notice newMacroCoin is set in case of an upgrade on this contract
    /// to indicate this contract's successor
    /// @param newCoin reference to the new macrocoin's address
    function setNewMacroCoin(address newCoin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(permanent && paused() && block.timestamp >= dueDate, "MUST_BE_PERMANENTLY_PAUSED");
        require(newMacroCoin == address(0x0), "CAN_ONLY_SET_ONCE");
        newMacroCoin = newCoin;
    }

    /// @notice Allows anyone with the minter role to mint more MACRO tokens only if 
    /// contract is not permanently paused
    function mint(
        address account,
        uint256 amount
    ) external notPermanentlyPaused {
        require(hasRole((MINTER_ROLE), msg.sender), "NOT_ALLOWED_TO_MINT");
        _mint(account, amount);
    }

    /// @notice Disallows token transferring if contract is permanently paused
    /// Disallows token transferring when token is (not permanently) paused unless it's
    /// initiated by one with a transferer role
    /// Allows transferring when token is not paused
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override notPermanentlyPaused {
        if (paused()) {
            require(hasRole((TRANSFERER_ROLE), msg.sender), "NOT_ALLOWED_TO_TRANSFER");
        }
        super._transfer(from, to, amount);
    }

}