// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {ERC20Burnable} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import {ERC20Snapshot} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol';
import {ERC20Votes} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';

/**
 * @title InfinityTokens
 * @author nneverlander. Twitter @nneverlander
 * @notice The Infinity Token ($NFT). Implements timelock config to control token release schedule.
 */
contract InfinityToken is ERC20('Infinity', 'INFT'), ERC20Permit('Infinity'), ERC20Burnable, ERC20Snapshot, ERC20Votes {
  uint256 public constant EPOCH_INFLATION = 25e7 ether;
  uint256 public constant EPOCH_DURATION = 180 days;
  uint256 public constant EPOCH_CLIFF = 180 days;
  uint256 public constant MAX_EPOCHS = 4;
  uint256 public immutable currentEpochTimestamp;
  uint256 public currentEpoch;
  uint256 public previousEpochTimestamp;
  address public admin;

  event EpochAdvanced(uint256 currentEpoch, uint256 supplyMinted);
  event AdminChanged(address oldAdmin, address newAdmin);

  /**
    @param _admin The address of the admin who will be sent the minted tokens
    @param supply Initial supply of the token
   */
  constructor(address _admin, uint256 supply) {
    previousEpochTimestamp = block.timestamp;
    currentEpochTimestamp = block.timestamp;
    admin = _admin;

    // mint initial supply
    _mint(admin, supply);
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'only admin');
    _;
  }

  // =============================================== ADMIN FUNCTIONS =========================================================

  function advanceEpoch() external onlyAdmin {
    require(currentEpoch < MAX_EPOCHS, 'no epochs left');
    require(block.timestamp >= currentEpochTimestamp + EPOCH_CLIFF, 'cliff not passed');
    require(block.timestamp >= previousEpochTimestamp + EPOCH_DURATION, 'not ready to advance');

    uint256 epochsPassedSinceLastAdvance = (block.timestamp - previousEpochTimestamp) / EPOCH_DURATION;
    uint256 epochsLeft = MAX_EPOCHS - currentEpoch;
    epochsPassedSinceLastAdvance = epochsPassedSinceLastAdvance > epochsLeft
      ? epochsLeft
      : epochsPassedSinceLastAdvance;

    // update epochs
    currentEpoch += epochsPassedSinceLastAdvance;
    previousEpochTimestamp = block.timestamp;

    // inflation amount
    uint256 supplyToMint = EPOCH_INFLATION * epochsPassedSinceLastAdvance;

    // mint supply
    _mint(admin, supplyToMint);

    emit EpochAdvanced(currentEpoch, supplyToMint);
  }

  function changeAdmin(address newAdmin) external onlyAdmin {
    require(newAdmin != address(0), 'zero address');
    admin = newAdmin;
    emit AdminChanged(admin, newAdmin);
  }

  // =============================================== HOOKS =========================================================

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Snapshot) {
    ERC20Snapshot._beforeTokenTransfer(from, to, amount);
  }

  // =============================================== REQUIRED OVERRIDES =========================================================
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}