// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IFeeCollector } from "./interfaces/IFeeCollector.sol";
import { LibTransfer } from "./lib/LibTransfer.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

/// @title A smart contract for registering vaults for payments.
contract FeeCollector is IFeeCollector, Multicall, Ownable {
    using LibTransfer for address payable;

    address payable public guildTreasury;
    uint96 public totalFeeBps;

    mapping(string => FeeShare[]) internal feeSchemas;

    Vault[] internal vaults;

    /// @param guildTreasury_ The address that will receive Guild's share from the funds.
    /// @param totalFeeBps_ The percentage of Guild's and any partner's share expressed in basis points.
    constructor(address payable guildTreasury_, uint256 totalFeeBps_) {
        guildTreasury = guildTreasury_;
        totalFeeBps = uint96(totalFeeBps_);
    }

    function registerVault(address payable owner, address token, bool multiplePayments, uint128 fee) external {
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
        vault.balance += uint128(requiredAmount);
        vault.paid[msg.sender] = true;

        // If the tokenAddress is zero, the payment should be in Ether, otherwise in ERC20.
        address tokenAddress = vault.token;
        if (tokenAddress == address(0)) {
            if (msg.value != requiredAmount) revert IncorrectFee(vaultId, msg.value, requiredAmount);
        } else {
            if (msg.value != 0) revert IncorrectFee(vaultId, msg.value, 0);
            payable(address(this)).sendTokenFrom(msg.sender, tokenAddress, requiredAmount);
        }

        emit FeeReceived(vaultId, msg.sender, requiredAmount);
    }

    function withdraw(uint256 vaultId, string calldata feeSchemaKey) external {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);

        Vault storage vault = vaults[vaultId];

        if (msg.sender != vault.owner) revert AccessDenied(msg.sender, vault.owner);

        uint256 collected = vault.balance;
        vault.balance = 0;

        // Calculate fees to receive. Royalty is truncated - the remainder goes to the owner.
        uint256 royaltyAmount = (collected * totalFeeBps) / 10000;
        uint256 guildAmount = royaltyAmount;

        // If the tokenAddress is zero, the collected fees are in Ether, otherwise in ERC20.
        address tokenAddress = vault.token;

        // Distribute fees for partners.
        FeeShare[] memory feeSchema = feeSchemas[feeSchemaKey];
        for (uint256 i; i < feeSchema.length; ) {
            uint256 partnerAmount = (royaltyAmount * feeSchema[i].feeShareBps) / 10000;
            guildAmount -= partnerAmount;

            if (tokenAddress == address(0)) feeSchema[i].treasury.sendEther(partnerAmount);
            else feeSchema[i].treasury.sendToken(tokenAddress, partnerAmount);

            unchecked {
                ++i;
            }
        }

        // Send the fees to Guild and the vault owner.
        if (tokenAddress == address(0)) {
            guildTreasury.sendEther(guildAmount);
            vault.owner.sendEther(collected - royaltyAmount);
        } else {
            guildTreasury.sendToken(tokenAddress, guildAmount);
            vault.owner.sendToken(tokenAddress, collected - royaltyAmount);
        }

        emit Withdrawn(vaultId);
    }

    function addFeeSchema(string calldata key, FeeShare[] calldata feeShare) external onlyOwner {
        FeeShare[] storage fs = feeSchemas[key];
        for (uint256 i; i < feeShare.length; ) {
            fs.push(feeShare[i]);

            unchecked {
                ++i;
            }
        }
        emit FeeSchemaAdded(key);
    }

    function setGuildTreasury(address payable newTreasury) external onlyOwner {
        guildTreasury = newTreasury;
        emit GuildTreasuryChanged(newTreasury);
    }

    function setTotalFeeBps(uint96 newShare) external onlyOwner {
        totalFeeBps = newShare;
        emit TotalFeeBpsChanged(newShare);
    }

    function setVaultDetails(
        uint256 vaultId,
        address payable newOwner,
        bool newMultiplePayments,
        uint128 newFee
    ) external {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        Vault storage vault = vaults[vaultId];

        if (msg.sender != vault.owner) revert AccessDenied(msg.sender, vault.owner);

        vault.owner = newOwner;
        vault.multiplePayments = newMultiplePayments;
        vault.fee = newFee;

        emit VaultDetailsChanged(vaultId);
    }

    function getFeeSchema(string calldata key) external view returns (FeeShare[] memory schema) {
        return feeSchemas[key];
    }

    function getVault(
        uint256 vaultId
    )
        external
        view
        returns (address payable owner, address token, bool multiplePayments, uint128 fee, uint128 balance)
    {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        Vault storage vault = vaults[vaultId];
        return (vault.owner, vault.token, vault.multiplePayments, vault.fee, vault.balance);
    }

    function hasPaid(uint256 vaultId, address account) external view returns (bool paid) {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        return vaults[vaultId].paid[account];
    }
}