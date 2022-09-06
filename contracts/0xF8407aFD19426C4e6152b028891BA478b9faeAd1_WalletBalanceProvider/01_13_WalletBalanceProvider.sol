// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

pragma experimental ABIEncoderV2;

import {Address} from '../dependencies/openzeppelin/contracts/Address.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC721} from '../dependencies/openzeppelin/contracts/IERC721.sol';
import {IERC721Enumerable} from '../dependencies/openzeppelin/contracts/IERC721Enumerable.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {GPv2SafeERC20} from '../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {NFTVaultConfiguration} from '../protocol/libraries/configuration/NFTVaultConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title WalletBalanceProvider contract
 * @author Aave, influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE AAVE PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the Aave backend.
 **/
contract WalletBalanceProvider {
  using Address for address payable;
  using Address for address;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;

  address constant MOCK_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
    @dev Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
  function balanceOf(address user, address token) public view returns (uint256) {
    if (token == MOCK_ETH_ADDRESS) {
      return user.balance; // ETH balance
      // check if token is actually a contract
    } else if (token.isContract()) {
      return IERC20(token).balanceOf(user);
    }
    revert('INVALID_TOKEN');
  }

  function balanceOfNFT(address user, address token) public view returns (uint256) {
    if (token.isContract()) {
      return IERC721(token).balanceOf(user);
    }
    revert('INVALID_TOKEN');
  }

  /**
   * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
   * @param users The list of users
   * @param tokens The list of tokens
   * @return And array with the concatenation of, for each user, his/her balances
   **/
  function batchBalanceOf(address[] calldata users, address[] calldata tokens)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = balanceOf(users[i], tokens[j]);
      }
    }

    return balances;
  }

  /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
  function getUserWalletBalances(address provider, address user)
    external
    view
    returns (address[] memory, uint256[] memory)
  {
    ILendingPool pool = ILendingPool(ILendingPoolAddressesProvider(provider).getLendingPool());

    address[] memory reserves = pool.getReservesList();
    address[] memory vaults = pool.getNFTVaultsList();
    address[] memory reservesWithEth = new address[](reserves.length + 1 + vaults.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      reservesWithEth[i] = reserves[i];
    }
    reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;
    uint256 offset = reserves.length + 1;

    for (uint256 i = 0; i < vaults.length; ++i) {
      reservesWithEth[i + offset] = vaults[i];
    }

    uint256[] memory balances = new uint256[](reservesWithEth.length);

    for (uint256 j = 0; j < reserves.length; j++) {
      DataTypes.ReserveConfigurationMap memory configuration =
        pool.getConfiguration(reservesWithEth[j]);

      (bool isActive, , , ) = configuration.getFlagsMemory();

      if (!isActive) {
        balances[j] = 0;
        continue;
      }
      balances[j] = balanceOf(user, reservesWithEth[j]);
    }
    balances[reserves.length] = balanceOf(user, MOCK_ETH_ADDRESS);
    for (uint256 j = offset; j < balances.length; ++j) {
      DataTypes.NFTVaultConfigurationMap memory configuration =
        pool.getNFTVaultConfiguration(reservesWithEth[j]);

      (bool isActive, ) = configuration.getFlagsMemory();

      if (!isActive) {
        balances[j] = 0;
        continue;
      }
      balances[j] = balanceOfNFT(user, reservesWithEth[j]);
    }

    return (reservesWithEth, balances);
  }

  struct UserNFTTokensData {
    address underlyingNFT;
    uint256[] tokenIds;
    uint256[] amounts;
  }

  function getUserNFTTokens(address provider, address user)
    external
    view
    returns (UserNFTTokensData[] memory)
  {
    ILendingPool pool = ILendingPool(ILendingPoolAddressesProvider(provider).getLendingPool());

    address[] memory vaults = pool.getNFTVaultsList();
    UserNFTTokensData[] memory tokensList = new UserNFTTokensData[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      UserNFTTokensData memory tokens = tokensList[i];
      tokens.underlyingNFT = vaults[i];
      IERC721Enumerable underlyingNFT = IERC721Enumerable(vaults[i]);
      tokens.tokenIds = new uint256[](underlyingNFT.balanceOf(user));
      tokens.amounts = new uint256[](tokens.tokenIds.length);
      for(uint256 j = 0; j < tokens.tokenIds.length; ++j) {
        tokens.tokenIds[j] = underlyingNFT.tokenOfOwnerByIndex(user, j);
        tokens.amounts[j] = 1;
      }
    }
    return tokensList;
  }
}