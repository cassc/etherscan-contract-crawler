// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Constants.sol";
import "./interfaces/IStrategy.sol";
import "../interfaces/IWhiteList.sol";
import "../interfaces/IContractsRegistry.sol";

contract Strategy is IStrategy, Ownable {
  /// @notice Stores the address of ContractsRegistry contract.
  /// It is used to get addresses of main contracts as WhiteList
  /// @return address of ContractsRegistry contract.
  IContractsRegistry public registry;

  /// @param registry_ address of ContractRegistry contract.
  constructor(address registry_) {
    if (registry_ == address(0)) {
      revert ZeroAddress();
    }
    registry = IContractsRegistry(registry_);
  }

  /// @notice Set new address of ContractRegistry contract.
  /// @param registry_ new address of ContractRegistry contract.
  function setRegistry(address registry_) external onlyOwner {
    if (registry_ == address(0)) {
      revert ZeroAddress();
    }
    registry = IContractsRegistry(registry_);
    emit UpdatedRegistry(registry_);
  }

  /// @notice Validate transaction by checking addresses "from" and "to".
  /// @param from address of sender transaction;
  /// @param to address of recipient of sMILE tokens.
  function validateTransaction(
    address from,
    address to,
    uint256 /* amount */
  ) external view {
    IWhiteList whiteList = IWhiteList(
      registry.getContractByKey(WHITE_LIST_CONTRACT_CODE)
    );
    if (!(whiteList.isValidAddress(from) || whiteList.isValidAddress(to))) {
      revert InvalidAddresses();
    }
  }
}