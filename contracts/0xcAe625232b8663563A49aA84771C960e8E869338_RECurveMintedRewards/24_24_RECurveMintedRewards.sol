// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRECurveMintedRewards.sol";
import "./Base/UpgradeableBase.sol";
import "./Library/Roles.sol";

contract RECurveMintedRewards is UpgradeableBase(1), IRECurveMintedRewards
{
    bytes32 constant RewardManagerRole = keccak256("ROLE:RECurveMintedRewards:rewardManager");

    uint256 public perDay;
    uint256 public perDayPerUnit;
    uint256 public lastRewardTimestamp;

    //------------------ end of storage

    bool public constant isRECurveMintedRewards = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICanMint public immutable rewardToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveGauge public immutable gauge;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICanMint _rewardToken, ICurveGauge _gauge)
    {
        rewardToken = _rewardToken;
        gauge = _gauge;
    }

    function initialize()
        public
    {
        rewardToken.approve(address(gauge), type(uint256).max);
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveMintedRewards(newImplementation).isRECurveMintedRewards());
    }
    
    function isRewardManager(address user) public view returns (bool) { return Roles.hasRole(RewardManagerRole, user); }

    modifier onlyRewardManager()
    {
        if (!isRewardManager(msg.sender) && msg.sender != owner()) { revert NotRewardManager(); }
        _;
    }

    function sendRewards(uint256 units)
        public
        onlyRewardManager
    {
        uint256 interval = block.timestamp - lastRewardTimestamp;
        if (interval == 0) { return; }
        lastRewardTimestamp = block.timestamp;
        
        uint256 amount = interval * (units * perDayPerUnit + perDay) / 86400;
        if (amount > 0)
        {
            rewardToken.mint(address(this), amount);
            gauge.deposit_reward_token(address(rewardToken), amount);
        }
    }

    function sendAndSetRewardRate(uint256 _perDay, uint256 _perDayPerUnit, uint256 units)
        public
        onlyRewardManager
    {
        sendRewards(units);
        perDay = _perDay;
        perDayPerUnit = _perDayPerUnit;
        emit RewardRate(_perDay, _perDayPerUnit);
    }
    
    function setRewardManager(address manager, bool enabled) 
        public
        onlyOwner
    {
        Roles.setRole(RewardManagerRole, manager, enabled);
    }
}