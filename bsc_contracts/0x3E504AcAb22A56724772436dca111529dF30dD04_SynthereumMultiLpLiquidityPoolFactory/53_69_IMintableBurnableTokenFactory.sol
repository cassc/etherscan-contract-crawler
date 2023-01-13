// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {
  BaseControlledMintableBurnableERC20
} from '../../BaseControlledMintableBurnableERC20.sol';

/**
 * @title Interface for interacting with the MintableBurnableTokenFactory contract
 */
interface IMintableBurnableTokenFactory {
  /** @notice Calls the deployment of a new ERC20 token
   * @param tokenName The name of the token to be deployed
   * @param tokenSymbol The symbol of the token that will be deployed
   * @param tokenDecimals Number of decimals for the token to be deployed
   */
  function createToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) external returns (BaseControlledMintableBurnableERC20 newToken);
}