// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ThriveCoinRewardSeason.sol";

/**
 * @author vigan.abd
 * @title ThriveCoin reward season contract with refund gas ability on add reward methods.
 *
 * @dev ThriveCoinRewardSeasonGasRefundable is a simple smart contract that is used to store reward seasons and their
 * respective user rewards. It supports these key functionalities:
 * - Managing reward seasons where there is at most one active season, seasons can be added only by ADMIN_ROLE
 * - Adding user rewards to a season, only by WRITER_ROLE, gas is refunded in these methods
 * - Reading user rewards publicly
 * - Sending user rewards to destination, done by reward owner or reward destinaion
 * - Sending unclaimed rewards to default destination, can be done only by admin
 */
contract ThriveCoinRewardSeasonGasRefundable is ThriveCoinRewardSeason {
  /**
   * @dev Fixed gas cost applied on top of gas used until payable transfer call.
   */
  uint256 fixedGasFee;

  /**
   * @dev Stores first season with default destination and close dates, additionally grants `DEFAULT_ADMIN_ROLE` and
   * `WRITER_ROLE` to the account that deploys the contract. Additionally it sets fixed gas cost applied on top of gas
   * used until payable transfer call in methods that are refundable.
   *
   * @param defaultDestination - Address where remaining funds will be sent once opportunity is closed
   * @param closeDate - Determines time when season will be closed, end users can't claim rewards prior to this date
   * @param claimCloseDate - Determines the date until funds are available to claim, should be after season close date
   * @param _fixedGasFee - Fixed gas cost applied on top of gas used until payable transfer call in methods that are
   *                       refundable.
   */
  constructor(
    address defaultDestination,
    uint256 closeDate,
    uint256 claimCloseDate,
    uint256 _fixedGasFee
  ) ThriveCoinRewardSeason(defaultDestination, closeDate, claimCloseDate) {
    fixedGasFee = _fixedGasFee;
  }

  /**
   * @dev Refunds the gas to transaction origin once the function is executed.
   */
  modifier refundGasCost() {
    uint256 remainingGasStart = gasleft();

    _;

    uint256 usedGas = remainingGasStart - gasleft() + fixedGasFee;
    uint256 gasCost = usedGas * tx.gasprice;
    require(address(this).balance >= gasCost, "ThriveCoinRewardSeasonGasRefundable: not enough funds for transaction");
    payable(tx.origin).transfer(gasCost);
  }

  /**
   * @dev Returns fixed gas cost applied on top of gas used until payable
   * transfer call in methods that are refundable.
   */
  function getFixedGasFee() public view returns (uint256) {
    return fixedGasFee;
  }

  /**
   * @dev Sets fixed gas cost applied on top of gas used until payable
   * transfer call in methods that are refundable.
   */
  function setFixedGasFee(uint256 _fixedGasFee) public virtual onlyAdmin {
    fixedGasFee = _fixedGasFee;
  }

  /**
   * @dev Function to receive ether when msg.data is empty
   */
  receive() external payable {}

  /**
   * @dev Function to receive ether when msg.data is not empty
   */
  fallback() external payable {}

  /**
   * @dev Withdraw ether from smart contract, only admins can do this
   *
   * @param account - Destination of ether funds
   * @param amount - Amount that will be withdrawn
   */
  function withdrawEther(address account, uint256 amount) public onlyAdmin {
    require(address(this).balance >= amount, "ThriveCoinRewardSeasonGasRefundable: not enough funds");

    address payable to = payable(account);
    to.transfer(amount);
  }

  /**
   * @dev Beside storing reward it refunds the gas cost to transaction origin.
   * See {ThriveCoinRewardSeason-addReward} for more details.
   */
  function addReward(
    UserRewardRequest calldata entry
  ) public virtual override(ThriveCoinRewardSeason) onlyWriter refundGasCost {
    super.addReward(entry);
  }

  /**
   * @dev Beside storing rewards it refunds the gas cost to transaction origin.
   * See {ThriveCoinRewardSeason-addRewardBatch} for more details.
   */
  function addRewardBatch(
    UserRewardRequest[] calldata entries
  ) public virtual override(ThriveCoinRewardSeason) onlyWriter refundGasCost {
    super.addRewardBatch(entries);
  }
}