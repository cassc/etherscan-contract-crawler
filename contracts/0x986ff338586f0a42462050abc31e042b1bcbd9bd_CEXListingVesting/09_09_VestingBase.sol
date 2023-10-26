//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingBase is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claimed(address vestingAddress, uint256 claimAmount);

    struct VestingInfo {
        address wallet;
        uint256 amountTokenAllocation;
        uint256 amountTGE;
        uint256 durationLock;
        uint256 numberOfClaims;
    }

    struct VestingSchedule {
        uint256 amountOfGrant;
        uint256 amountClaimed;
        uint256 numberOfClaimed;
        bool isClaimedTGE;
    }

    address public xox;
    uint256 public TIME_TOKEN_LAUNCH; //August 20 - at 12:00PM UTC ~ 1692532800
    uint256 public ONE_TIME_UNLOCK; // month = 2592000, year = 31536000
    uint256 private _FIVE_MINUTES = 300;

    uint256 private amountVesting;

    VestingInfo public vestingInfo;
    VestingSchedule public vestingSchedule;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address xox_,
        VestingInfo memory vestingInfo_,
        uint256 one_time_unlock_
    ) {
        TIME_TOKEN_LAUNCH = 1700913600;
        require(xox_ != address(0), "Cannot zero address");
        xox = xox_;
        ONE_TIME_UNLOCK = one_time_unlock_;
        require(vestingInfo_.wallet != address(0), "Cannot zero address");
        require(vestingInfo_.amountTokenAllocation > 0, "Cannot zero amount");
        vestingInfo = vestingInfo_;
        vestingSchedule = VestingSchedule(
            vestingInfo_.amountTokenAllocation,
            0,
            0,
            false
        );
        amountVesting = vestingInfo_.amountTokenAllocation.sub(
            vestingInfo_.amountTGE
        );
        _transferOwnership(0x9A29b081E91471302dD7522B211775d90a1622C1);
    }

    /**
     * @dev Withdraw the token out this contract by beneficiary
     */
    function claim() external {
        require(
            msg.sender == vestingInfo.wallet,
            "caller is not the beneficiary"
        );
        require(block.timestamp >= getPendingTimeLaunch(), "Not Launchtime yet");
        uint256 amountClaim = 0;
        uint256 numberClaimCurrent = _getNumberofClaims();
        if (numberClaimCurrent > vestingInfo.numberOfClaims)
            numberClaimCurrent = vestingInfo.numberOfClaims;
        if (!vestingSchedule.isClaimedTGE && numberClaimCurrent == 0) {
            amountClaim = vestingInfo.amountTGE;
            vestingSchedule.isClaimedTGE = true;
        }
        if (numberClaimCurrent > vestingSchedule.numberOfClaimed) {
            amountClaim = _calculatorAmountClaim(
                numberClaimCurrent.sub(vestingSchedule.numberOfClaimed),
                vestingInfo.numberOfClaims
            );
            if (!vestingSchedule.isClaimedTGE) {
                amountClaim = amountClaim.add(vestingInfo.amountTGE);
                vestingSchedule.isClaimedTGE = true;
            }
        }
        require(amountClaim > 0, "nothing to claim");
        IERC20(xox).transfer(msg.sender, amountClaim);
        vestingSchedule.amountClaimed = vestingSchedule.amountClaimed.add(
            amountClaim
        );
        vestingSchedule.numberOfClaimed = numberClaimCurrent;
        emit Claimed(msg.sender, amountClaim);
    }

    /**
     * @dev  View function to see pending amount on frontend
     */
    function getPendingAmount(address account) external view returns (uint256) {
        if (block.timestamp < getPendingTimeLaunch()) return 0;
        if (account != vestingInfo.wallet) return 0;
        uint256 numberClaimCurrent = _getNumberofClaims();
        if (numberClaimCurrent >= vestingInfo.numberOfClaims)
            return
                vestingSchedule.amountOfGrant.sub(
                    vestingSchedule.amountClaimed
                );
        if (numberClaimCurrent == 0 && vestingSchedule.isClaimedTGE)
            return vestingInfo.amountTGE;
        if (numberClaimCurrent <= vestingSchedule.numberOfClaimed) return 0;
        return
            vestingSchedule.isClaimedTGE
                ? _calculatorAmountClaim(
                    numberClaimCurrent.sub(vestingSchedule.numberOfClaimed),
                    vestingInfo.numberOfClaims
                )
                : _calculatorAmountClaim(
                    numberClaimCurrent.sub(vestingSchedule.numberOfClaimed),
                    vestingInfo.numberOfClaims
                ).add(vestingInfo.amountTGE);
    }

    /**
     * @dev Return claimable amount
     */
    function _calculatorAmountClaim(
        uint256 _part,
        uint256 _distribution
    ) private view returns (uint256) {
        return amountVesting.mul(_part).div(_distribution);
    }

    /**
     * @dev Pre function to calculate What far it's been
     */
    function _getNumberofClaims() private view returns (uint256) {
        return (block.timestamp.sub(getPendingTimeLaunch())).div(ONE_TIME_UNLOCK);
    }

    /**
     * @dev Pre function to pending 5 minutes after launch
     */
    function getPendingTimeLaunch() private view returns (uint256) {
        return TIME_TOKEN_LAUNCH.add(_FIVE_MINUTES); // pending 5 minutes
    }

    function changeTimeLaunch(uint256 _time) external onlyOwner {
        TIME_TOKEN_LAUNCH = _time;
    }
}