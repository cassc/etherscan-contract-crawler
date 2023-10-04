// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IRouterClient} from './interfaces/IRouterClient.sol';

/**
 * @title ICCIPAdapter
 * @author BGD Labs
 * @notice interface containing the events, objects and method definitions used in the CCIP bridge adapter
 */
interface ICCIPAdapter {
  /**
   * @notice method to get the LINK token address used to pay fees
   * @return address of the LINK token
   */
  function LINK_TOKEN() external view returns (IERC20);

  /**
   * @notice method to get the CCIP router address
   * @return address of the CCIP router
   */
  function CCIP_ROUTER() external view returns (IRouterClient);
}