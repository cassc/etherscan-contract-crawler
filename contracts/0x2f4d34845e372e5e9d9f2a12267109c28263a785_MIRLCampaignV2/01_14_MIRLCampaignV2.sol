// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Difference compared to v1:
/// Separate rewards for $MIRL holders and non-holders
/// Different rewards allocations to different winners
contract MIRLCampaignV2 is AccessControl {
    using Address for address;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    // in production, currency will be fixed and cannot be changed
    // IERC20 public constant currency = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public currency;
    using Counters for Counters.Counter;

    Counters.Counter private _campaignIdCounter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice multiplier to make sure no floating/decimal points is lost in winners' rewards
    uint256 private constant MIRL_PRECISION_MULTIPLIER = 1e18;

    struct Campaign {
        uint256 rewardForHolders;
        uint256 rewardForNonHolders;
        uint256 maxRewardPerHolderWinner;
        uint256 maxRewardPerNonHolderWinner;
        bool isClosed;
    }

    mapping(uint256 => Campaign) public _campaigns;
    mapping(address => uint256) public winnersBalances; // balances of winner
    
    event CampaignCreated(
        uint256 campaignId,
        uint256 rewardForHolders,
        uint256 rewardForNonHolders,
        uint256 maxRewardPerHolderWinner,
        uint256 maxRewardPerNonHolderWinner
    );
    event CampaignCompleted(
        uint256 campaignId,
        address[] holderWinners,
        uint256[] holderRewardAllocationPoints,
        address[] nonHolderWinners,
        uint256[] nonHolderRewardAllocationPoints
    );
    event Withdraw(address to, uint256 amount);
    event CampaignRewardModified(
        uint256 campaignId,
        uint256 rewardForHolders,
        uint256 rewardForNonHolders
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function setCurrency(address currencyAddress) public onlyRole(ADMIN_ROLE) {
        currency = IERC20(currencyAddress);
    }

    function createCampaign(
        uint256 rewardForHolders,
        uint256 rewardForNonHolders,
        uint256 maxRewardPerHolderWinner,
        uint256 maxRewardPerNonHolderWinner
    ) public onlyRole(ADMIN_ROLE) {
        require(
            rewardForHolders + rewardForNonHolders > 0,
            "Reward must be greater than zero"
        );
        uint256 balance = currency.balanceOf(msg.sender);
        uint256 totalReward = rewardForHolders + rewardForNonHolders;
        require(balance >= totalReward, "Balance is not enough");
        uint256 campaignId = _campaignIdCounter.current();

        // Effects
        _campaignIdCounter.increment();
        address[] memory adr;
        _campaigns[campaignId] = Campaign(
            rewardForHolders,
            rewardForNonHolders,
            maxRewardPerHolderWinner,
            maxRewardPerNonHolderWinner,
            false
        );

        // Interactions
        currency.transferFrom(msg.sender, address(this), totalReward);

        emit CampaignCreated(
            campaignId,
            rewardForHolders,
            rewardForNonHolders,
            maxRewardPerHolderWinner,
            maxRewardPerNonHolderWinner
        );
    }

    /// @notice End campaign & increase winners balance
    /// @param campaignId The campaign id (to query from _campaigns)
    /// @param holderAddresses Winners' wallet addresses - $MIRL holders. If contains a non-holder address then method will reject.
    /// @param holderRewardAllocationPoints Allocation points (or reward weights). Must be the same length as addresses.
    /// @param nonHolderAddresses Winners' wallet addresses - non $MIRL holders.
    /// @param nonHolderRewardAllocationPoints Allocation points (or reward weights). Must be the same length as addresses.
    /// A $600 reward pool with [2,1,3] allocation will result in $200, $100, $300 for each winner, respectively
    function setWinner(
        uint256 campaignId,
        address[] calldata holderAddresses,
        uint256[] calldata holderRewardAllocationPoints,
        address[] calldata nonHolderAddresses,
        uint256[] calldata nonHolderRewardAllocationPoints
    ) public onlyRole(ADMIN_ROLE) {
        require(_exists(campaignId), "Campaign does not exist");
        require(!_isClosed(campaignId), "Campaign is closed");
        require(
            holderAddresses.length == holderRewardAllocationPoints.length,
            "Holders: Allocation points length must equal to winners length"
        );
        require(
            nonHolderAddresses.length == nonHolderRewardAllocationPoints.length,
            "Non-holders: Allocation points length must equal to winners length"
        );

        Campaign memory campaign = _campaigns[campaignId];
        // Effects
        uint256 remainingReward = (campaign.rewardForHolders +
            campaign.rewardForNonHolders);
        _campaigns[campaignId].isClosed = true;
        {
            for (uint256 i = 0; i < holderAddresses.length; i++) {
                require(holderRewardAllocationPoints[i]>0, 'Allocation points must be greater than 0');
                // max reward per winner
                uint256 realReward = Math.min(
                    (holderRewardAllocationPoints[i] *
                        campaign.rewardForHolders) /
                        _reduce(holderRewardAllocationPoints),
                    campaign.maxRewardPerHolderWinner
                );
                winnersBalances[holderAddresses[i]] += realReward;
                remainingReward -= realReward;
            }
        }
        {
            for (uint256 i = 0; i < nonHolderAddresses.length; i++) {
                require(nonHolderRewardAllocationPoints[i]>0, 'Allocation points must be greater than 0');
                // max reward per winner
                uint256 realReward = Math.min(
                    (nonHolderRewardAllocationPoints[i] *
                        campaign.rewardForNonHolders) /
                        _reduce(nonHolderRewardAllocationPoints),
                    campaign.maxRewardPerNonHolderWinner
                );
                winnersBalances[nonHolderAddresses[i]] += realReward;
                remainingReward -= realReward;
            }
        }
        
        if (remainingReward > 0) {
            currency.transfer(
                msg.sender,
                remainingReward
            );
        }

        emit CampaignCompleted(
            campaignId,
            nonHolderAddresses,
            holderRewardAllocationPoints,
            nonHolderAddresses,
            nonHolderRewardAllocationPoints
        );
    }

    function withdraw() public {
        uint256 balance = balanceOfWinner(msg.sender);
        require(balance > 0, "Nothing to withdraw");
        currency.transfer(msg.sender, balance);
        winnersBalances[msg.sender] = 0;
        emit Withdraw(msg.sender, balance);
    }

    function balanceOfWinner(address to) public view returns (uint256) {
        return winnersBalances[to];
    }

    function holdersRewardOf(uint256 campaignId) public view returns (uint256) {
        return _campaigns[campaignId].rewardForHolders;
    }

    function nonHoldersRewardOf(
        uint256 campaignId
    ) public view returns (uint256) {
        return _campaigns[campaignId].rewardForNonHolders;
    }

    function exists(uint256 campaignId) public view returns (bool) {
        return _exists(campaignId);
    }

    function _exists(uint256 campaignId) internal view virtual returns (bool) {
        return
            _campaigns[campaignId].rewardForHolders != 0 ||
            _campaigns[campaignId].rewardForNonHolders != 0;
    }

    function CampaignInfo(uint256 campaignId) public view returns (Campaign memory) {
        return _campaigns[campaignId];
    }

    function _isClosed(
        uint256 campaignId
    ) internal view virtual returns (bool) {
        return _campaigns[campaignId].isClosed;
    }

    function _reduce(
        uint256[] calldata arr
    ) internal pure returns (uint256 result) {
        for (uint256 i = 0; i < arr.length; i++) {
            result += arr[i];
        }
        return result;
    }
}