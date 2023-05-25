// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGrainLGE.sol";
import "./interfaces/IGrainSaleClaim.sol";

error GrainSaleClaim__GrainNotSet();
error GrainSaleClaim__WeightNotSet();
error GrainSaleClaim__GrainAlreadySet();
error GrainSaleClaim__WeightAlreadySet();

contract GrainSaleClaim is IGrainSaleClaim, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant PERIOD = 91 days;
    uint256 public constant MAX_KINK_RELEASES = 8;
    uint256 public constant MAX_RELEASES = 20;
    uint256 public constant maxKinkDiscount = 4e26;
    uint256 public constant maxDiscount = 6e26;
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IGrainLGE public immutable lge;
    IERC20 public immutable grain;
    uint256 public immutable lgeEnd;

    uint256 public cumulativeWeight;
    uint256 public totalGrain;

    struct UserShare {
        uint256 userTotalWeight;
        uint256 numberOfReleases;
        uint256 totalClaimed;
    }

    mapping (address => UserShare) public userShares;

    constructor(address _lge) {
        lge = IGrainLGE(_lge);
        grain = lge.grain();
        lgeEnd = lge.lgeEnd();
    }

    function claim() external returns (uint256 claimable) {
        if (totalGrain == 0) {
            revert GrainSaleClaim__GrainNotSet();
        }
        if (cumulativeWeight == 0) {
            revert GrainSaleClaim__WeightNotSet();
        }
        if (userShares[msg.sender].userTotalWeight == 0) {
            (uint256 _userTotalWeight, uint256 _numberOfReleases) = getUserShares(msg.sender);
            userShares[msg.sender].userTotalWeight = _userTotalWeight;
            userShares[msg.sender].numberOfReleases = _numberOfReleases;
        }

        claimable = _pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }

        emit Claim(msg.sender, claimable);
    }

    // @dev returns the amount of grain that can be claimed by the user
    // @param user address of the user
    function _pending(address user) internal view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = _totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // number of quarters since the end of the LGE
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            // if the quarters passed since end of LGE is greater than number of releases...
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                // set the claim periods to maximum
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (_totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    // @dev returns the total amount of grain that the user is entitled to
    // @param user address of the user
    function _totalOwed(address user) internal view returns (uint256 userTotal) {
        uint256 shareOfLge = userShares[user].userTotalWeight * PERCENT_DIVISOR / cumulativeWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    // @dev sets the total amount of grain that the user is entitled to
    // @param grainAmount amount of grain to be set
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        /// Fetch the tokens to guarantee the amount received
        if (totalGrain != 0) {
            revert GrainSaleClaim__GrainAlreadySet();
        }
        totalGrain = grainAmount;
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
    }

    // @dev sets the total amount of grain that the user is entitled to
    // @param _cumulativeWeight total weight of the chain
    function setCumulativeWeight(uint256 _cumulativeWeight) external onlyOwner {
        if (cumulativeWeight != 0) {
            revert GrainSaleClaim__WeightAlreadySet();
        }
        cumulativeWeight = _cumulativeWeight;
    }

    // @dev returns the total weight of the user and the number of releases
    // @param user address of the user
    function getUserShares(address user) public view returns (uint256 userTotalWeight, uint256 numberOfReleases) {
        (uint256 usdcValue, uint256 releases,,, address nft,) = lge.userShares(user);

        uint256 whitelistedBonus = lge.whitelistedBonuses(nft);

        uint256 vestingPremium;
        if (releases == 0) {
            vestingPremium = 0;
        } else if (releases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * releases / MAX_KINK_RELEASES;
        } else if (releases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (releases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        uint256 weight = vestingPremium == 0 ? usdcValue : usdcValue * PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium);

        uint256 bonusWeight = nft == address(0) ? 0 : weight * whitelistedBonus / PERCENT_DIVISOR;

        userTotalWeight = weight + bonusWeight;
        numberOfReleases = releases;
    }
}