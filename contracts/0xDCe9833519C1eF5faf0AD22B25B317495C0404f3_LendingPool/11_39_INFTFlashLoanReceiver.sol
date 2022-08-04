// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';

/**
 * @title INFTFlashLoanReceiver interface
 * @notice Interface for the Vinci fee INFTFlashLoanReceiver.
 * @author Aave
 * @author Vinci
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface INFTFlashLoanReceiver {
  function executeOperation(
    address assets,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256 premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

  function LENDING_POOL() external view returns (ILendingPool);
}