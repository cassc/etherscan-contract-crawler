//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReferalPool is Ownable {
    enum ReferalLevels {
        Basic,
        Advanced,
        Pro
    }
    struct Referals {
        ReferalLevels level;
        uint256 totalRewards;
        uint256 claimedRewards;
        uint256 lastClaimedAt;
        uint256 lastRewardsAt;
        address lastRewardFrom;
        bool isAtMaxLevel;
        uint256 referalCount;
    }

    struct TierStructure {
        uint256 minReferals;
        uint256 rewardPercentage;
    }

    uint256 constant DEVIDE_FACTOR = 10000;

    address public superAdmin;
    IERC20 public Token;

    uint256 public totalRewardsSent;

    mapping(ReferalLevels => TierStructure) public levelDetails;

    mapping(address => Referals) public referalDetails;

    mapping(address => address) public userReferal;

    event NewReferalAdded(address referee, address referal);
    event NewReferalBonusAdded(address from, address to, uint256 amount);

    modifier onlySuper() {
        require(
            msg.sender == superAdmin,
            "Ownable: caller is not the Super admin"
        );
        _;
    }

    constructor(address _superAdmin, address _token) {
        TierStructure storage _level1 = levelDetails[ReferalLevels.Basic];
        TierStructure storage _level2 = levelDetails[ReferalLevels.Advanced];
        TierStructure storage _level3 = levelDetails[ReferalLevels.Pro];

        _level1.minReferals = 1;
        _level1.rewardPercentage = 100;

        _level2.minReferals = 4;
        _level2.rewardPercentage = 200;

        _level3.minReferals = 7;
        _level3.rewardPercentage = 300;

        superAdmin = _superAdmin;
        Token = IERC20(_token);
    }

    function setReferal(address _referal) external {
        require(
            userReferal[msg.sender] == address(0),
            "Referal address already set"
        );

        require(msg.sender != _referal, "Can not set own address");

        userReferal[msg.sender] = _referal;

        Referals storage referal = referalDetails[_referal];

        referal.referalCount++;

        if (!referal.isAtMaxLevel) {
            updateReferalLevel(_referal);
        }

        emit NewReferalAdded(msg.sender, _referal);
    }

    function setReferalBonus(
        address from,
        uint256 buyAmount
    ) external onlyOwner {
        if (userReferal[from] == address(0)) return;
        Referals storage referal = referalDetails[userReferal[from]];
        TierStructure memory tier = levelDetails[referal.level];

        uint256 _bonus = (buyAmount * tier.rewardPercentage) / DEVIDE_FACTOR;

        referal.lastRewardFrom = from;
        referal.lastRewardsAt = block.timestamp;
        referal.totalRewards += _bonus;

        Token.transfer(userReferal[from], _bonus);

        emit NewReferalBonusAdded(from, userReferal[from], _bonus);
    }

    function changeTiers(
        ReferalLevels level,
        uint256 newMinReferals,
        uint256 newRewardPercentage
    ) external onlySuper {
        TierStructure storage tier = levelDetails[level];

        // Check that the provided values are valid
        require(newMinReferals > 0, "Minimum referrals must be greater than 0");
        require(
            newRewardPercentage > 0,
            "Reward percentage must be greater than 0"
        );

        // Update the tier structure with the new values
        tier.minReferals = newMinReferals;
        tier.rewardPercentage = newRewardPercentage;
    }

    function updateReferalLevel(address _user) internal {
        Referals storage referal = referalDetails[_user];

        uint256 referalCount = referal.referalCount;
        ReferalLevels newLevel;

        if (referalCount >= levelDetails[ReferalLevels.Pro].minReferals) {
            newLevel = ReferalLevels.Pro;
        } else if (
            referalCount >= levelDetails[ReferalLevels.Advanced].minReferals
        ) {
            newLevel = ReferalLevels.Advanced;
        } else {
            newLevel = ReferalLevels.Basic;
        }

        // Update the referral's level if it has changed
        if (referal.level != newLevel) {
            referal.level = newLevel;
            if (newLevel == ReferalLevels.Pro) referal.isAtMaxLevel = true;
        }
    }

    function claimRewards() external {
        Referals storage referal = referalDetails[msg.sender];

        require(referal.totalRewards > 0, "you didn't start earning yet");

        uint256 claimabaleRewards = referal.totalRewards -
            referal.claimedRewards;

        require(claimabaleRewards > 0, "you don't have any claiamble rewards");

        referal.claimedRewards += claimabaleRewards;

        referal.lastClaimedAt = block.timestamp;
        Token.transfer(msg.sender, claimabaleRewards);

        totalRewardsSent += claimabaleRewards;
    }
}