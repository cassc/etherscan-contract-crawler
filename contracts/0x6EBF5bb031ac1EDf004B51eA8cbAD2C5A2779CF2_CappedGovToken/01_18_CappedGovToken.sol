// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../_external/IERC20Metadata.sol";
import "../_external/openzeppelin/ERC20Upgradeable.sol";
import "../_external/openzeppelin/OwnableUpgradeable.sol";
import "../_external/openzeppelin/Initializable.sol";

import "./IVaultController.sol";
import "./IVault.sol";
import "./VotingVault.sol";
import "./VotingVaultController.sol";


/// @title CappedGovToken
/// @notice handles all minting/burning of underlying
/// @dev extends ierc20 upgradable
contract CappedGovToken is Initializable, OwnableUpgradeable, ERC20Upgradeable {
  IERC20Metadata public _underlying;
  IVaultController public _vaultController;
  VotingVaultController public _votingVaultController;

  // in actual units
  uint256 public _cap;

  /// @notice initializer for contract
  /// @param name_ name of capped token
  /// @param symbol_ symbol of capped token
  /// @param underlying_ the address of underlying
  /// @param vaultController_ the address of vault controller
  /// @param votingVaultController_ the address of voting vault controller
  function initialize(
    string memory name_,
    string memory symbol_,
    address underlying_,
    address vaultController_,
    address votingVaultController_
  ) public initializer {
    __Ownable_init();
    __ERC20_init(name_, symbol_);
    _underlying = IERC20Metadata(underlying_);

    _vaultController = IVaultController(vaultController_);
    _votingVaultController = VotingVaultController(votingVaultController_);
  }

  /// @notice 18 decimal erc20 spec should have been written into the fucking standard
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
    require(ERC20Upgradeable.totalSupply() + amount_ <= _cap, "cap reached");
  }

  /// @notice deposit _underlying to mint CappedToken
  /// @param amount of underlying to deposit
  /// @param vaultId recipient vault of tokens
  function deposit(uint256 amount, uint96 vaultId) public {
    require(amount > 0, "Cannot deposit 0");
    VotingVault votingVault = VotingVault(_votingVaultController.votingVaultAddress(vaultId));
    require(address(votingVault) != address(0x0), "invalid voting vault");
    IVault vault = IVault(_vaultController.vaultAddress(vaultId));
    require(address(vault) != address(0x0), "invalid vault");
    // check cap
    checkCap(amount);
    // check allowance and ensure transfer success
    uint256 allowance = _underlying.allowance(_msgSender(), address(this));
    require(allowance >= amount, "Insufficient Allowance");
    // mint this token, the collateral token, to the vault
    ERC20Upgradeable._mint(address(vault), amount);
    // send the actual underlying to the voting vault for the vault
    require(_underlying.transferFrom(_msgSender(), address(votingVault), amount), "transfer failed");
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    uint96 vault_id = _votingVaultController.vaultId(_msgSender());
    // only vaults will ever send this. only vaults will ever hold this token.
    require(vault_id > 0, "only vaults");
    // get the corresponding voting vault
    address voting_vault_address = _votingVaultController.votingVaultAddress(vault_id);
    require(voting_vault_address != address(0x0), "no voting vault");
    // burn the collateral tokens from the sender, which is the vault that holds the collateral tokens
    ERC20Upgradeable._burn(_msgSender(), amount);
    // move the underlying tokens from voting vault to the target
    _votingVaultController.retrieveUnderlying(amount, voting_vault_address, recipient);
    return true;
  }

  function transferFrom(
    address /*sender*/,
    address /*recipient*/,
    uint256 /*amount*/
  ) public pure override returns (bool) {
    // allowances are never granted, as the VotingVault does not grant allowances.
    // this function is therefore always uncallable and so we will just return false
    return false;
  }
}