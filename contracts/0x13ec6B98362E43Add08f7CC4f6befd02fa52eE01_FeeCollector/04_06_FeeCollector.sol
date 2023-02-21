// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IFeeCollector } from "./interfaces/IFeeCollector.sol";
import { LibAddress } from "./lib/LibAddress.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title A smart contract for registering vaults for payments.
contract FeeCollector is IFeeCollector, Multicall {
    using LibAddress for address payable;

    address payable public guildFeeCollector;
    uint96 public guildShareBps;

    Vault[] internal vaults;

    /// @param guildFeeCollector_ The address that will receive Guild's share from the funds.
    /// @param guildShareBps_ The percentage of Guild's share expressed in basis points (e.g 500 for a 5% cut).
    constructor(address payable guildFeeCollector_, uint96 guildShareBps_) {
        guildFeeCollector = guildFeeCollector_;
        guildShareBps = guildShareBps_;
    }

    function registerVault(address owner, address token, bool multiplePayments, uint120 fee) external {
        Vault storage vault = vaults.push();
        vault.owner = owner;
        vault.token = token;
        vault.multiplePayments = multiplePayments;
        vault.fee = fee;

        emit VaultRegistered(vaults.length - 1, owner, token, fee);
    }

    function payFee(uint256 vaultId) external payable {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);

        Vault storage vault = vaults[vaultId];

        if (!vault.multiplePayments && vault.paid[msg.sender]) revert AlreadyPaid(vaultId, msg.sender);

        uint256 requiredAmount = vault.fee;
        vault.collected += uint128(requiredAmount);
        vault.paid[msg.sender] = true;

        // If the tokenAddress is zero, the payment should be in Ether, otherwise in ERC20.
        address tokenAddress = vault.token;
        if (tokenAddress == address(0)) {
            if (msg.value != requiredAmount) revert IncorrectFee(vaultId, msg.value, requiredAmount);
        } else {
            if (msg.value != 0) revert IncorrectFee(vaultId, msg.value, 0);
            if (!IERC20(tokenAddress).transferFrom(msg.sender, address(this), requiredAmount))
                revert TransferFailed(msg.sender, address(this));
        }

        emit FeeReceived(vaultId, msg.sender, requiredAmount);
    }

    function withdraw(uint256 vaultId) external {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);

        Vault storage vault = vaults[vaultId];
        uint256 collected = vault.collected;
        vault.collected = 0;

        // Calculate fees to receive. Guild's part is truncated - the remainder goes to the owner.
        uint256 guildAmount = (collected * guildShareBps) / 10000;
        uint256 ownerAmount = collected - guildAmount;

        // If the tokenAddress is zero, the collected fees are in Ether, otherwise in ERC20.
        address tokenAddress = vault.token;
        if (tokenAddress == address(0)) _withdrawEther(guildAmount, ownerAmount, vault.owner);
        else _withdrawToken(guildAmount, ownerAmount, vault.owner, tokenAddress);

        emit Withdrawn(vaultId, guildAmount, ownerAmount);
    }

    function setGuildFeeCollector(address payable newFeeCollector) external {
        if (msg.sender != guildFeeCollector) revert AccessDenied(msg.sender, guildFeeCollector);
        guildFeeCollector = newFeeCollector;
        emit GuildFeeCollectorChanged(newFeeCollector);
    }

    function setGuildShareBps(uint96 newShare) external {
        if (msg.sender != guildFeeCollector) revert AccessDenied(msg.sender, guildFeeCollector);
        guildShareBps = newShare;
        emit GuildShareBpsChanged(newShare);
    }

    function setVaultDetails(uint256 vaultId, address newOwner, bool newMultiplePayments, uint120 newFee) external {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        Vault storage vault = vaults[vaultId];

        if (msg.sender != vault.owner) revert AccessDenied(msg.sender, vault.owner);

        vault.owner = newOwner;
        vault.multiplePayments = newMultiplePayments;
        vault.fee = newFee;

        emit VaultDetailsChanged(vaultId);
    }

    function getVault(
        uint256 vaultId
    ) external view returns (address owner, address token, bool multiplePayments, uint120 fee, uint128 collected) {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        Vault storage vault = vaults[vaultId];
        return (vault.owner, vault.token, vault.multiplePayments, vault.fee, vault.collected);
    }

    function hasPaid(uint256 vaultId, address account) external view returns (bool paid) {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        return vaults[vaultId].paid[account];
    }

    function _withdrawEther(uint256 guildAmount, uint256 ownerAmount, address eventOwner) internal {
        guildFeeCollector.sendEther(guildAmount);
        payable(eventOwner).sendEther(ownerAmount);
    }

    function _withdrawToken(
        uint256 guildAmount,
        uint256 ownerAmount,
        address eventOwner,
        address tokenAddress
    ) internal {
        IERC20 token = IERC20(tokenAddress);
        if (!token.transfer(guildFeeCollector, guildAmount)) revert TransferFailed(address(this), guildFeeCollector);
        if (!token.transfer(eventOwner, ownerAmount)) revert TransferFailed(address(this), eventOwner);
    }
}