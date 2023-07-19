// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../_external/openzeppelin/ERC20Upgradeable.sol";
import "../../_external/openzeppelin/OwnableUpgradeable.sol";
import "../../_external/openzeppelin/Initializable.sol";
import "../../_external/openzeppelin/SafeERC20Upgradeable.sol";

import {IVaultController} from "../IVaultController.sol";
import {IVault} from "../IVault.sol";
import {MKRVotingVault} from "../vault/MKRVotingVault.sol";
import {MKRVotingVaultController} from "../controller/MKRVotingVaultController.sol";

/// @title CappedMkrToken
/// @notice handles all minting/burning of underlying
/// @dev extends IERC20 upgradable
contract CappedMkrToken is Initializable, OwnableUpgradeable, ERC20Upgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;

    error CannotDepositZero();
    error CapReached();
    error InsufficientAllowance();
    error InvalidMKRVotingVault();
    error InvalidVault();
    error OnlyVaults();

    ERC20Upgradeable public _underlying;
    IVaultController public _vaultController;
    MKRVotingVaultController public _mkrVotingVaultController;

    // in actual units
    uint256 private _cap;

    /// @notice initializer for contract
    /// @param name_ name of capped token
    /// @param symbol_ symbol of capped token
    /// @param underlying_ the address of underlying
    /// @param vaultController_ the address of vault controller
    /// @param mkrVotingVaultController_ the address of voting vault controller
    function initialize(
        string memory name_,
        string memory symbol_,
        address underlying_,
        address vaultController_,
        address mkrVotingVaultController_
    ) public initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
        _underlying = ERC20Upgradeable(underlying_);

        _vaultController = IVaultController(vaultController_);
        _mkrVotingVaultController = MKRVotingVaultController(mkrVotingVaultController_);
    }

    /// @notice 18 decimals
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /// @notice get the Cap
    /// @return cap uint256
    function getCap() public view returns (uint256) {
        return _cap;
    }

    /// @notice set the Cap
    function setCap(uint256 cap_) external onlyOwner {
        _cap = cap_;
    }

    function checkCap(uint256 amount_) internal view {
        if (ERC20Upgradeable.totalSupply() + amount_ > _cap) revert CapReached();
    }

    /// @notice deposit _underlying to mint CappedMkrToken
    /// @param amount of underlying to deposit
    /// @param vaultId recipient vault of tokens
    function deposit(uint256 amount, uint96 vaultId) public {
        if (amount == 0) revert CannotDepositZero();
        MKRVotingVault votingVault = MKRVotingVault(_mkrVotingVaultController.votingVaultAddress(vaultId));
        if (address(votingVault) == address(0)) revert InvalidMKRVotingVault();
        IVault vault = IVault(_vaultController.vaultAddress(vaultId));
        if (address(vault) == address(0)) revert InvalidVault();

        checkCap(amount);
        // check allowance and ensure transfer success
        uint256 allowance_ = _underlying.allowance(_msgSender(), address(this));
        if (allowance_ < amount) revert InsufficientAllowance();
        // mint this token, the collateral token, to the vault
        ERC20Upgradeable._mint(address(vault), amount);
        // send the actual underlying to the voting vault for the vault
        _underlying.safeTransferFrom(_msgSender(), address(votingVault), amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint96 vault_id = _mkrVotingVaultController.vaultId(_msgSender());
        // only vaults will ever send this. only vaults will ever hold this token.
        if (vault_id == 0) revert OnlyVaults();
        // get the corresponding voting vault
        address voting_vault_address = _mkrVotingVaultController.votingVaultAddress(vault_id);
        if (voting_vault_address == address(0)) revert InvalidMKRVotingVault();
        // burn the collateral tokens from the sender, which is the vault that holds the collateral tokens
        ERC20Upgradeable._burn(_msgSender(), amount);
        // move the underlying tokens from voting vault to the target
        _mkrVotingVaultController.retrieveUnderlying(amount, voting_vault_address, recipient);
        return true;
    }

    function transferFrom(
        address, /*sender*/
        address, /*recipient*/
        uint256 /*amount*/
    ) public pure override returns (bool) {
        // allowances are never granted, as the MKRVotingVault does not grant allowances.
        // this function is therefore always uncallable and so we will just return false
        return false;
    }
}