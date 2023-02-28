// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../token/MyShare.sol";


/**
 * @title The magical MyStaking contract.
 * @author int(200/0), slidingpanda
 */
contract MyStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct User {
        uint256 stakeBegin;
        uint256 share;
        uint256 lastRewardsPerShare;
        uint256 unclaimedAmount;
    }

    mapping(address => User) public userInfo;

    MyShare public myShare;

    uint256 public constant PERIOD0 = 86400; // 1 day
    uint256 public constant PERIOD1 = 7 * PERIOD0; // 1 week
    uint256 public constant PERIOD2 = 2 * PERIOD1; // 2 weeks
    uint256 public constant PERIOD3 = 2 * PERIOD2; // 4 weeks
    uint256 public constant PERIOD4 = 2 * PERIOD3; // 8 weeks

    uint256 public lpPeriod0Fee = 10;
    uint256 public lpPeriod1Fee = 20;
    uint256 public lpPeriod2Fee = 30;
    uint256 public lpPeriod3Fee = 20;
    uint256 public lpPeriod4Fee = 10;
    uint256 public lpStandardFee = 5;

    uint256 public period0Divisor = 6;
    uint256 public period1Divisor = 5;
    uint256 public period2Divisor = 4;
    uint256 public period3Divisor = 3;
    uint256 public period4Divisor = 2;
    uint256 public period5Divisor = 1;

    address public stakeToken;

    uint256 public totalShares;
    uint256 constant SHARE_DIVISOR = 10**6;

    uint256 public lastEmission;
    uint256 private _rewardsPerShare;
    uint256 private _rewardsPerShareResidual;

    uint256 public stakerCount;

    bool public isActive;

    /**
     * Creates the staking contract.
	 * Needs the myShare token which is able to mint rewards and the token which will be staked.
	 *
     * @param myShareAddr myShare token address.
     * @param lpAddr To-stake token address
     */
    constructor(address myShareAddr, address lpAddr, address owner_) {
        myShare = MyShare(myShareAddr);
        stakeToken = lpAddr;
        transferOwnership(owner_);
    }

    /**
     * Activates/Deactivates the staking pool if there are more than 0 tokens staked.
	 * Otherwise there is no need to emit or calculate the emission.
	 *
     * @notice - There also is an activity flag in the myShare token
	 *         - If there are some shares and this contract is active, it will activate the minter/emission for this contract as a minter
     *         - Otherwise it will deactivate the minter/emission for this contract as a minter
     */
    function _setActivity() internal {
        if (myShare.isMinter(address(this))) {
            if (totalShares > 0) {
                myShare.setMinterActivity(address(this), isActive);
            } else {
                myShare.setMinterActivity(address(this), false);
            }
        }
    }

    /**
     * Activates/Deactives this contract.
	 * If there already are shares, it activates the minter/emission for this contract as a minter.
	 *
     * @param toSet determines if address should be whitelisted
     */
    function setActivity(bool toSet) external onlyOwner {
        updateRewards();
        isActive = toSet;
        _setActivity();
    }

    /**
     * Calculates the uncalculated rewards.
     * - 1) The rewards of the myShare tokens -> minter/emission = X
     * - 2) The rewards for the staker depending on X -> X/shares
	 *
	 * @notice example (the same happens on the myShare contract):
     *         - (R)ewards = 1002, (S)hares = 10 -> (R+Residual)/S = RPS
     *         - (R)ewards(P)er(S)hare = 100
     *         - (Residual) = 2
	 *
     * @return uncalculatedRewardsPerShare returns the actual calculated rewards
     * @return uncalculatedResidual returns the residual which is not calculated but will be calculated in the next time
     */
    function getUncalculated() public view returns (uint256 uncalculatedRewardsPerShare, uint256 uncalculatedResidual) {
        uint256 tempLastEmission;

        if (myShare.isActiveMinter(address(this)) == true) {
            tempLastEmission = myShare.emissionPerSecondPerMinter() + myShare.uncalculatedEmission() - lastEmission;
        } else {
            tempLastEmission = 0;
        }

        if (totalShares > 0) {
            uint256 tempSum = tempLastEmission + _rewardsPerShareResidual;
            uncalculatedRewardsPerShare = tempSum / totalShares;
            uncalculatedResidual = tempSum % totalShares;
        }
    }

    /**
     * Changes the state of the contract on the chain based on the return values of "getUncalculated()".
     */
    function updateRewards() public {
        myShare.updateEmission();
        (uint256 rps, uint256 rpsr) = getUncalculated();

        lastEmission = myShare.emissionPerSecondPerMinter();
        _rewardsPerShareResidual = rpsr;
        _rewardsPerShare += rps;
    }

    /**
     * Changes the start time of a staker to the actual time.
	 * This takes care of that stakers have the correct fees when they withdraw or claim.
     */
    function _setTimer() internal {
        userInfo[msg.sender].stakeBegin = block.timestamp;
    }

    /**
     * Returns the lp withdraw fees, the divisor of the earned rewards and the staked time.
	 *
     * @notice claim:
     *         - 1 Day -> rewards / 6
     *         - <7 Days -> rewards / 5
     *         - <14 Days -> rewards / 4
     *         - <28 Days -> rewards / 3
     *         - <56 Days -> rewards / 2
     *         - >56 Days -> rewards / 1
     *         withdraw:
     *         - 1 Day -> 1%
     *         - <7 Days -> 2%
     *         - <14 Days -> 3%
     *         - <28 Days -> 2%
     *         - <56 Days -> 1%
     *         - >56 Days -> 0.5%
	 *
     * @param user address
     * @return lpFeeMultiplier lp/withdraw fee multiplier
     * @return rewardDivisor claim/reward divisor
     * @return stakedTime already staked time
     */
    function getDivisorByTime(address user) public view returns (uint256 lpFeeMultiplier, uint256 rewardDivisor, uint256 stakedTime) {
        stakedTime = block.timestamp - userInfo[user].stakeBegin;
        lpFeeMultiplier = lpStandardFee;
        rewardDivisor = period5Divisor;

        if (stakedTime < PERIOD0) {
            lpFeeMultiplier = lpPeriod0Fee;
            rewardDivisor = period0Divisor;
        } else if (stakedTime >= PERIOD0 && stakedTime < PERIOD1) {
            lpFeeMultiplier = lpPeriod1Fee;
            rewardDivisor = period1Divisor;
        } else if (stakedTime >= PERIOD1 && stakedTime < PERIOD2) {
            lpFeeMultiplier = lpPeriod2Fee;
            rewardDivisor = period2Divisor;
        } else if (stakedTime >= PERIOD2 && stakedTime < PERIOD3) {
            lpFeeMultiplier = lpPeriod3Fee;
            rewardDivisor = period3Divisor;
        } else if (stakedTime >= PERIOD3 && stakedTime < PERIOD4) {
            lpFeeMultiplier = lpPeriod4Fee;
            rewardDivisor = period4Divisor;
        }
    }

    /**
     * Stakes the stakeable tokens.
	 *
     * @notice - The amount will be divided by 10**6 to have a better possibility to divide the rewards
	 *         - It is not possible to stake an amount which has a residual of 10**6
	 *
     * @param amount stakeable tokens
     */
    function stake(uint256 amount) external nonReentrant {
        require(isActive == true, "This pool is not active");

        uint256 amountWithoutResidual = amount - (amount % SHARE_DIVISOR);

        require(amountWithoutResidual > 0, "Too small amount");

        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amountWithoutResidual);
        _stake(amountWithoutResidual);
    }

    /**
     * After the Transfer of the stakable Tokens happend, the needed flags for the staker are set.
	 *
	 * @param amount stakeable tokens
     */
    function _stake(uint256 amount) internal {
        if (userInfo[msg.sender].share == 0) {
            stakerCount += 1;
        }
        
        updateRewards();

        uint256 shareAmount = amount / SHARE_DIVISOR;

        (uint256 tempUnclaimed, ) = claimableAmount(msg.sender);
        userInfo[msg.sender].unclaimedAmount = tempUnclaimed;
        userInfo[msg.sender].lastRewardsPerShare = _rewardsPerShare;
        userInfo[msg.sender].share += shareAmount;
        userInfo[msg.sender].stakeBegin = block.timestamp;

        totalShares += shareAmount;

        // the emission will be activated only if there is a staker
        _setActivity();
    }

    /**
     * Calculates the actual claimable amount.
     * Counts the rewards per seconds from the last update plus the uncalculated (not updated) rewards minus the last user update.
     * It multiplies them with the share amount of the user.
     * Plus the unclaimed amount of the user which may happen when the user stakes more than one time without redeeming.
     * Divides the possible claimable amount by the claim divisor.
	 *
     * @notice claim:
     *         - 1 Day -> rewards / 6
     *         - <7 Days -> rewards / 5
     *         - <14 Days -> rewards / 4
     *         - <28 Days -> rewards / 3
     *         - <56 Days -> rewards / 2
     *         - >56 Days -> rewards / 1
     *         withdraw:
     *         - 1 Day -> 1%
     *         - <7 Days -> 2%
     *         - <14 Days -> 3%
     *         - <28 Days -> 2%
     *         - <56 Days -> 1%
     *         - >56 Days -> 0.5%
	 *
     * @param user address
     * @return claimable claimable amount without factoring in the claim fee
     * @return claimableAfterFee claimable amount with factoring in the claim fee
     */
    function claimableAmount(address user) public view returns (uint256 claimable, uint256 claimableAfterFee) {
        (uint256 uncalculatedRewardsPerShare, ) = getUncalculated();
        uint256 claimablePerShare = _rewardsPerShare + uncalculatedRewardsPerShare - userInfo[user].lastRewardsPerShare;

        claimable = claimablePerShare * userInfo[user].share;
        claimable += userInfo[user].unclaimedAmount;

        (, uint256 rewardFee, ) = getDivisorByTime(user);
        claimableAfterFee = claimable / rewardFee;
    }

    /**
     * Updates the actual rewards and sends the claimable amount to the caller.
     */
    function claim() external nonReentrant {
        updateRewards();
        _claim();
    }

    /**
     * Sends the claimable amount to the caller.
     */
    function _claim() internal {
        (uint256 claimable, uint256 claimableAfterFee) = claimableAmount(msg.sender);

        myShare.mint(msg.sender, claimableAfterFee, claimable - claimableAfterFee);

        userInfo[msg.sender].lastRewardsPerShare = _rewardsPerShare;
        userInfo[msg.sender].unclaimedAmount = 0;
    }

    /**
     * Sends all staked tokens to the message sender.
     */
    function _withdraw() internal {
        require(userInfo[msg.sender].share > 0, "You are not a staker.");
        
        uint256 wAmount = userInfo[msg.sender].share * SHARE_DIVISOR;
        (uint256 withdrawFee, ,) = getDivisorByTime(msg.sender);

        uint256 fee = (wAmount * withdrawFee) / 1000;
        uint256 roundedAmountAfterFee = wAmount - fee;

        IERC20(stakeToken).safeTransfer(msg.sender, roundedAmountAfterFee);
        IERC20(stakeToken).safeTransfer(address(1), fee);

        totalShares -= userInfo[msg.sender].share;
        userInfo[msg.sender].share = 0;

        stakerCount -= 1;
        _setActivity();
    }

    /**
     * Claims all rewards and unstakes the staked tokens.
     */
    function redeem() public nonReentrant {
        updateRewards();

        _claim();
        _withdraw();
        _setTimer();
    }

    /**
     * Redeems without claiming (if a minter is removed and there are still lp tokens staked)
     */
    function emergencyRedeemWithOutClaim() public nonReentrant {
        _withdraw();
        _setTimer();
    }

    /**
     * Gives the owner the possibility to withdraw tokens which are airdroped or send by mistake to this contract, except the staked tokens.
	 *
     * @param to recipient of the tokens
     * @param tokenAddr token contract
     */
    function daoWithdrawERC(address to, address tokenAddr) external onlyOwner {
        require(tokenAddr != stakeToken,"You cannot withdraw the staked tokens");

        IERC20(tokenAddr).safeTransfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
	 *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external onlyOwner {
        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }
}