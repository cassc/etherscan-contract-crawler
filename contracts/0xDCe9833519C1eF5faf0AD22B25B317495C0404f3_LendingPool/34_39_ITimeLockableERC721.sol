pragma solidity 0.8.11;

import {IERC721} from '../dependencies/openzeppelin/contracts/IERC721.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ITimeLockableERC721 is IERC721 {
  event TimeLocked(
    uint256 indexed tokenid,
    uint256 indexed lockType,
    uint40 indexed expirationTime
  );

  function lock(uint256 tokenid, uint16 lockType) external;

  function getUnlockTime(uint256 tokenId) external view returns(uint40 unlockTime);

  function getLockData(uint256 tokenId) external view returns(DataTypes.TimeLock memory lock);

  function unlockedBalanceOfBatch(address user, uint256[] memory tokenIds) external view returns(uint256[] memory amounts);

  function tokensAndLocksByAccount(address user) external view returns(uint256[] memory tokenIds, DataTypes.TimeLock[] memory locks);
}