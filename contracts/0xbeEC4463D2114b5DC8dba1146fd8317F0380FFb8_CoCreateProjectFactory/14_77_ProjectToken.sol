// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../project/ICoCreateProject.sol";

/// @title ProjectToken is an ERC20 token contract
/// @notice This is an UUPS upgradeable ERC20 contract. It can be
/// used for governance using the ERC20Votes interface.
contract ProjectToken is OwnableUpgradeable, ERC20BurnableUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable {
  event AddrAddedToAllowList(address addr);
  event AddrRemovedFromAllowList(address addr);
  event TransferAllowListUpdated(bool isTransferAllowlisted);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // If isTransferAllowlisted is true, then only addresses in the transferAllowList can transfer
  // (either send or receive) tokens
  // If isTransferAllowlisted is false, then all addresses can transfer tokens
  bool public isTransferAllowlisted;
  // If isFixedSupply is true, then no more tokens can be minted after initialization
  bool public isFixedSupply;
  // A public description of the token
  string public description;
  // A mapping of addresses to a boolean indicating whether they are allowlisted for transfers
  mapping(address => bool) public transferAllowList;

  /// @notice Initialize the ERC20 contract
  /// @param name_ Name of the ERC20 token
  /// @param description_ A public description of the token
  /// @param symbol_ Symbol of the ERC20 token
  /// @param initialSupply_ Initial supply
  /// @param isFixedSupply_ Whether the supply is fixed
  /// @param isTransferAllowlisted_ Whether transfers are allowlisted. If true, only addresses in the transferAllowList can transfer
  /// @param mintRecipients_ An array of addresses which receives the minted tokens
  /// @param mintAmounts_ An array of mint amounts received by these addresses
  function initialize(
    ICoCreateProject _coCreateProject,
    string memory name_,
    string memory description_,
    string memory symbol_,
    uint224 initialSupply_,
    bool isFixedSupply_,
    bool isTransferAllowlisted_,
    address[] calldata mintRecipients_,
    uint224[] calldata mintAmounts_
  ) public initializer {
    __ERC20_init(name_, symbol_);
    __Ownable_init();
    __ERC20Burnable_init();
    __ERC20Permit_init(name_);
    __ERC20Votes_init();
    __UUPSUpgradeable_init();
    description = description_;
    isFixedSupply = isFixedSupply_;
    _initialMint(mintRecipients_, mintAmounts_, initialSupply_);
    isTransferAllowlisted = isTransferAllowlisted_;
    // Set project admin as owner of this contract
    _transferOwnership(_coCreateProject.getContractOwner());
    // By default add the treasury to the allowlist of addresses
    uint256 numOfTreasuries = _coCreateProject.getTreasuries().length;
    for (uint256 i = 0; i < numOfTreasuries; ++i) {
      address treasury = _coCreateProject.getTreasuries()[i];
      transferAllowList[treasury] = true;
      emit AddrAddedToAllowList(treasury);
    }
  }

  function _initialMint(
    address[] calldata mintRecipients_,
    uint224[] calldata mintAmounts_,
    uint256 initialSupply_
  ) private {
    require(mintRecipients_.length == mintAmounts_.length, "mintRecipients_ and mintAmounts_ length mismatch");
    uint224 totalMint = 0;
    for (uint224 i = 0; i < mintRecipients_.length; ++i) {
      require(mintAmounts_[i] > 0, "All mint amounts must be > 0");
      _mint(mintRecipients_[i], mintAmounts_[i]);
      totalMint += mintAmounts_[i];
    }
    require(totalMint == initialSupply_, "Mint amounts don't add up to initial supply");
  }

  /**
   * @dev Updates the list of addresses allowlisted for transfer restrictions.
   * Also updates the transfer allowlist restrictions
   *
   * @param _isTransferAllowlisted Whether transfers are allowlisted.
   * @param addAddresses These addresses get added to the allowlist
   * @param removeAddresses These addresses get removed from the allowlist
   */
  function updateAllowlist(
    address[] calldata addAddresses,
    address[] calldata removeAddresses,
    bool _isTransferAllowlisted
  ) public onlyOwner {
    if (_isTransferAllowlisted != isTransferAllowlisted) {
      isTransferAllowlisted = _isTransferAllowlisted;
      emit TransferAllowListUpdated(_isTransferAllowlisted);
    }
    for (uint256 i = 0; i < addAddresses.length; ++i) {
      require(addAddresses[i] != address(0), "Invalid addr");
      transferAllowList[addAddresses[i]] = true;
      emit AddrAddedToAllowList(addAddresses[i]);
    }
    for (uint256 i = 0; i < removeAddresses.length; ++i) {
      if (transferAllowList[removeAddresses[i]]) {
        transferAllowList[removeAddresses[i]] = false;
        emit AddrRemovedFromAllowList(removeAddresses[i]);
      }
    }
  }

  // Minting is only allowed if the token is not fixed supply.
  // Only the owner can mint tokens.
  // We acknowledge that this transaction would fail there are too many recipients
  function mintBatch(address[] calldata recipients, uint256[] calldata amounts) public onlyOwner {
    require(!isFixedSupply, "Minting is restricted");
    require(recipients.length == amounts.length, "recipient and amount length mismatch");
    for (uint256 i = 0; i < recipients.length; ++i) {
      _mint(recipients[i], amounts[i]);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    validateTokenOperation(from, to);
    super._beforeTokenTransfer(from, to, amount);
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal view virtual override onlyOwner {}

  // The following functions are overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._burn(account, amount);
  }

  function _approve(
    address _owner,
    address spender,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable) {
    validateTokenOperation(_owner, spender);
    super._approve(_owner, spender, amount);
  }

  // A token transfer is valid under the following conditions.
  // This allows the owner to restrict transfers to a specific set of addresses if needed.
  // 1. isTransferAllowlisted is false
  // 2. isTransferAllowlisted is true and either the sender or receiver is on the allowlist
  function validateTokenOperation(address from, address to) internal view virtual {
    if (isTransferAllowlisted && !(transferAllowList[from] || transferAllowList[to])) {
      revert("Transfer not allowed");
    }
  }
}