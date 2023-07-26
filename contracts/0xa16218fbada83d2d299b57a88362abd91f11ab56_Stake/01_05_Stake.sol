// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error NotOwner();
error BalanceLessThanAmount();
error StakingPeriodMismatch();
error ZeroAmount();
error ZeroAddress();
error StakingIdMismatch();
error StakeNotMature();
error StakeAlreadyMature();
error AlreadyClaimed();
error LengthMismatch();
error NonTransferable();
error StakeCompleted();
error NoRewardsToClaim();

contract Stake is ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdate(address indexed owner);
    event Withdraw(address indexed tokenAddress, uint256 balance);
    event AddInterestRate(uint8 period, uint96 rate);
    event AddgStfxMultiplier(uint8 period, uint32 multiplier);
    event UpdateBurnPercent(uint32 percent);
    event UpdateBurnAddress(address indexed burnAddress);
    event AddStake(
        address indexed staker, uint256 stakeNumber, uint96 amount, uint96 expiryAmount, uint40 expiryTime, uint8 period
    );
    event Unstake(address indexed staker, uint256[] stakeNumber, uint96 totalTransferAmount, uint96 totalBurnAmount);
    event Claim(
        address indexed staker, uint256[] stakeNumber, uint96 amount, uint96 expiryAmount, uint96 transferAmount
    );
    event ClaimRewards(address indexed staker, uint256[] stakeNumber, uint96 totalRewards);

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    struct StakingInfo {
        StakingPeriod period;
        uint40 startTime;
        uint40 expiryTime;
        uint96 amount;
        uint96 expiryAmount;
        uint96 claimedAmount;
        uint96 gStfxAmount;
        bool isCompleted;
    }

    enum StakingPeriod {
        MONTH, // 1 months - 30 days
        QUARTER, // 3 months - 90 days
        HALF, // 6 months - 180 days
        YEAR, // 1 year - 365 days
        TWO_YEAR // 2 years - 730 days
    }

    address public owner;

    address public token;

    uint32 public burnPercent;

    address public burnAddress;

    uint96 public totalStaked;

    uint96 public burntToDate;

    uint96 public rewardsToDate;

    mapping(address => StakingInfo[]) public stakingInfo;

    mapping(uint8 => uint96) public interestRate;

    mapping(uint8 => uint32) public gStfxMultiplier;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _token) ERC20("gSTFX", "gSTFX") {
        owner = msg.sender;
        token = _token;
        burnPercent = 20000; // 20%
        burnAddress = address(0x000000000000000000000000000000000000dEaD);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getNumberOfStakes(address staker) public view returns (uint256) {
        return stakingInfo[staker].length;
    }

    function getAllStakes(address staker) public view returns (StakingInfo[] memory) {
        uint256 length = stakingInfo[staker].length;
        StakingInfo[] memory allStakes = new StakingInfo[](length);
        for (uint256 i = 0; i < length;) {
            allStakes[i] = stakingInfo[staker][i];
            unchecked {
                ++i;
            }
        }
        return allStakes;
    }

    function getStakingInfo(address staker, uint256 n) public view returns (StakingInfo memory) {
        return stakingInfo[staker][n];
    }

    function getIsStakeMature(address staker, uint256 n) public view returns (bool isMature) {
        if (block.timestamp >= stakingInfo[staker][n].expiryTime) isMature = true;
    }

    function getStakeAmount(address staker, uint256[] memory n) public view returns (uint96 amount) {
        if (n.length > getNumberOfStakes(staker)) revert LengthMismatch();
        for (uint256 i = 0; i < n.length;) {
            StakingInfo memory s = stakingInfo[staker][n[i]];
            amount += s.amount;
            unchecked {
                ++i;
            }
        }
    }

    function getExpiryAmount(address staker, uint256[] memory n) public view returns (uint96 expiryAmount) {
        if (n.length > getNumberOfStakes(staker)) revert LengthMismatch();
        for (uint256 i = 0; i < n.length;) {
            StakingInfo memory s = stakingInfo[staker][n[i]];
            expiryAmount += s.expiryAmount;
            unchecked {
                ++i;
            }
        }
    }

    function getClaimedAmount(address staker, uint256[] memory n) public view returns (uint96 claimedAmount) {
        if (n.length > getNumberOfStakes(staker)) revert LengthMismatch();
        for (uint256 i = 0; i < n.length;) {
            StakingInfo memory s = stakingInfo[staker][n[i]];
            claimedAmount += s.claimedAmount;
            unchecked {
                ++i;
            }
        }
    }

    function getAccruedRewards(address staker, uint256[] memory n) public view returns (uint96 claimableAmount) {
        if (n.length > getNumberOfStakes(staker)) revert LengthMismatch();
        for (uint256 i = 0; i < n.length;) {
            StakingInfo memory s = stakingInfo[staker][n[i]];
            if (s.isCompleted) {
                claimableAmount += 0;
            } else {
                if (block.timestamp >= s.expiryTime) {
                    claimableAmount += uint96(s.expiryAmount - s.amount);
                } else {
                    claimableAmount += uint96(
                        ((s.expiryAmount - s.amount) * (block.timestamp - s.startTime)) / (s.expiryTime - s.startTime)
                    );
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function getBurnAmount(address staker, uint256[] memory n) public view returns (uint96 burnAmount) {
        if (n.length > getNumberOfStakes(staker)) revert LengthMismatch();
        for (uint256 i = 0; i < n.length;) {
            StakingInfo memory s = stakingInfo[staker][n[i]];
            if ((block.timestamp >= s.expiryTime) || s.isCompleted) {
                burnAmount += 0;
            } else {
                burnAmount += uint96(
                    (uint256(burnPercent) * s.amount * (s.expiryTime - block.timestamp))
                        / (uint256(s.expiryTime - s.startTime) * 100000)
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    function getAccruedRewardsPerStake(address staker, uint256 n) public view returns (uint96 claimableAmount) {
        StakingInfo memory s = stakingInfo[staker][n];
        if (s.isCompleted) {
            claimableAmount = 0;
        } else {
            if (block.timestamp >= s.expiryTime) {
                claimableAmount = uint96(s.expiryAmount - s.amount);
            } else {
                claimableAmount = uint96(
                    ((s.expiryAmount - s.amount) * (block.timestamp - s.startTime)) / (s.expiryTime - s.startTime)
                );
            }
        }
    }

    function getBurnAmountPerStake(address staker, uint256 n) public view returns (uint96 burnAmount) {
        StakingInfo memory s = stakingInfo[staker][n];
        if ((block.timestamp >= s.expiryTime) || s.isCompleted) {
            burnAmount = 0;
        } else {
            burnAmount = uint96(
                (uint256(burnPercent) * s.amount * (s.expiryTime - block.timestamp))
                    / (uint256(s.expiryTime - s.startTime) * 100000)
            );
        }
    }

    function getStats() public view returns (uint96, uint96, uint96) {
        return (totalStaked, rewardsToDate, burntToDate);
    }

    function getStatsPerStaker(address staker)
        public
        view
        returns (uint96 amount, uint96 expiryAmount, uint96 claimedAmount, uint96 accruedRewards)
    {
        uint256 length = getNumberOfStakes(staker);
        for (uint256 i = 0; i < length;) {
            StakingInfo memory s = stakingInfo[staker][i];
            amount += s.amount;
            expiryAmount += s.expiryAmount;
            claimedAmount += s.claimedAmount;
            accruedRewards += getAccruedRewardsPerStake(staker, i);
            unchecked {
                ++i;
            }
        }
    }

    function getIdsForClaimRewards(address staker) public view returns (uint256[] memory n) {
        uint256 length = getNumberOfStakes(staker);
        for (uint256 i = 0; i < length;) {
            StakingInfo memory s = stakingInfo[staker][i];
            if (!s.isCompleted && (block.timestamp < s.expiryTime)) {
                assembly {
                    let currentLength := mload(n)
                    mstore(n, add(currentLength, 1))
                    mstore(add(n, mul(add(currentLength, 1), 32)), i)
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        owner = newOwner;
        emit OwnerUpdate(newOwner);
    }

    function addInterestRate(StakingPeriod period, uint96 rate) external onlyOwner {
        if (rate < 1) revert ZeroAmount();
        interestRate[uint8(period)] = rate;
        emit AddInterestRate(uint8(period), rate);
    }

    function addgStfxMultiplier(StakingPeriod period, uint32 multiplier) external onlyOwner {
        if (multiplier < 1) revert ZeroAmount();
        gStfxMultiplier[uint8(period)] = multiplier;
        emit AddgStfxMultiplier(uint8(period), multiplier);
    }

    function updateBurnPercent(uint32 percent) external onlyOwner {
        if (percent < 1) revert ZeroAmount();
        burnPercent = percent;
        emit UpdateBurnPercent(percent);
    }

    function updateBurnAddress(address burn) external onlyOwner {
        burnAddress = burn;
        emit UpdateBurnAddress(burn);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _setStakingPeriod(StakingPeriod period) internal view returns (uint40 expiryTime) {
        if (period == StakingPeriod.MONTH) {
            expiryTime = uint40(block.timestamp + 30 days);
        } else if (period == StakingPeriod.QUARTER) {
            expiryTime = uint40(block.timestamp + 90 days);
        } else if (period == StakingPeriod.HALF) {
            expiryTime = uint40(block.timestamp + 180 days);
        } else if (period == StakingPeriod.YEAR) {
            expiryTime = uint40(block.timestamp + 365 days);
        } else if (period == StakingPeriod.TWO_YEAR) {
            expiryTime = uint40(block.timestamp + 730 days);
        } else {
            revert StakingPeriodMismatch();
        }
    }

    function _stake(uint96 amount, StakingPeriod period) internal view returns (StakingInfo memory s) {
        s.startTime = uint40(block.timestamp);
        s.amount = amount;
        s.expiryAmount = uint96(((uint256(amount) * uint256(interestRate[uint8(period)])) / 100e18) + uint256(amount));
        s.period = period;
        s.expiryTime = _setStakingPeriod(period);
        s.gStfxAmount = uint96((uint256(gStfxMultiplier[uint8(period)]) * uint256(s.amount)) / 1000);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice add a stake with the input amount for the address calling this function
    /// @dev approve has to be called before calling this function
    /// @param amount the amount of tokens the staker wants to stake
    /// @param period the time period from the enum
    function stake(uint96 amount, StakingPeriod period) external {
        if (IERC20(token).balanceOf(msg.sender) < amount) revert BalanceLessThanAmount();
        if (interestRate[uint8(period)] == 0) revert StakingPeriodMismatch();

        StakingInfo memory s = _stake(amount, period);
        stakingInfo[msg.sender].push(s);
        totalStaked += amount;
        uint256 length = stakingInfo[msg.sender].length;

        _mint(msg.sender, s.gStfxAmount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit AddStake(msg.sender, length - 1, amount, s.expiryAmount, s.expiryTime, uint8(period));
    }

    /// @notice restakes the initial amount with the rewards accrued till now and restakes it for the new time period
    /// @dev the new period has to be more than the existing stake period
    /// @param n the id of the stake
    /// @param period the new period of the stake which can only be more than the existing stake
    function restake(uint256 n, StakingPeriod period) external {
        uint256 length = getNumberOfStakes(msg.sender);
        if (n >= length) revert StakingIdMismatch();

        StakingInfo memory s = getStakingInfo(msg.sender, n);
        if (block.timestamp >= s.expiryTime) revert StakeAlreadyMature();
        if (uint8(period) < uint8(s.period)) revert StakingPeriodMismatch();

        uint96 stakedRewardTillNow = getAccruedRewardsPerStake(msg.sender, n);
        StakingInfo memory sAfterRestake = _stake(s.amount + (stakedRewardTillNow - s.claimedAmount), period);
        stakingInfo[msg.sender][n] = sAfterRestake;
        totalStaked += stakedRewardTillNow - s.claimedAmount;

        _mint(msg.sender, sAfterRestake.gStfxAmount - s.gStfxAmount);

        emit AddStake(
            msg.sender,
            n,
            sAfterRestake.amount,
            sAfterRestake.expiryAmount,
            sAfterRestake.expiryTime,
            uint8(sAfterRestake.period)
        );
    }

    /// @notice unstakes prematurely and transfers `amount + rewards - burnAmount` to the staker
    /// @dev burns `burnPercent` of the remaining amount of stake
    /// @param n array of all the staking ids
    function unstake(uint256[] memory n) external {
        uint256 length = getNumberOfStakes(msg.sender);
        if (n.length > length) revert LengthMismatch();

        uint96 totalRewards;
        uint96 totalTransferAmount;
        uint96 totalBurnAmount;
        uint96 gStfxToBurn;

        for (uint256 i = 0; i < n.length;) {
            if (n[i] >= length) revert StakingIdMismatch();

            StakingInfo memory s = getStakingInfo(msg.sender, n[i]);
            if (block.timestamp >= s.expiryTime) revert StakeAlreadyMature();
            if (s.isCompleted) revert StakeCompleted();

            uint96 accruedRewards = getAccruedRewardsPerStake(msg.sender, n[i]);
            uint96 burnAmount = getBurnAmountPerStake(msg.sender, n[i]);

            totalRewards += accruedRewards - s.claimedAmount;
            totalTransferAmount += (s.amount - burnAmount) + (accruedRewards - s.claimedAmount);
            totalBurnAmount += burnAmount;
            gStfxToBurn += s.gStfxAmount;
            stakingInfo[msg.sender][n[i]].claimedAmount = accruedRewards;
            stakingInfo[msg.sender][n[i]].isCompleted = true;

            unchecked {
                ++i;
            }
        }

        rewardsToDate += totalRewards;
        burntToDate += totalBurnAmount;
        _burn(msg.sender, gStfxToBurn);
        IERC20(token).transfer(msg.sender, totalTransferAmount);
        IERC20(token).transfer(burnAddress, totalBurnAmount);

        emit Unstake(msg.sender, n, totalTransferAmount, totalBurnAmount);
    }

    /// @notice transfers the initial amount with the remaining rewards after the stake matures to the staker
    /// @dev can be called after all the stakes in the array are matured
    /// @param n array of the staking ids
    function claim(uint256[] memory n) external {
        uint96 totalStakeAmount;
        uint96 totalExpiryAmount;
        uint96 transferAmount;
        uint96 gStfxToBurn;
        uint96 totalRewardsToDate;
        uint256 length = getNumberOfStakes(msg.sender);
        if (n.length > length) revert LengthMismatch();

        for (uint256 i = 0; i < n.length;) {
            if (n[i] >= length) revert StakingIdMismatch();

            StakingInfo memory s = getStakingInfo(msg.sender, n[i]);
            if (block.timestamp < s.expiryTime) revert StakeNotMature();
            if (s.isCompleted) revert StakeCompleted();

            totalStakeAmount += s.amount;
            totalExpiryAmount += s.expiryAmount;
            transferAmount += s.expiryAmount - s.claimedAmount;
            totalRewardsToDate += s.expiryAmount - s.amount - s.claimedAmount;
            gStfxToBurn += s.gStfxAmount;
            stakingInfo[msg.sender][n[i]].claimedAmount = s.expiryAmount - s.amount;
            stakingInfo[msg.sender][n[i]].isCompleted = true;

            unchecked {
                ++i;
            }
        }

        rewardsToDate += totalRewardsToDate;
        _burn(msg.sender, gStfxToBurn);
        IERC20(token).transfer(msg.sender, transferAmount);

        emit Claim(msg.sender, n, totalStakeAmount, totalExpiryAmount, transferAmount);
    }

    /// @notice transfers all the eligible rewards of all the stakes in the array to the staker
    /// @param n array of the staking ids
    function claimRewards(uint256[] memory n) external {
        uint256 length = getNumberOfStakes(msg.sender);
        if (n.length > length) revert LengthMismatch();

        uint96 transferAmount;

        for (uint256 i = 0; i < n.length;) {
            if (n[i] >= length) revert StakingIdMismatch();

            StakingInfo memory s = getStakingInfo(msg.sender, n[i]);
            uint96 claimableAmount = getAccruedRewardsPerStake(msg.sender, n[i]);
            if ((s.claimedAmount < claimableAmount) && !s.isCompleted) {
                uint96 claimedAmountTillNow = s.claimedAmount;
                transferAmount += claimableAmount - claimedAmountTillNow;
                stakingInfo[msg.sender][n[i]].claimedAmount = claimableAmount;
            }

            unchecked {
                ++i;
            }
        }

        if (transferAmount == 0) revert NoRewardsToClaim();
        rewardsToDate += transferAmount;
        IERC20(token).transfer(msg.sender, transferAmount);

        emit ClaimRewards(msg.sender, n, transferAmount);
    }

    function withdraw(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(owner, balance);
        emit Withdraw(tokenAddress, balance);
    }

    /*//////////////////////////////////////////////////////////////
                                ERC20
    //////////////////////////////////////////////////////////////*/

    function approve(address, uint256) public virtual override returns (bool) {
        revert NonTransferable();
    }

    function transfer(address, uint256) public virtual override returns (bool) {
        revert NonTransferable();
    }

    function transferFrom(address, address, uint256) public virtual override returns (bool) {
        revert NonTransferable();
    }
}