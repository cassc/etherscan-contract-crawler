//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {IRatios} from "interfaces/IRatios.sol";
import {Errors} from "utils/Errors.sol";
import {Owner} from "utils/Owner.sol";

/**
 * @title Warlord WAR minting ratios contract V2
 * @author Paladin
 * @notice Calculate the amounts of WAR to mint or burn
 */
contract WarRatiosV2 is IRatios, Owner {
  /**
   * @notice 1e18 scale
   */
  uint256 private constant UNIT = 1e18;

  /**
   * @notice Amount of WAR to mint per token for each listed token
   */
  mapping(address => uint256) public warPerToken;

  /**
   * @notice Returns the ratio for a given token
   * @param token Address of the token
   */
  function getTokenRatio(address token) external view returns (uint256) {
    return warPerToken[token];
  }

  /**
   * @notice Adds a new token and sets the ratio of WAR to mint per token
   * @param token Address of the token
   * @param warRatio Amount of WAR minted per token
   */
  function addToken(address token, uint256 warRatio) external onlyOwner {
    if (token == address(0)) revert Errors.ZeroAddress();
    if (warRatio == 0) revert Errors.ZeroValue();
    if (warPerToken[token] != 0) revert Errors.RatioAlreadySet();

    warPerToken[token] = warRatio;
  }

  /**
   * @notice Returns the amount of WAR to mint for a given amount of token
   * @param token Address of the token
   * @param amount Amount of token received
   * @return mintAmount (uint256) : Amount to mint
   */
  function getMintAmount(address token, uint256 amount) external view returns (uint256 mintAmount) {
    if (token == address(0)) revert Errors.ZeroAddress();
    if (amount == 0) revert Errors.ZeroValue();

    mintAmount = amount * warPerToken[token] / UNIT;
  }

  /**
   * @notice Returns the amount of token to redeem for a given amount of WAR burned
   * @param token Address of the token
   * @param burnAmount Amount of WAR to burn
   * @return redeemAmount (uint256) : Redeem amount
   */
  function getBurnAmount(address token, uint256 burnAmount) external view returns (uint256 redeemAmount) {
    if (token == address(0)) revert Errors.ZeroAddress();
    if (burnAmount == 0) revert Errors.ZeroValue();

    redeemAmount = burnAmount * UNIT / warPerToken[token];
  }
}