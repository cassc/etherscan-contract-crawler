// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//* ================ IMPORTS ================ *//

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IStaking.sol";

contract Staking is Ownable, ReentrancyGuard {
    //* ========== STATE PUBLIC VARIABLES ========== *//

    IERC20 public rewardToken; //?REWARD TOKEN ADDRESS
    IERC20 public stakingToken; //?LP TOKEN ADDRESS
    uint256 public allStakedBalance; //? ALL STAKE BALANCE OF CONTRACT
    uint256 public startStakeTimestamp; //?TIMESTAMP STAKE START
    uint256 public startWitdrawTimestamp; //?TIMESTAMP WITDRAW START
    uint256 public endStakeTimestamp; //?TIMESTAMP STAKE END
    uint256 public endWitdrawTimestamp; //?TIMESTAMP WITDRAW END
    uint256 public duration;
    uint256 public StakedReward; //?REWARD OF THIS MONTH
    uint256[] public allStakedBalances; //?ALL STAKES BALANCES FROM BEGINNING
    uint256[] public allRewards; //?ALL REWARDS FROM BEGINNING
    address[] public stakers;
    mapping(address => uint32) public stakedTime; //?WHENE THE USER DID STAKE
    mapping(address => uint256) public stakedBalance; //? BALANCE OF EACH PERSON IN CONTRACT
    //* ========== STATE PRIVATE VARIABLES ========== *//
    bool private timeSet = false; //?BOOLEAN FOR SET THE TIME
    uint32 private stakeTimes; //?HOW MANY STAKE TIMES ARE SET
    uint32 private witdrawTimes; //?HOW MANY WITDRAW TIMES ARE SET
    mapping(address => uint256) private stakedBalanceCopy; //?A COPY FOR stakedBalance ;

    //* ================= EVENTS ================= *//
    event rewardAmount(address indexed user, uint256 reward);
    event Stake(address indexed user, uint256 amount, uint256 endTime);
    event Unstake(address indexed user, uint256 amountStaked, uint256 shares);
    event SetReward(address user, uint256 reward);

    //* ============== CONSTRUCTOR ============== *//
    constructor(address _stakingToken, address _rewardToken) {
        //! STAKING TOKEN HAS TO BE A PAIR ADDRESS
        stakingToken = IERC20(_stakingToken); //?LP TOKEN ADDRESS

        rewardToken = IERC20(_rewardToken); //? REWARD ROKEN ADDRESS
    }

    //* =============== MODIFIERS =============== *//
    modifier haveReward(address sender) {
        require(stakedTime[msg.sender] != 0, "you did not stake");
        require(
            stakedTime[sender] != witdrawTimes + 1,
            "You have already withdrawn your reward"
        );
        _;
    }
    modifier startStake() {
        require(
            block.timestamp >= startStakeTimestamp &&
                block.timestamp <= endStakeTimestamp,
            "you cant stake at this time"
        );

        _;
    }
    modifier zeroAmount(uint256 amount) {
        require(amount != 0, "zero amount");
        _;
    }
    modifier haveShares(address sender) {
        require(stakedBalance[sender] != 0, "you have no shares");

        _;
    }

    modifier startWitdraw(address sender) {
        require(
            block.timestamp >= startWitdrawTimestamp &&
                block.timestamp <= endWitdrawTimestamp,
            "you cant witdraw at this time"
        );

        _;
    }

    //* ============== SEND METHODS ============== *//

    function stake(uint256 _amount)
        external
        nonReentrant
        startStake
        zeroAmount(_amount)
    {
        require(
            stakedBalance[msg.sender] == 0,
            "you have already staked amount"
        );

        stakedTime[msg.sender] = witdrawTimes + 1;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        addStaker(_amount, msg.sender);
        stakedBalance[msg.sender] += _amount;

        stakedBalanceCopy[msg.sender] = stakedBalance[msg.sender];
        allStakedBalance += _amount;
    }

    function unstake()
        external
        nonReentrant
        startWitdraw(msg.sender)
        haveShares(msg.sender)
    {
        uint256 deposited = stakedBalance[msg.sender];
        (, uint256 reward) = _getReward(msg.sender);
        require(reward == 0, "you have to get your reward first");

        stakedBalance[msg.sender] = 0;
        stakedTime[msg.sender] = 0;
        removeStaker(msg.sender);
        uint256 shares = calculate(deposited, allStakedBalance);
        allStakedBalance -= deposited;

        emit Unstake(msg.sender, deposited, shares);
        stakingToken.transfer(msg.sender, deposited);
    }

    function getReward(address sender)
        external
        nonReentrant
        haveReward(msg.sender)
        returns (uint256 reward)
    {
        require(sender == msg.sender);

        (, reward) = _getReward(sender);
        require(reward != 0, "no reward to recieve");
        stakedTime[sender] = witdrawTimes + 1;

        rewardToken.transfer(sender, reward);
        emit rewardAmount(sender, reward);
    }

    function setReward(uint256 _reward) external onlyOwner {
        require(_reward > 0, "Cannot setReward 0");

        rewardToken.transferFrom(msg.sender, address(this), _reward + 3000);
        StakedReward = _reward;
        emit SetReward(msg.sender, _reward);
    }

    function addReward(uint256 _reward) external onlyOwner {
        require(_reward > 0, "Cannot setReward 0");

        rewardToken.transferFrom(msg.sender, address(this), _reward);
        StakedReward += _reward;

        emit SetReward(msg.sender, _reward);
    }

    function setStake() external onlyOwner {
        require(
            !timeSet,
            "you can't set stake until witdraw is still going on "
        );
        startWitdrawTimestamp = 0;
        endWitdrawTimestamp = 0;
        startStakeTimestamp = block.timestamp;
        endStakeTimestamp = block.timestamp + 24 hours;
        stakeTimes++;

        timeSet = true;
    }

    function setWitdraw() external onlyOwner {
        require(timeSet, "you can't set witdraw until stake is still going on");
        startStakeTimestamp = 0;
        endStakeTimestamp = 0;
        witdrawTimes++;
        allRewards.push(StakedReward);
        allStakedBalances.push(allStakedBalance);
        StakedReward = 0;
        timeSet = false;
        startWitdrawTimestamp = block.timestamp;
        endWitdrawTimestamp = block.timestamp + 24 hours;
    }

    function witdrawOwnerLP(uint256 amount)
        external
        onlyOwner
        zeroAmount(amount)
    {
        stakingToken.transfer(owner(), amount);
    }

    function witdrawOwnerReward(uint256 amount)
        external
        onlyOwner
        zeroAmount(amount)
    {
        require(amount < rewardToken.balanceOf(address(this)) - 3000);
        rewardToken.transfer(owner(), amount);
    }

    function setDuration(uint256 timestamp) external onlyOwner {
        duration = timestamp;
    }

    //* ============== INTERNAL METHODS ============== *//

    function removeStaker(address sender) internal {
        uint256 index = findIndex(sender) - 1;
        for (uint256 i = index; i < stakers.length - 1; i++) {
            stakers[i] = stakers[i + 1];
        }
        stakers.pop();
    }

    function addStaker(uint256 _amount, address sender) internal {
        uint256 len = stakers.length;
        uint256 index = len;
        if (len != 0) {
            for (uint256 i = 0; i < len; ) {
                uint256 stakerShare = stakedBalance[stakers[i]];
                if (_amount > stakerShare) {
                    index = i;
                    break;
                }
                unchecked {
                    i++;
                }
            }
            stakers.push(stakers[len - 1]);
            for (uint256 j = len - 1; j > index; ) {
                stakers[j] = stakers[j - 1];

                unchecked {
                    j--;
                }
            }
            stakers[index] = sender;
        } else stakers.push(sender);
    }

    //* ============== CALL METHODS ============== *//
    function topTen()
        external
        view
        returns (address[] memory TopTen, uint256[] memory TopTenAmount)
    {
        uint256 len = stakers.length;
        if (len > 10) {
            len = 10;
        }
        TopTen = new address[](len);
        TopTenAmount = new uint256[](len);
        for (uint256 i = 0; i < stakers.length; ) {
            TopTen[i] = stakers[i];
            TopTenAmount[i] = stakedBalance[stakers[i]];
            if (i == len - 1) {
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    function findIndex(address sender) public view returns (uint256) {
        for (uint256 i = 0; i <= stakers.length; i++) {
            if (stakers[i] == sender) {
                return i + 1;
            }
        }
        return 0;
    }

    function _getReward(address sender)
        public
        view
        returns (uint256 commingReward, uint256 reward)
    {
        uint256 percentShares;
        if (witdrawTimes >= stakedTime[sender]) {
            for (uint256 i = stakedTime[sender]; i <= witdrawTimes; i++) {
                percentShares = calculate(
                    stakedBalanceCopy[sender],
                    allStakedBalances[i - 1]
                );

                reward += Math.ceilDiv(
                    (percentShares * allRewards[i - 1]),
                    100 * 10**18
                );
            }

            if (reward > 0) commingReward = 0;
        }

        if (StakedReward != 0 && commingReward == 0) {
            percentShares = calculate(
                stakedBalanceCopy[sender],
                allStakedBalance
            );
            commingReward =
                Math.ceilDiv((percentShares * StakedReward), 100 * 10**18) +
                reward;
        }
    }

    function calculate(uint256 deposited, uint256 Balance)
        public
        pure
        returns (uint256 percentShares)
    {
        uint256 div = 100 * 10**18;
        percentShares = Math.ceilDiv(deposited * div, Balance);
    }

    function percentageShare(address _sender) public view returns (uint256) {
        uint256 deposited = stakedBalance[_sender];
        return calculate(deposited, allStakedBalance);
    }

    function getAll(address sender)
        public
        view
        returns (
            uint256 percentShares,
            uint256 shares,
            uint256 reward
        )
    {
        percentShares = percentageShare(sender);
        shares = stakedBalance[sender];
        (uint256 commingReward, uint256 reward_) = _getReward(sender);

        if (reward != 0) reward = reward_;
        else reward = commingReward;
    }

    function isStartedStake() public view returns (bool start) {
        start = false;
        if (
            block.timestamp >= startStakeTimestamp &&
            block.timestamp <= endStakeTimestamp
        ) start = true;
    }

    function isStartedWitdraw() public view returns (bool start) {
        start = false;
        if (
            block.timestamp >= startWitdrawTimestamp &&
            block.timestamp <= endWitdrawTimestamp
        ) start = true;
    }
}