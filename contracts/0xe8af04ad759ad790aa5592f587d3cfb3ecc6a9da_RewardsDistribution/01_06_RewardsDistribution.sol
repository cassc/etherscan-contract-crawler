// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.0

pragma solidity ^0.8.0;

// Inheritance
import "../utils/Owned.sol";
import "../interfaces/IRewardsDistribution.sol";

// Libraires
import "../libraries/SafeDecimalMath.sol";

// Internal references
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistribution
contract RewardsDistribution is Owned, IRewardsDistribution {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  /**
   * @notice Authorised addresses able to call distributeRewards
   */
  mapping(address => bool) public rewardDistributors;

  /**
   * @notice Address of the Synthetix ProxyERC20
   */
  address public pop;

  /**
   * @notice Address of the FeePoolProxy
   */
  address public treasury;

  /**
   * @notice An array of addresses and amounts to send
   */
  DistributionData[] public override distributions;

  constructor(
    address _owner,
    address _pop,
    address _treasury
  ) public Owned(_owner) {
    pop = _pop;
    treasury = _treasury;
  }

  // ========== EXTERNAL SETTERS ==========

  function setPop(address _pop) external onlyOwner {
    pop = _pop;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function approveRewardDistributor(address _distributor, bool _approved) external onlyOwner {
    emit RewardDistributorUpdated(_distributor, _approved);
    rewardDistributors[_distributor] = _approved;
  }

  // ========== EXTERNAL FUNCTIONS ==========

  /**
   * @notice Adds a Rewards DistributionData struct to the distributions
   * array. Any entries here will be iterated and rewards distributed to
   * each address when tokens are sent to this contract and distributeRewards()
   * is called by the autority.
   * @param destination An address to send rewards tokens too
   * @param amount The amount of rewards tokens to send
   * @param isLocker If the contract is a popLocker which has a slightly different notifyRewardsAmount interface
   */
  function addRewardDistribution(
    address destination,
    uint256 amount,
    bool isLocker
  ) external onlyOwner returns (bool) {
    require(destination != address(0), "Cant add a zero address");
    require(amount != 0, "Cant add a zero amount");

    DistributionData memory rewardsDistribution = DistributionData(destination, amount, isLocker);
    distributions.push(rewardsDistribution);

    emit RewardDistributionAdded(distributions.length - 1, destination, amount, isLocker);
    return true;
  }

  /**
   * @notice Deletes a RewardDistribution from the distributions
   * so it will no longer be included in the call to distributeRewards()
   * @param index The index of the DistributionData to delete
   */
  function removeRewardDistribution(uint256 index) external onlyOwner {
    require(index <= distributions.length - 1, "index out of bounds");

    // shift distributions indexes across
    delete distributions[index];
  }

  /**
   * @notice Edits a RewardDistribution in the distributions array.
   * @param index The index of the DistributionData to edit
   * @param destination The destination address. Send the same address to keep or different address to change it.
   * @param amount The amount of tokens to edit. Send the same number to keep or change the amount of tokens to send.
   * @param isLocker If the contract is a popLocker which has a slightly different notifyRewardsAmount interface
   */
  function editRewardDistribution(
    uint256 index,
    address destination,
    uint256 amount,
    bool isLocker
  ) external onlyOwner returns (bool) {
    require(index <= distributions.length - 1, "index out of bounds");

    distributions[index].destination = destination;
    distributions[index].amount = amount;
    distributions[index].isLocker = isLocker;

    return true;
  }

  function distributeRewards(uint256 amount) external override returns (bool) {
    require(amount > 0, "Nothing to distribute");
    require(rewardDistributors[msg.sender], "not authorized");
    require(pop != address(0), "Pop is not set");
    require(treasury != address(0), "Treasury is not set");
    require(
      IERC20(pop).balanceOf(address(this)) >= amount,
      "RewardsDistribution contract does not have enough tokens to distribute"
    );

    uint256 remainder = amount;

    // Iterate the array of distributions sending the configured amounts
    for (uint256 i = 0; i < distributions.length; i++) {
      if (distributions[i].destination != address(0) || distributions[i].amount != 0) {
        remainder = remainder.sub(distributions[i].amount);

        // Approve the POP
        IERC20(pop).approve(distributions[i].destination, distributions[i].amount);

        // If the contract implements RewardsDistributionRecipient.sol, inform it how many POP its received.
        bytes memory payload;
        if (distributions[i].isLocker) {
          payload = abi.encodeWithSignature("notifyRewardAmount(address,uint256)", pop, distributions[i].amount);
        } else {
          payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", distributions[i].amount);
        }

        // solhint-disable avoid-low-level-calls
        (bool success, ) = distributions[i].destination.call(payload);

        if (!success) {
          // Note: we're ignoring the return value as it will fail for contracts that do not implement RewardsDistributionRecipient.sol
        }
      }
    }

    // After all ditributions have been sent, send the remainder to the RewardsEscrow contract
    IERC20(pop).transfer(treasury, remainder);

    emit RewardsDistributed(amount);
    return true;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Retrieve the length of the distributions array
   */
  function distributionsLength() external view override returns (uint256) {
    return distributions.length;
  }

  /* ========== Events ========== */

  event RewardDistributionAdded(uint256 index, address destination, uint256 amount, bool isLocker);
  event RewardsDistributed(uint256 amount);
  event RewardDistributorUpdated(address indexed distributor, bool approved);
}