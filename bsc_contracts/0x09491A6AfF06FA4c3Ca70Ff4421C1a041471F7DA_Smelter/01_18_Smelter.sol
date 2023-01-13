//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { IERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import { IERC721ReceiverUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import { UUPSUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import { SafeOwnableUpgradeable } from '@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol';

import { ISmelter } from './interface/ISmelter.sol';
import { IP12BadgeUpgradable } from './interface/IP12BadgeUpgradable.sol';

contract Smelter is
  ISmelter,
  IERC721ReceiverUpgradeable,
  SafeOwnableUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  address public constant NULL_ADDRESS = 0x0000000000000000000000000000000000000001;

  /// @dev erc721 badge to be burned
  IP12BadgeUpgradable internal _badge;
  /// @dev first several tokenIds can reward
  uint256 internal _maxTokenId;
  /// @dev reward erc20 address
  IERC20Upgradeable internal _rewardToken;
  /// @dev reward erc20 amount
  uint256 internal _rewardAmount;

  function initialize(
    address owner_,
    IP12BadgeUpgradable badge,
    IERC20Upgradeable rewardToken
  ) public initializer {
    _badge = badge;
    _rewardToken = rewardToken;

    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable_init_unchained(owner_);
  }

  /**
   * @dev set maxTokenId
   */
  function setMaxTokenId(uint256 maxTokenId) external onlyOwner {
    _maxTokenId = maxTokenId;
    emit MaxTokenIdSet(maxTokenId);
  }

  /**
   * @dev set rewardAmount
   */
  function setRefundAmount(uint256 rewardAmount) external onlyOwner {
    _rewardAmount = rewardAmount;
    emit rewardAmountSet(rewardAmount);
  }

  /**
   * @dev Received ERC-721 function
   * @dev check data to disallow directly transfer by mistake
   * @dev use swapIn instead
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    if (msg.sig != this.cast.selector) {
      revert InvalidTransfer();
    }
    return this.onERC721Received.selector;
  }

  /**
   * @dev burn tokenId and get erc20 back
   */
  function cast(uint256 tokenId) public {
    if (tokenId > _maxTokenId) {
      revert InvalidRewardTokenId();
    }

    _badge.safeTransferFrom(_msgSender(), NULL_ADDRESS, tokenId);

    _rewardToken.transfer(_msgSender(), _rewardAmount);

    emit Redeem(_msgSender(), tokenId, _rewardAmount);
  }

  function getBadge() external view returns (address) {
    return address(_badge);
  }

  function getRewardToken() external view returns (address) {
    return address(_rewardToken);
  }

  function getMaxTokenId() external view returns (uint256) {
    return _maxTokenId;
  }

  function getRewardAmount() external view returns (uint256) {
    return _rewardAmount;
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}