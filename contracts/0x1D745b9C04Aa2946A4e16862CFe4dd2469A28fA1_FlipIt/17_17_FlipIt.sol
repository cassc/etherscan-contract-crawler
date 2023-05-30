// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *  @title FlipIt ERC20 token
 *
 *  @notice An implementation of the ERC20 token in the FlipIt ecosystem.
 */
contract FlipIt is ERC20, ERC20Burnable, ERC20Permit, AccessControl {
    //-------------------------------------------------------------------------
    // Constants & Immutables

    bytes32 internal UNTAXED_ROLE = keccak256("UNTAXED_ROLE");
    bytes32 internal ALLOWED_TO_TRANSFER_EARLY_ROLE = keccak256("ALLOWED_TO_TRANSFER_EARLY_ROLE");

    uint256 internal TRANSFER_TAX_NUMERATOR = 1;
    uint256 internal TRANSFER_TAX_DENOMINATOR = 100;

    /// @notice Address to which the tax will be transferred.
    address internal immutable taxCollector;

    //-------------------------------------------------------------------------
    // Config

    /// @notice Timestamp after which "public" transfers will be available.
    uint256 internal supervisedTransfersEndAt;

    //-------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when game has been played.
    /// @param timestamp The value of the new timestamp.
    event SupervisedTransfersEndAtUpdated(uint256 timestamp);

    //-------------------------------------------------------------------------
    // Errors

    /// @notice Transfer made by authorized caller.
    /// When the timestamp of supervised transfers has not expired,
    /// transfers can only be performed by authorized addresses
    /// (addresses with the "ALLOWED_TO_TRANSFER_EARLY_ROLE" role).
    /// @param spender Address of the spender.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param amount Amount of the transferred tokens.
    error UnauthorizedTransfer(address spender, address from, address to, uint256 amount);

    /// @notice Update to an invalid value.
    /// The update can be made when the current value of `supervisedTransfersEndAt` has not passed.
    /// @param timestamp The value of the new timestamp.
    error InvalidSupervisedTransfersEndAtTimestamp(uint256 timestamp);

    //-------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param name_ ERC20 name of the token.
    /// @param symbol_ ERC20 symbol of the token.
    /// @param initialSupply Initial amount of tokens.
    /// @param taxCollector_ Address to which the tax will be transferred.
    constructor(string memory name_, string memory symbol_, uint256 initialSupply, address taxCollector_) ERC20(name_, symbol_) ERC20Permit(name_) {
        address deployer = _msgSender();

        _mint(deployer, initialSupply);
        _grantRole(DEFAULT_ADMIN_ROLE, deployer);

        taxCollector = taxCollector_;
    }

    //-------------------------------------------------------------------------
    // Configuration

    /// @notice Updates the timestamp after which public transfers will be available.
    /// @dev Throws error if `supervisedTransfersEndAt` has not passed yet.
    /// @param supervisedTransfersEndAt_ The value of the new timestamp.
    function updateSupervisedTransfersEndAt(uint256 supervisedTransfersEndAt_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 timestamp = supervisedTransfersEndAt;

        // checks if the previous timestamp has not yet passed
        if (timestamp != 0 && block.timestamp > timestamp) {
            revert InvalidSupervisedTransfersEndAtTimestamp(supervisedTransfersEndAt_);
        }

        supervisedTransfersEndAt = supervisedTransfersEndAt_;

        emit SupervisedTransfersEndAtUpdated(supervisedTransfersEndAt_);
    }

    //-------------------------------------------------------------------------
    // Domain

    /// @notice Checks if the spender is authorized to make transfer.
    /// Calculates tax and transfers it to the tax collector.
    /// @dev Throws error if current block.timestamp is less than `supervisedTransfersEndAt`
    /// and `msg.sender` doesn't have the "ALLOWED_TO_TRANSFER_EARLY_ROLE" role.
    /// @inheritdoc ERC20
    function _transfer(address from, address to, uint256 amount) internal override {
        address sender = _msgSender();

        if (block.timestamp < supervisedTransfersEndAt && !hasRole(ALLOWED_TO_TRANSFER_EARLY_ROLE, sender)) {
            revert UnauthorizedTransfer(sender, from, to, amount);
        }

        (uint256 tax, uint256 rest) = _computeTax(sender, from, to, amount);

        if (tax > 0) super._transfer(from, taxCollector, tax);

        super._transfer(from, to, rest);
    }

    /// @notice Calculate the tax depending on the transfer parties.
    /// @param sender Address of the sender.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param amount Amount of the tokens.
    /// @return tax The value of calculated tax.
    /// @return The value deducted by calculated tax.
    function _computeTax(address sender, address from, address to, uint256 amount) internal view returns (uint256 tax, uint256) {
        if (hasRole(UNTAXED_ROLE, sender) || hasRole(UNTAXED_ROLE, to) || hasRole(UNTAXED_ROLE, from)) return (tax, amount);

        tax = (amount * TRANSFER_TAX_NUMERATOR) / TRANSFER_TAX_DENOMINATOR;

        return (tax, amount - tax);
    }
}