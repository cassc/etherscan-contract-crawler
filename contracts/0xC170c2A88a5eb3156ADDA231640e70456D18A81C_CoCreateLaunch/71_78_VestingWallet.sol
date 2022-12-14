// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import "../utils/CoCreateContractMetadata.sol";

/**
 * @title VestingWallet
 * @dev This contract handles the vesting of Eth and ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract VestingWallet is CoCreateContractMetadata, VestingWalletUpgradeable {
  event VestingWalletDeployed(
    string name,
    string description,
    address indexed vestingWalletContract,
    address beneficiaryAddress,
    uint64 startTimestamp,
    uint64 durationSeconds,
    address coCreateProject
  );

  /**
   * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
   */
  function initialize(
    string memory _name,
    string memory _description,
    address beneficiaryAddress,
    uint64 startTimestamp,
    uint64 durationSeconds
  ) public initializer {
    __CoCreateContractMetadata_init(_name, _description);
    __VestingWallet_init(beneficiaryAddress, startTimestamp, durationSeconds);
    emit VestingWalletDeployed(
      _name,
      _description,
      address(this),
      beneficiaryAddress,
      startTimestamp,
      durationSeconds,
      msg.sender
    );
  }

  constructor() {
    _disableInitializers();
  }
}