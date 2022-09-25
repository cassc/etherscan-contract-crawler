// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./CollaborativeOwnable.sol";
import "./IFliesToken.sol";

contract FliesToken is ERC20Pausable, CollaborativeOwnable, IFliesToken { 
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint256[] __legendaryTokenIds = [85, 88, 102, 128, 132, 192, 196, 266, 284, 318, 324, 493, 585, 708, 709, 736, 862, 869, 870, 911, 972];

  address public stakingContractAddress = address(0);

  struct WalletInfo {
    uint32 stakedPepeCount;
    uint32 stakedLegendaryCount;
    uint256 committedRewards;
    uint256 lastUpdate;
  }

  mapping(address => WalletInfo) public walletInfo;

  uint256 public constant interval = 86400;
  uint256 public tier1BaseRate = 5 ether;
  uint256 public tier2BaseRate = 7 ether;
  uint256 public tier3BaseRate = 10 ether;
  uint256 public legendaryRate = 15 ether;
  uint32 public legendaryMultiplier = 100;

  uint32 public tier2Requirement = 5;
  uint32 public tier3Requirement = 10;

  constructor() ERC20("FLIES", "FLIES") {
    _mint(address(this), 10_000_000 * 1e18);

    _transfer(address(this), 0xC1F6596B54B98E953276b77393680FC14797Af13, 100_000 * 1e18);

    _pause();
  }

  //
  // Public / External
  //

  function availableRewards(address _address) public view returns(uint256) {
    WalletInfo memory wallet = walletInfo[_address];
    return getPendingReward(_address) + wallet.committedRewards;
  }
  
  function claimRewards() public whenNotPaused {
    _claimRewardsForAddress(_msgSender());
  }

  function dailyRate(address _address) external view returns (uint256) {
    WalletInfo memory wallet = walletInfo[_address];
    uint256 pepeRate = getPepeRate(wallet.stakedPepeCount, wallet.stakedLegendaryCount);
    return (pepeRate * wallet.stakedPepeCount) + (legendaryRate * wallet.stakedLegendaryCount);
  }

  function legendaryTokenIds() external view returns(uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](__legendaryTokenIds.length);
    for (uint256 i = 0; i < __legendaryTokenIds.length; i++) {
      tokenIds[i] = __legendaryTokenIds[i];
    }
    return tokenIds;
  }

  //
  // External (contract events)
  //
  
  function onStakeEvent(address _address, uint256[] calldata _tokenIds) external {
    require(_msgSender() == stakingContractAddress, "sender");

    WalletInfo storage wallet = walletInfo[_address];
    wallet.committedRewards += getPendingReward(_address);
    for (uint256 i; i < _tokenIds.length; i++) {
      if (isTokenLegendary(_tokenIds[i])) {
        wallet.stakedLegendaryCount += 1;
      } else {
        wallet.stakedPepeCount += 1;
      }
    }
    wallet.lastUpdate = block.timestamp;
  }

  function onUnstakeEvent(address _address, uint256[] calldata _tokenIds) external {
    require(_msgSender() == stakingContractAddress, "sender");

    WalletInfo storage wallet = walletInfo[_address];
    wallet.committedRewards += getPendingReward(_address);
    for (uint256 i; i < _tokenIds.length; i++) {
      if (isTokenLegendary(_tokenIds[i])) {
        wallet.stakedLegendaryCount -= 1;
      } else {
        wallet.stakedPepeCount -= 1;
      }
    }
    wallet.lastUpdate = block.timestamp;
  }

  //
  // Internal
  //

  function getPepeRate(uint256 stakedPepeCount, uint256 stakedLegendaryCount) internal view returns (uint256) {
    uint256 pepeRate = tier1BaseRate;

    uint256 totalCount = stakedPepeCount + stakedLegendaryCount;

    if (totalCount >= tier3Requirement) {
      pepeRate = tier3BaseRate;
    } else if (totalCount >= tier2Requirement) {
      pepeRate = tier2BaseRate;
    }

    if (stakedLegendaryCount > 0) {
      pepeRate = pepeRate + (pepeRate.mul(legendaryMultiplier).div(100));
    }
      
    return pepeRate;
  }

  function getPendingReward(address _address) internal view returns(uint256) {
    WalletInfo memory wallet = walletInfo[_address];

    uint256 pepeRate = getPepeRate(wallet.stakedPepeCount, wallet.stakedLegendaryCount);

    uint256 pepeRewards = wallet.stakedPepeCount *
      pepeRate *
      (block.timestamp - wallet.lastUpdate) / 
      interval;

    uint256 legendRewards = wallet.stakedLegendaryCount *
      legendaryRate *
      (block.timestamp - wallet.lastUpdate) / 
      interval;

    return pepeRewards + legendRewards;
  }

  function _claimRewardsForAddress(address _address) internal {
    WalletInfo storage wallet = walletInfo[_address];

    _transfer(address(this), _address, wallet.committedRewards + getPendingReward(_address));

    wallet.committedRewards = 0;
    wallet.lastUpdate = block.timestamp;
  }

  function isTokenLegendary(uint256 _tokenId) internal view returns(bool) {
    for (uint256 i = 0; i < __legendaryTokenIds.length; i++) {
      if (_tokenId == __legendaryTokenIds[i]) {
        return true;
      }
    }
    return false;
  }
  
  //
  // Collaborator Access
  //

  function pause() public onlyCollaborator { 
    _pause(); 
  }

  function unpause() public onlyCollaborator { 
    _unpause(); 
  }

  function burn(address _address, uint256 _amount) external onlyCollaborator {
    require(_address != address(0), "zero");
    _burn(_address, _amount);
  }

  function airDrop(address _address, uint256 _amount) external onlyCollaborator {
    require(_address != address(0), "zero");
    _transfer(address(this), _address, _amount);
  }

  function setTier1BaseRate(uint256 _tier1BaseRate) external onlyCollaborator {
    tier1BaseRate = _tier1BaseRate;
  }

  function setTier2BaseRate(uint256 _tier2BaseRate) external onlyCollaborator {
    tier2BaseRate = _tier2BaseRate;
  }

  function setTier2Requirement(uint32 _tier2Requirement) external onlyCollaborator {
    tier2Requirement = _tier2Requirement;
  }

  function setTier3BaseRate(uint256 _tier3BaseRate) external onlyCollaborator {
    tier3BaseRate = _tier3BaseRate;
  }

  function setTier3Requirement(uint32 _tier3Requirement) external onlyCollaborator {
    tier3Requirement = _tier3Requirement;
  }

  function setLegendaryRate(uint256 _legendaryRate) external onlyCollaborator {
    legendaryRate = _legendaryRate;
  }

  function setLegendaryMultiplier(uint32 _legendaryMultiplier) external onlyCollaborator {
    legendaryMultiplier = _legendaryMultiplier;
  }

  function setStakingContractAddress(address _stakingContractAddress) external onlyCollaborator {
    stakingContractAddress = _stakingContractAddress;
  }

  function setLegendaryTokenIds(uint256[] calldata _legendaryTokenIds) external onlyCollaborator {
    __legendaryTokenIds = _legendaryTokenIds;
  }

  //
  // Owner Access
  //

  function updateWalletInfo(
    address addr, 
    uint32 stakedPepeCount, 
    uint32 stakedLegendaryCount, 
    uint256 committedRewards,
    uint256 lastUpdate
  ) external onlyOwner {
    WalletInfo storage wallet = walletInfo[addr];
    wallet.stakedPepeCount = stakedPepeCount;
    wallet.stakedLegendaryCount = stakedLegendaryCount;
    wallet.committedRewards = committedRewards;
    wallet.lastUpdate = lastUpdate;
  }
}