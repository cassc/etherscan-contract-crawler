// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../token/UpgradableDiversify_V1.sol';
import '../utils/RetrieveTokensFeature.sol';

/**
 * @author  Diversify.io
 * @title   Staking contract
 * @notice  Changeable APY and no Lockings
 */
contract Staking is Ownable, RetrieveTokensFeature {
    // ERC20 basic token contract. Reward and Staking Token.
    UpgradableDiversify_V1 private _token;

    //Total supply of tokens to reward users
    uint256 private _totalSupplyReward;
    //Total tokens in stake
    uint256 private _totalStakedTokens;

    //Timestamps where the rate changes
    uint256[] private _rateTimestamps;

    //Record of APYs with two decimal places. 100% corresponds 10000
    uint256[] private _rateValues;

    //Staked Amount of each user
    mapping(address => uint256) private _stakedAmount;
    //Timestamp of the last stake / compound
    mapping(address => uint256) private _timestampStake;

    //Events
    event contractFilled(uint256 amount);
    event tokensStaked(address indexed purchaser, uint256 amount);
    event tokensWithdrawn(address indexed purchaser, uint256 amount);
    event rateChanged(uint256 newRate);

    constructor(UpgradableDiversify_V1 token_, uint256 rewardRate_) {
        require(address(token_) != address(0), 'Token address can not be 0');
        _token = token_;
        _totalSupplyReward = 0;
        _totalStakedTokens = 0;
        _rateTimestamps.push(block.timestamp);
        _rateValues.push(rewardRate_);
    }

    /**
     * @return  UpgradableDiversify_V1 token address
     */
    function token() public view returns (UpgradableDiversify_V1) {
        return _token;
    }

    /**
     * @return  uint256  Contract supply of tokens to distribute
     */
    function totalSupplyReward() public view returns (uint256) {
        return _totalSupplyReward;
    }

    /**
     * @return  uint256  Total amount of tokens currently staked
     */
    function totalStakedTokens() public view returns (uint256) {
        return _totalStakedTokens;
    }

    /**
     * @return  uint256[]  Array of timestamps where rate changed
     */
    function rateTimestamps() public view returns (uint256[] memory) {
        return _rateTimestamps;
    }

    /**
     * @return  uint256[]  Array of rate values
     */
    function rateValues() public view returns (uint256[] memory) {
        return _rateValues;
    }

    /**
     * @return  uint256  Stake amount of user
     */
    function stakedAmount() public view returns (uint256) {
        return _stakedAmount[_msgSender()];
    }

    /**
     * @dev     This amount can only be withdrawn if the contract has enough tokens
     * @return  uint256  Possible current withdraw amount
     */
    function rewardAmount() public view returns (uint256) {
        return _stakedAmount[_msgSender()] + _calculateRewardTotal(block.timestamp);
    }

    /**
     * @return  uint256  Timestamp of last stake / compound
     */
    function timestampStake() public view returns (uint256) {
        return _timestampStake[_msgSender()];
    }

    /**
     * @notice  Fill contract with tokens to distribute
     * @param   amount  of tokens to fill contract
     */
    function fillContract(uint256 amount) public {
        require(amount > 0, 'Amount cant be zero');
        require(_token.allowance(_msgSender(), address(this)) >= amount, 'Insufficient allowance');
        _token.transferFrom(_msgSender(), address(this), amount);
        _totalSupplyReward += _calculateTokensReceived(amount);

        emit contractFilled(_calculateTokensReceived(amount));
    }

    /**
     * @notice  increses stake of caller
     * @dev     before calling this function, the allowance must be set
     * @param   amount  of tokens to stake
     */
    function stakeTokens(uint256 amount) public {
        require(amount > 0, 'Amount cant be zero');
        require(_token.allowance(_msgSender(), address(this)) >= amount, 'Insufficient allowance');
        _token.transferFrom(_msgSender(), address(this), amount);
        _totalStakedTokens += _calculateTokensReceived(amount);

        uint256 currentTimestamp = block.timestamp;
        _compound(currentTimestamp);
        _stakedAmount[_msgSender()] += _calculateTokensReceived(amount);
        _timestampStake[_msgSender()] = currentTimestamp;

        emit tokensStaked(_msgSender(), _calculateTokensReceived(amount));
    }

    /**
     * @notice  compound current stake. Can only be called every 10 minutes
     */
    function compound() public {
        require(_stakedAmount[_msgSender()] > 0, 'Caller stakes no tokens');
        require(block.timestamp - _timestampStake[_msgSender()] > 10 minutes, 'Compounding only every 10 minutes');
        _compound(block.timestamp);
    }

    /**
     * @notice  Withdraw staked tokens
     * @dev     If withdrawAmount is set to 0, all possible tokens get withdrawn
     * @param   withdrawAmount  the amount the stake wants to withdraw
     */
    function withdrawTokens(uint256 withdrawAmount) public {
        require(_stakedAmount[_msgSender()] > 0, 'No tokens to withdraw');
        require(_stakedAmount[_msgSender()] >= withdrawAmount, 'Not enough tokens to withdraw');
        _compound(block.timestamp);
        uint256 tokensToWithdraw = _stakedAmount[_msgSender()];
        if (withdrawAmount != 0) {
            tokensToWithdraw = withdrawAmount;
        }

        _stakedAmount[_msgSender()] = _stakedAmount[_msgSender()] - tokensToWithdraw;
        _token.transfer(_msgSender(), tokensToWithdraw);

        _totalStakedTokens -= tokensToWithdraw;

        emit tokensWithdrawn(_msgSender(), tokensToWithdraw);
    }

    // function withdrawTokens() public {
    //     require(_stakedAmount[_msgSender()] > 0, 'No tokens to withdraw');
    //     _compound(block.timestamp);
    //     uint256 tokensToWithdraw = _stakedAmount[_msgSender()];
    //     _stakedAmount[_msgSender()] = 0;
    //     _token.transfer(_msgSender(), tokensToWithdraw);

    //     _totalStakedTokens -= tokensToWithdraw;

    //     emit tokensWithdrawn(_msgSender(), tokensToWithdraw);
    // }

    /**
     * @dev     Rate can be changed only by owner
     * @param   newRate  new APY
     */
    function changeRate(uint256 newRate) public onlyOwner {
        _rateTimestamps.push(block.timestamp);
        _rateValues.push(newRate);

        emit rateChanged(newRate);
    }

    /**
     * @notice  retrieve either wrongly assigned tokens or leftover DIV
     * @param   to  address of recepient
     * @param   anotherToken  address of token to retrieve
     */
    function retrieveTokens(address to, address anotherToken) public override onlyOwner {
        super.retrieveTokens(to, anotherToken);
    }

    /**
     * @notice  private compound function to update state variables
     * @dev     compounding is only possible as long the contract has enough tokens left
     * @param   timestampCompound  current compound timestamp
     */
    function _compound(uint256 timestampCompound) private {
        uint256 reward = _calculateRewardTotal(timestampCompound);
        require(reward < _totalSupplyReward, 'Contract has not enough tokens left');

        _totalSupplyReward -= reward;
        _totalStakedTokens += reward;
        _stakedAmount[_msgSender()] += reward;
        _timestampStake[_msgSender()] = timestampCompound;
    }

    /**
     * @dev     the calculation for compounding using the _rateTimestamps and _rateValues array.
     *          1. case: user uses only the latest rate. Only consider the last interval
     *          2. case: user uses multiple rates.
     *              a) compute the last interval
     *              b) compute the first interval
     *              c) compute in-between intervals
     * @param   timestampCompound  current compound time
     */
    function _calculateRewardTotal(uint256 timestampCompound) private view returns (uint256) {
        uint256 reward = 0;
        if (_timestampStake[_msgSender()] > _rateTimestamps[_rateTimestamps.length - 1]) {
            reward += _calculateRewardForInterval(
                _stakedAmount[_msgSender()], //stakedAmount
                _timestampStake[_msgSender()], //intervalStart
                timestampCompound, //intervalEnd
                _rateValues[_rateValues.length - 1] //rate
            );
            //2. case
        } else {
            // a)
            reward += _calculateRewardForInterval(
                _stakedAmount[_msgSender()], //stakedAmount
                _rateTimestamps[_rateTimestamps.length - 1], //intervalStart
                timestampCompound, //intervalEnd
                _rateValues[_rateValues.length - 1] //rate
            );

            bool startIntervalIscalculated = false;

            for (uint256 i = 1; i < _rateTimestamps.length; i++) {
                // c)
                if (startIntervalIscalculated) {
                    reward += _calculateRewardForInterval(
                        _stakedAmount[_msgSender()], //stakedAmount
                        _rateTimestamps[i - 1], //intervalStart
                        _rateTimestamps[i], //intervalEnd
                        _rateValues[i - 1] //rate
                    );
                }

                // b)
                if (_timestampStake[_msgSender()] < _rateTimestamps[i] && !startIntervalIscalculated) {
                    reward += _calculateRewardForInterval(
                        _stakedAmount[_msgSender()], //stakedAmount
                        _timestampStake[_msgSender()], //intervalStart
                        _rateTimestamps[i], //intervalEnd
                        _rateValues[i - 1] //rate
                    );
                    startIntervalIscalculated = true;
                }
            }
        }
        return reward;
    }

    /**
     * @dev     calculates the reward depending on parameters
     * @param   stake  the amount of staked tokens
     * @param   intervalStart  start of the interval
     * @param   intervalEnd  end of the interval
     * @param   rate  rate to use for computation of reward (100% = 10000)
     * @return  uint256  reward
     */
    function _calculateRewardForInterval(
        uint256 stake,
        uint256 intervalStart,
        uint256 intervalEnd,
        uint256 rate
    ) private pure returns (uint256) {
        //reward = stake * intervalDuration (in seconds) * (rewardRate/10**4) / (seconds in a year)
        return (stake * (intervalEnd - intervalStart) * rate) / (10**4 * 31536000);
    }

    /**
     * @dev     calculates the DIV tokens that the recepient of a transaction gets
     * @param   amount  amount of sended tokens
     * @return  uint256  amound of received tokens
     */
    function _calculateTokensReceived(uint256 amount) private view returns (uint256) {
        // function _calculateTokensReceived(uint256 amount) private returns (uint256) {
        uint256 tBurn = 0;
        if (_token.totalSupply() != _token.burnStopSupply()) {
            tBurn = amount / 100; // 1 pct per transaction
            // Reduce burn amount to burn limit
            if (_token.totalSupply() < _token.burnStopSupply() + amount) {
                tBurn = _token.totalSupply() - _token.burnStopSupply();
            }
        }
        //amount - tFound - tCommunity - tBurn
        return
            amount - ((amount * _token.foundationRate()) / 10**4) - ((amount * _token.communityRate()) / 10**4) - tBurn;
    }
}