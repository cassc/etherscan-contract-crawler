pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../reward/PeakReward.sol";
import "../PeakToken.sol";

contract PeakStaking {
    using SafeMath for uint256;
    using SafeERC20 for PeakToken;

    event CreateStake(
        uint256 idx,
        address user,
        address referrer,
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        uint256 interestAmount
    );
    event ReceiveStakeReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawStake(uint256 idx, address user);

    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant PEAK_PRECISION = 10**8;
    uint256 internal constant INTEREST_SLOPE = 2 * (10**8); // Interest rate factor drops to 0 at 5B mintedPeakTokens
    uint256 internal constant BIGGER_BONUS_DIVISOR = 10**15; // biggerBonus = stakeAmount / (10 million peak)
    uint256 internal constant MAX_BIGGER_BONUS = 10**17; // biggerBonus <= 10%
    uint256 internal constant DAILY_BASE_REWARD = 15 * (10**14); // dailyBaseReward = 0.0015
    uint256 internal constant DAILY_GROWING_REWARD = 10**12; // dailyGrowingReward = 1e-6
    uint256 internal constant MAX_STAKE_PERIOD = 1000; // Max staking time is 1000 days
    uint256 internal constant MIN_STAKE_PERIOD = 10; // Min staking time is 10 days
    uint256 internal constant DAY_IN_SECONDS = 86400;
    uint256 internal constant COMMISSION_RATE = 20 * (10**16); // 20%
    uint256 internal constant REFERRAL_STAKER_BONUS = 3 * (10**16); // 3%
    uint256 internal constant YEAR_IN_DAYS = 365;
    uint256 public constant PEAK_MINT_CAP = 7 * 10**16; // 700 million PEAK

    struct Stake {
        address staker;
        uint256 stakeAmount;
        uint256 interestAmount;
        uint256 withdrawnInterestAmount;
        uint256 stakeTimestamp;
        uint256 stakeTimeInDays;
        bool active;
    }
    Stake[] public stakeList;
    mapping(address => uint256) public userStakeAmount;
    uint256 public mintedPeakTokens;
    bool public initialized;

    PeakToken public peakToken;
    PeakReward public peakReward;

    constructor(address _peakToken) public {
        peakToken = PeakToken(_peakToken);
    }

    function init(address _peakReward) public {
        require(!initialized, "PeakStaking: Already initialized");
        initialized = true;

        peakReward = PeakReward(_peakReward);
    }

    function stake(
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        address referrer
    ) public returns (uint256 stakeIdx) {
        require(
            stakeTimeInDays >= MIN_STAKE_PERIOD,
            "PeakStaking: stakeTimeInDays < MIN_STAKE_PERIOD"
        );
        require(
            stakeTimeInDays <= MAX_STAKE_PERIOD,
            "PeakStaking: stakeTimeInDays > MAX_STAKE_PERIOD"
        );

        // record stake
        uint256 interestAmount = getInterestAmount(
            stakeAmount,
            stakeTimeInDays
        );
        stakeIdx = stakeList.length;
        stakeList.push(
            Stake({
                staker: msg.sender,
                stakeAmount: stakeAmount,
                interestAmount: interestAmount,
                withdrawnInterestAmount: 0,
                stakeTimestamp: now,
                stakeTimeInDays: stakeTimeInDays,
                active: true
            })
        );
        mintedPeakTokens = mintedPeakTokens.add(interestAmount);
        userStakeAmount[msg.sender] = userStakeAmount[msg.sender].add(
            stakeAmount
        );

        // transfer PEAK from msg.sender
        peakToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        // mint PEAK interest
        peakToken.mint(address(this), interestAmount);

        // handle referral
        if (peakReward.canRefer(msg.sender, referrer)) {
            peakReward.refer(msg.sender, referrer);
        }
        address actualReferrer = peakReward.referrerOf(msg.sender);
        if (actualReferrer != address(0)) {
            // pay referral bonus to referrer
            uint256 rawCommission = interestAmount.mul(COMMISSION_RATE).div(
                PRECISION
            );
            peakToken.mint(address(this), rawCommission);
            peakToken.safeApprove(address(peakReward), rawCommission);
            uint256 leftoverAmount = peakReward.payCommission(
                actualReferrer,
                address(peakToken),
                rawCommission,
                true
            );
            peakToken.burn(leftoverAmount);

            // pay referral bonus to staker
            uint256 referralStakerBonus = interestAmount
                .mul(REFERRAL_STAKER_BONUS)
                .div(PRECISION);
            peakToken.mint(msg.sender, referralStakerBonus);

            mintedPeakTokens = mintedPeakTokens.add(
                rawCommission.sub(leftoverAmount).add(referralStakerBonus)
            );

            emit ReceiveStakeReward(stakeIdx, msg.sender, referralStakerBonus);
        }

        require(mintedPeakTokens <= PEAK_MINT_CAP, "PeakStaking: reached cap");

        emit CreateStake(
            stakeIdx,
            msg.sender,
            actualReferrer,
            stakeAmount,
            stakeTimeInDays,
            interestAmount
        );
    }

    function withdraw(uint256 stakeIdx) public {
        Stake storage stakeObj = stakeList[stakeIdx];
        require(
            stakeObj.staker == msg.sender,
            "PeakStaking: Sender not staker"
        );
        require(stakeObj.active, "PeakStaking: Not active");

        // calculate amount that can be withdrawn
        uint256 stakeTimeInSeconds = stakeObj.stakeTimeInDays.mul(
            DAY_IN_SECONDS
        );
        uint256 withdrawAmount;
        if (now >= stakeObj.stakeTimestamp.add(stakeTimeInSeconds)) {
            // matured, withdraw all
            withdrawAmount = stakeObj
                .stakeAmount
                .add(stakeObj.interestAmount)
                .sub(stakeObj.withdrawnInterestAmount);
            stakeObj.active = false;
            stakeObj.withdrawnInterestAmount = stakeObj.interestAmount;
            userStakeAmount[msg.sender] = userStakeAmount[msg.sender].sub(
                stakeObj.stakeAmount
            );

            emit WithdrawReward(
                stakeIdx,
                msg.sender,
                stakeObj.interestAmount.sub(stakeObj.withdrawnInterestAmount)
            );
            emit WithdrawStake(stakeIdx, msg.sender);
        } else {
            // not mature, partial withdraw
            withdrawAmount = stakeObj
                .interestAmount
                .mul(uint256(now).sub(stakeObj.stakeTimestamp))
                .div(stakeTimeInSeconds)
                .sub(stakeObj.withdrawnInterestAmount);

            // record withdrawal
            stakeObj.withdrawnInterestAmount = stakeObj
                .withdrawnInterestAmount
                .add(withdrawAmount);

            emit WithdrawReward(stakeIdx, msg.sender, withdrawAmount);
        }

        // withdraw interest to sender
        peakToken.safeTransfer(msg.sender, withdrawAmount);
    }

    function getInterestAmount(uint256 stakeAmount, uint256 stakeTimeInDays)
        public
        view
        returns (uint256)
    {
        uint256 earlyFactor = _earlyFactor(mintedPeakTokens);
        uint256 biggerBonus = stakeAmount.mul(PRECISION).div(
            BIGGER_BONUS_DIVISOR
        );
        if (biggerBonus > MAX_BIGGER_BONUS) {
            biggerBonus = MAX_BIGGER_BONUS;
        }

        // convert yearly bigger bonus to stake time
        biggerBonus = biggerBonus.mul(stakeTimeInDays).div(YEAR_IN_DAYS);

        uint256 longerBonus = _longerBonus(stakeTimeInDays);
        uint256 interestRate = biggerBonus.add(longerBonus).mul(earlyFactor).div(
            PRECISION
        );
        uint256 interestAmount = stakeAmount.mul(interestRate).div(PRECISION);
        return interestAmount;
    }

    function _longerBonus(uint256 stakeTimeInDays)
        internal
        pure
        returns (uint256)
    {
        return
            DAILY_BASE_REWARD.mul(stakeTimeInDays).add(
                DAILY_GROWING_REWARD
                    .mul(stakeTimeInDays)
                    .mul(stakeTimeInDays.add(1))
                    .div(2)
            );
    }

    function _earlyFactor(uint256 _mintedPeakTokens)
        internal
        pure
        returns (uint256)
    {
        uint256 tmp = INTEREST_SLOPE.mul(_mintedPeakTokens).div(PEAK_PRECISION);
        if (tmp > PRECISION) {
            return 0;
        }
        return PRECISION.sub(tmp);
    }
}