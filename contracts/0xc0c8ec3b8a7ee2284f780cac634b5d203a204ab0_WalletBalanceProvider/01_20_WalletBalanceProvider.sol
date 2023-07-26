// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IPunks} from "../interfaces/IPunks.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title WalletBalanceProvider contract
 * @author BendDao; Forked and edited by Unlockd, influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE UNLOCKD PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the Unlockd backend.
 **/
contract WalletBalanceProvider {
  using Address for address payable;
  using Address for address;
  using SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  address constant MOCK_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
    @dev Check the reserve balance of a wallet in a reserve contract

    Returns the balance of the reserve for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
  function balanceOfReserve(address user, address token) public view returns (uint256) {
    if (token == MOCK_ETH_ADDRESS) {
      return user.balance; // ETH balance
      // check if token is actually a contract
    } else if (token.isContract()) {
      return IERC20(token).balanceOf(user);
    }
    revert("INVALID_TOKEN");
  }

  /**
   * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
   * @param users The list of users
   * @param tokens The list of tokens
   * @return And array with the concatenation of, for each user, his/her balances
   **/
  function batchBalanceOfReserve(
    address[] calldata users,
    address[] calldata tokens
  ) external view returns (uint256[] memory) {
    uint256 usersLength = users.length;
    uint256 tokensLength = tokens.length;

    uint256[] memory balances = new uint256[](usersLength * tokensLength);

    for (uint256 i; i < usersLength; ) {
      for (uint256 j; j < tokensLength; ) {
        balances[i * tokensLength + j] = balanceOfReserve(users[i], tokens[j]);
        unchecked {
          ++j;
        }
      }

      unchecked {
        ++i;
      }
    }

    return balances;
  }

  /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
  function getUserReservesBalances(
    address provider,
    address user
  ) external view returns (address[] memory, uint256[] memory) {
    ILendPool pool = ILendPool(ILendPoolAddressesProvider(provider).getLendPool());
    address[] memory reserves = pool.getReservesList();
    uint256 reservesLength = reserves.length;
    address[] memory reservesWithEth = new address[](reservesLength + 1);
    for (uint256 i; i < reservesLength; ) {
      reservesWithEth[i] = reserves[i];

      unchecked {
        i = i + 1;
      }
    }
    reservesWithEth[reservesLength] = MOCK_ETH_ADDRESS;

    uint256[] memory balances = new uint256[](reservesWithEth.length);

    for (uint256 j; j < reservesLength; ) {
      DataTypes.ReserveConfigurationMap memory configuration = pool.getReserveConfiguration(reservesWithEth[j]);

      (bool isActive, , , ) = configuration.getFlagsMemory();

      if (!isActive) {
        delete balances[j];
        continue;
      }
      balances[j] = balanceOfReserve(user, reservesWithEth[j]);

      unchecked {
        ++j;
      }
    }
    balances[reservesLength] = balanceOfReserve(user, MOCK_ETH_ADDRESS);

    return (reservesWithEth, balances);
  }

  /**
    @dev Check the nft balance of a wallet in a nft contract

    Returns the balance of the nft for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
  function balanceOfNft(address user, address token) public view returns (uint256) {
    if (token.isContract()) {
      return IERC721(token).balanceOf(user);
    }
    revert("INVALID_TOKEN");
  }

  /**
   * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
   * @param users The list of users
   * @param tokens The list of tokens
   * @return And array with the concatenation of, for each user, his/her balances
   **/
  function batchBalanceOfNft(
    address[] calldata users,
    address[] calldata tokens
  ) external view returns (uint256[] memory) {
    uint256 usersLength = users.length;
    uint256 tokensLength = tokens.length;
    uint256[] memory balances = new uint256[](usersLength * tokensLength);

    for (uint256 i; i < usersLength; ) {
      for (uint256 j; j < tokensLength; ) {
        balances[i * tokensLength + j] = balanceOfNft(users[i], tokens[j]);
        unchecked {
          ++j;
        }
      }

      unchecked {
        i = i + 1;
      }
    }

    return balances;
  }

  /**
    @dev provides balances of user wallet for all nfts available on the pool
    */
  function getUserNftsBalances(
    address provider,
    address user
  ) external view returns (address[] memory, uint256[] memory) {
    ILendPool pool = ILendPool(ILendPoolAddressesProvider(provider).getLendPool());

    address[] memory nfts = pool.getNftsList();
    uint256 nftsLength = nfts.length;
    uint256[] memory balances = new uint256[](nftsLength);

    for (uint256 j; j < nftsLength; ) {
      balances[j] = balanceOfNft(user, nfts[j]);

      unchecked {
        ++j;
      }
    }

    return (nfts, balances);
  }

  /**
   * @dev Returns a token ID list owned by `owner`.
   * Requirements:
   *  - The `token` must be IERC721Enumerable contract address
   * @param owner The address of user
   * @param token The address of ERC721 contract
   */
  function batchTokenOfOwnerByIndex(address owner, address token) external view returns (uint256[] memory) {
    uint256 tokenBalances = IERC721Enumerable(token).balanceOf(owner);

    uint256[] memory tokenIds = new uint256[](tokenBalances);
    for (uint256 index; index < tokenBalances; ) {
      tokenIds[index] = IERC721Enumerable(token).tokenOfOwnerByIndex(owner, index);

      unchecked {
        index = index + 1;
      }
    }

    return tokenIds;
  }

  /**
   * @dev Returns a token ID list owned by `owner`.
   * Requirements:
   *  - The `token` must be IERC721 contract address
   *  - The `start` plus `count` must be not greater than total supply
   *  - The transaction must not ran out of gas, `count` <= 2000
   * @param owner The address of user
   * @param token The address of ERC721 contract
   * @param start The starting token ID
   * @param count The scaning number
   */
  function batchTokenOfOwner(
    address owner,
    address token,
    uint256 start,
    uint256 count
  ) external view returns (uint256[] memory) {
    uint256 tokenBalances = IERC721(token).balanceOf(owner);

    uint256[] memory tokenIds = new uint256[](tokenBalances);
    uint256 pos;
    uint256 maxTokenId = start + count;
    for (uint256 tokenId; tokenId < maxTokenId; ) {
      try IERC721(token).ownerOf(tokenId) returns (address tokenOwner) {
        if (tokenOwner == owner) {
          tokenIds[pos] = tokenId;
          pos++;
          //avoid useless loop scan
          if (pos == tokenBalances) {
            return tokenIds;
          }
        }
      } catch Error(string memory /*reason*/) {} catch (bytes memory /*lowLevelData*/) {}

      unchecked {
        tokenId = tokenId + 1;
      }
    }

    return tokenIds;
  }

  /**
   * @dev Returns a punk index list owned by `owner`.
   * Requirements:
   *  - The `punkContract` must be CryptoPunksMarket address
   *  - The `start` plus `count` must be not greater than total supply
   *  - The transaction must not ran out of gas, `count` <= 2000
   * @param owner The address of user
   * @param punkContract The address of punk contract
   * @param start The starting punk index
   * @param count The scaning number
   */
  function batchPunkOfOwner(
    address owner,
    address punkContract,
    uint256 start,
    uint256 count
  ) external view returns (uint256[] memory) {
    uint256 punkBalances = IPunks(punkContract).balanceOf(owner);

    uint256[] memory punkIndexs = new uint256[](punkBalances);
    uint256 pos;
    uint256 maxIndex = start + count;
    for (uint256 punkIndex; punkIndex < maxIndex; ) {
      address ownerAddress = IPunks(punkContract).punkIndexToAddress(punkIndex);
      if (ownerAddress != owner) {
        continue;
      }

      punkIndexs[pos] = punkIndex;
      pos++;
      //avoid useless loop scan
      if (pos == punkBalances) {
        return punkIndexs;
      }

      unchecked {
        punkIndex = punkIndex + 1;
      }
    }

    return punkIndexs;
  }
}