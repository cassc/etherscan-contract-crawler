// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ITimeLockableERC721} from './ITimeLockableERC721.sol';
import {IInitializableNToken} from './IInitializableNToken.sol';

interface INToken is ITimeLockableERC721, IInitializableNToken {
    /**
    * @dev Emitted after the mint action
    * @param from The address performing the mint
    * @param tokenId The token id being
    * @param value The amount being
    **/
    event Mint(address indexed from, uint256 tokenId, uint256 value);

    /**
    * @dev Mints `amount` NTokens with `tokenId` to `user`
    * @param user The address receiving the minted tokens
    * @param tokenId The NFT's id
    * @param amount The amount of tokens getting minted
    * @return `true` if the the previous balance of the user was 0
    */
    function mint(
        address user,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

    /**
   * @dev Emitted after nTokens are burned
   * @param from The owner of the nTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param tokenId The token id being burned
   * @param value The amount being burned
   **/
  event Burn(address indexed from, address indexed target, uint256 tokenId, uint256 value);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param tokenId The NFT token id being transfered
   * @param amount The amount being transferred
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 tokenId, uint256 amount);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param tokenIds The ids of NFT tokens being transferred
   * @param amounts The amounts being transferred
   **/
  event BalanceBatchTransfer(address indexed from, address indexed to, uint256[] tokenIds, uint256[] amounts);

  /**
   * @dev Burns nTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the vTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param tokenId The token id being burned
   * @param amount The amount being burned
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 tokenId,
    uint256 amount
  ) external;

  function burnBatch(
    address user,
    address receiverOfUnderlying,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) external;

  /**
   * @dev Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
   * @param from The address getting liquidated, current owner of the vTokens
   * @param to The recipient
   * @param tokenIds The token id of tokens getting transffered
   * @param values The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory values
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in withdrawNFT()
   * @param user The recipient of the underlying
   * @param tokenId The token id getting transferred
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 tokenId, uint256 amount) external returns (uint256);

  function getLiquidationAmounts(address user, uint256 maxTotal, uint256[] memory tokenIds, uint256[] memory amounts) external view returns(uint256, uint256[] memory);

  /**
   * @dev Returns the address of the underlying asset of this nToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}