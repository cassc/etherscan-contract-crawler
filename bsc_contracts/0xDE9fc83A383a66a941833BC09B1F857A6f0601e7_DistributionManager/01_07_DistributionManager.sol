// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

import "../common/AbstractDependant.sol";
import "../interfaces/IGhostMinter.sol";
import "../interfaces/IDistributionManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DistributionManager is IDistributionManager, AbstractDependant, Ownable {

  address public minter;

  uint256 public defaultLiquidityPercent;
  address public liquidityRecipient;

  address public profitRecipient;
  address public donationRecipient;

  mapping (bytes32 => uint256) donationPercentage;

  event DonationPercentageUpdated(bytes32 slug, uint256 oldPercentage, uint256 newPercentage);
  event DefaultLiquidityPercentageUpdated(uint256 oldPercentage, uint256 newPercentage);

  modifier onlyMinter() {
    require(msg.sender == minter, "DistributionManager: Caller is not minter");
    _;
  }

  function setDependencies(IRegistry _registry) external override onlyInjectorOrZero {
    minter = _registry.getGhostMinterContract();
    liquidityRecipient = _registry.getLiquidityRecipient();
    donationRecipient = _registry.getDonationRecipient(); // @todo custom getters or consts?
    profitRecipient = _registry.getProfitRecipient();
  }

  function getLiquidityRewards(bytes32 /*slug*/, uint256 /*tokenId*/) external view
    returns(IGhostMinter.Distribution memory distribution)
  {
    distribution.recipient = liquidityRecipient;
    distribution.amount = defaultLiquidityPercent; // potentially may implement custom liquidity % by token

    return(distribution);
  }

  function getDonationRewards(bytes32 slug) external view
    returns(IGhostMinter.Distribution memory distribution)
  {
    if (donationPercentage[slug] > 0) {
      distribution.recipient = donationRecipient;
      distribution.amount = donationPercentage[slug];
    }

    return(distribution);
  }

  function setDonationPercentage(bytes32 slug, uint256 percentage) external onlyOwner
  {
    emit DonationPercentageUpdated(slug, donationPercentage[slug], percentage);
    donationPercentage[slug] = percentage;
  }

  function setDefaultLiquidityPercentage(uint256 percentage) external onlyOwner
  {
    emit DefaultLiquidityPercentageUpdated(defaultLiquidityPercent, percentage);
    defaultLiquidityPercent = percentage;
  }

  function getProfitRecipient(bytes32 /*slug*/) external view
    returns(address)
  {
    // potentially could return different addresses for different token collections
    return(profitRecipient);
  }
}