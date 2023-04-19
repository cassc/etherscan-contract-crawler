/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// File: DEXOStaking.sol
pragma solidity ^0.8.0;

import "./library/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
 
contract Staking is Initializable, OwnableUpgradeable{
    using SafeMath for uint256;
 
    uint256 public totalStake;
    uint256 public totalRewards;
 
    enum StakingPeriod{ ONE_MONTH, TWO_MONTH, THREE_MONTH, SIX_MONTH, ONE_YEAR }
 
    struct stake {
        uint256 amount;
        StakingPeriod stakePeriod;
        uint timestamp;
    }
 
    mapping(uint8 => address[]) public stakeholders;
    mapping(uint8 => uint) public oldTimeStamp;
    mapping(address => mapping(StakingPeriod => mapping(uint8 => stake))) public stakes;
    mapping(StakingPeriod => uint) public apr;
    mapping(StakingPeriod => mapping(uint8 => uint)) public apr_old;
 
    IERC20Upgradeable public myToken;
 
    function initialize (address _myToken) public initializer
    { 
        myToken = IERC20Upgradeable(_myToken);
        apr[StakingPeriod.ONE_MONTH] = 350; //15 days 
        apr[StakingPeriod.TWO_MONTH] = 775; // 30 days
        apr[StakingPeriod.THREE_MONTH] = 1417; // 90 days 
        apr[StakingPeriod.SIX_MONTH] = 2415; // 120 days
        apr[StakingPeriod.ONE_YEAR] = 4212; // 365 days
        __Ownable_init();
    }
 
    event TokenStaked(address indexed _from, uint amount, StakingPeriod plan, uint timestamp);
    event TokenUnstaked(address indexed _from, uint amount, StakingPeriod plan, uint timestamp);
    event RewardsTransferred(address indexed _to, uint amount, StakingPeriod plan, uint timestamp);
 
    // ---------- STAKES ----------
 
    function createStake(uint256 _stake, StakingPeriod _stakePeriod) public {
        require(_stake > 0, "stake value should not be zero");
        require(myToken.transferFrom(msg.sender, address(this), _stake), "Token Transfer Failed");
        if(stakes[msg.sender][_stakePeriod][2].amount == 0) {
            addStakeholder(msg.sender, 2);
            stakes[msg.sender][_stakePeriod][2] = stake(_stake, _stakePeriod, block.timestamp);
        } else {
            stake memory tempStake = stakes[msg.sender][_stakePeriod][2];
            tempStake.amount = tempStake.amount.add(_stake);
            tempStake.timestamp = block.timestamp;
            stakes[msg.sender][_stakePeriod][2] = tempStake;
        }
            totalStake = totalStake.add(_stake);
        emit TokenStaked(msg.sender, _stake, _stakePeriod, block.timestamp);
    }
 
    function unStake(uint256 _stake, StakingPeriod _stakePeriod) public {
        require(_stake > 0, "stake value should not be zero");
        stake memory newTempStake = stakes[msg.sender][_stakePeriod][2];
        stake memory silverTempStake = stakes[msg.sender][_stakePeriod][1];
        stake memory goldTempStake = stakes[msg.sender][_stakePeriod][0];
        require(_stake <= (newTempStake.amount + silverTempStake.amount + goldTempStake.amount) , "Invalid Stake Amount");
        require( (newTempStake.amount>0 && validateStakingPeriod(newTempStake)) || (silverTempStake.amount>0 && validateStakingPeriod(silverTempStake)) || (goldTempStake.amount>0 && validateStakingPeriod(goldTempStake)), "Staking period is not expired");
        uint256 _investorReward = getDailyRewards(_stakePeriod);
        uint256 _unstake = _stake;

        totalStake = totalStake.sub(_stake);
        if(goldTempStake.amount > 0 && _stake >= goldTempStake.amount){
            _stake = _stake - goldTempStake.amount;
            goldTempStake.amount = 0;
            stakes[msg.sender][_stakePeriod][0] = goldTempStake;
            removeStakeholder(msg.sender, 0);
        }else{
            goldTempStake.amount = goldTempStake.amount.sub(_stake);
            _stake = 0;
            stakes[msg.sender][_stakePeriod][0] = goldTempStake;
        }
        if(silverTempStake.amount > 0 && _stake >= silverTempStake.amount){
            _stake = _stake - silverTempStake.amount;
            silverTempStake.amount = 0;
            stakes[msg.sender][_stakePeriod][1] = silverTempStake;
            removeStakeholder(msg.sender, 1);
        }else{
            silverTempStake.amount = silverTempStake.amount.sub(_stake);
            _stake = 0;
            stakes[msg.sender][_stakePeriod][1] = silverTempStake;
        }
        if(newTempStake.amount > 0 && _stake >= newTempStake.amount){
            _stake = _stake - newTempStake.amount;
            newTempStake.amount = 0;
            stakes[msg.sender][_stakePeriod][2] = newTempStake;
            removeStakeholder(msg.sender, 2);
        }else{
            newTempStake.amount = newTempStake.amount.sub(_stake);
            _stake = 0;
            stakes[msg.sender][_stakePeriod][2] = newTempStake;
        }
        totalRewards = totalRewards.add(_investorReward);
        uint256 tokensToBeTransfer = _unstake.add(_investorReward);
        myToken.transfer(msg.sender, tokensToBeTransfer);
        emit TokenUnstaked(msg.sender, tokensToBeTransfer, _stakePeriod, block.timestamp);
    }

    function withdraw() public onlyOwner {
        myToken.transfer(msg.sender, myToken.balanceOf(address(this)));
    }
 
    function createOldInvestorList(address[] memory _address, uint256[] memory _stake, StakingPeriod[] memory _stakePeriod, uint[] memory _timeStamp) public onlyOwner {
        for(uint i = 0 ; i < _address.length ; i++) {
            require(_stake[i] > 0, "stake value should not be zero");
            if(_timeStamp[i] < oldTimeStamp[0]){
                if(stakes[_address[i]][_stakePeriod[i]][0].amount == 0) {
                    addStakeholder(_address[i], 0);
                    stakes[_address[i]][_stakePeriod[i]][0] = stake(_stake[i], _stakePeriod[i], _timeStamp[i]);
                } else {
                    stake memory goldTempStake = stakes[_address[i]][_stakePeriod[i]][0];
                    goldTempStake.amount = goldTempStake.amount.add(_stake[i]);
                    goldTempStake.timestamp = _timeStamp[i];
                    stakes[_address[i]][_stakePeriod[i]][0] = goldTempStake;
                }
            }else{
                    if(stakes[_address[i]][_stakePeriod[i]][1].amount == 0) {
                    addStakeholder(_address[i], 1);
                    stakes[_address[i]][_stakePeriod[i]][1] = stake(_stake[i], _stakePeriod[i], _timeStamp[i]);
                } else {
                    stake memory silverTempStake = stakes[_address[i]][_stakePeriod[i]][1];
                    silverTempStake.amount = silverTempStake.amount.add(_stake[i]);
                    silverTempStake.timestamp = _timeStamp[i];
                    stakes[_address[i]][_stakePeriod[i]][1] = silverTempStake;
                }
            }
                    totalStake = totalStake.add(_stake[i]);
            emit TokenStaked(_address[i], _stake[i], _stakePeriod[i], _timeStamp[i]);
        }
    }

    function getInvestorRewards(uint256 _unstakeAmount, StakingPeriod _period, uint _timeStamp) public view returns (uint256) {
        if(_timeStamp <= oldTimeStamp[0]) {
            return _unstakeAmount.mul(apr_old[_period][0]).div(100).div(100);
        }else if(_timeStamp <= oldTimeStamp[1]){
            return _unstakeAmount.mul(apr_old[_period][1]).div(100).div(100);
        } else {
            return _unstakeAmount.mul(apr[_period]).div(100).div(100);
        }
    } 
 
    function setOldTimeStamp(uint8 _index, uint _timeStamp) public onlyOwner() {
        oldTimeStamp[_index] = _timeStamp;
    }
 
    function validateStakingPeriod(stake memory _investor) internal view returns(bool) {
        uint256 stakingTimeStamp = _investor.timestamp + getStakingPeriodInNumbers(_investor);
        return block.timestamp >= stakingTimeStamp; 
    } 
 
    function getStakingPeriodInNumbers(stake memory _investor) internal pure returns (uint256){
        return _investor.stakePeriod == StakingPeriod.ONE_MONTH ? 15 days : _investor.stakePeriod == StakingPeriod.TWO_MONTH ? 30 days : _investor.stakePeriod == StakingPeriod.THREE_MONTH ? 90 days : _investor.stakePeriod == StakingPeriod.SIX_MONTH ? 120 days : _investor.stakePeriod == StakingPeriod.ONE_YEAR ? 365 days : 0; 
    }

    function stakeOf(address _stakeholder, StakingPeriod _stakePeriod)
        public
        view
        returns(uint256)
    {
        uint256 stakedAmount = stakes[_stakeholder][_stakePeriod][0].amount + stakes[_stakeholder][_stakePeriod][1].amount + stakes[_stakeholder][_stakePeriod][2].amount;
        return stakedAmount;
    }
 
    function getDailyRewards(StakingPeriod _stakePeriod) public view returns (uint256) {
        uint normal_reward = 0;
        uint silver_reward = 0;
        uint gold_reward = 0;
        stake memory normalTempStake = stakes[msg.sender][_stakePeriod][2];
        stake memory silverTempStake = stakes[msg.sender][_stakePeriod][1];
        stake memory goldTempStake = stakes[msg.sender][_stakePeriod][0];
        if(normalTempStake.amount > 0)
            normal_reward = getInvestorRewards(normalTempStake.amount, _stakePeriod, normalTempStake.timestamp).div(365).mul((block.timestamp - normalTempStake.timestamp).div(60).div(60).div(24) < 1 ? 1 : (block.timestamp - normalTempStake.timestamp).div(60).div(60).div(24));
        if(silverTempStake.amount > 0)
            silver_reward = getInvestorRewards(silverTempStake.amount, _stakePeriod, silverTempStake.timestamp).div(365).mul((block.timestamp - silverTempStake.timestamp).div(60).div(60).div(24) < 1 ? 1 : (block.timestamp - silverTempStake.timestamp).div(60).div(60).div(24));
        if(goldTempStake.amount > 0)
            gold_reward = getInvestorRewards(goldTempStake.amount, _stakePeriod, goldTempStake.timestamp).div(365).mul((block.timestamp - goldTempStake.timestamp).div(60).div(60).div(24) < 1 ? 1 : (block.timestamp - goldTempStake.timestamp).div(60).div(60).div(24));
        return (normal_reward + silver_reward + gold_reward);
    }
 
    function getRewardsPerDay(StakingPeriod _stakePeriod) public view returns (uint256) {
        uint normal_reward = 0;
        uint silver_reward = 0;
        uint gold_reward = 0;
        stake memory normalTempStake = stakes[msg.sender][_stakePeriod][2];
        stake memory silverTempStake = stakes[msg.sender][_stakePeriod][1];
        stake memory goldTempStake = stakes[msg.sender][_stakePeriod][0];
        if(normalTempStake.amount > 0)
            normal_reward = getInvestorRewards(normalTempStake.amount, _stakePeriod, normalTempStake.timestamp).div(365);
        if(silverTempStake.amount > 0)
            silver_reward = getInvestorRewards(silverTempStake.amount, _stakePeriod, silverTempStake.timestamp).div(365);
        if(goldTempStake.amount > 0)
            gold_reward = getInvestorRewards(goldTempStake.amount, _stakePeriod, goldTempStake.timestamp).div(365);
        uint256 total_rewards = normal_reward + silver_reward + gold_reward;
        return total_rewards;
    }
 
    function getExpiredDay(StakingPeriod _stakePeriod) public view returns (uint256) {
        uint256 expiredDay = 0;
        (bool _isGoldholder, ) = isStakeholder(msg.sender, 0);
        (bool _isSilverholder, ) = isStakeholder(msg.sender, 1);
        if(_isGoldholder){
            stake memory tempStake = stakes[msg.sender][_stakePeriod][0];
            expiredDay = tempStake.timestamp + getStakingPeriodInNumbers(tempStake);
        }else if(_isSilverholder){
            stake memory tempStake = stakes[msg.sender][_stakePeriod][1];
            expiredDay = tempStake.timestamp + getStakingPeriodInNumbers(tempStake);
        }else{
            stake memory tempStake = stakes[msg.sender][_stakePeriod][2];
            expiredDay = tempStake.timestamp + getStakingPeriodInNumbers(tempStake);
        }
        return expiredDay;
    }
 
    // ---------- STAKEHOLDERS ----------
 
    function isStakeholder(address _address, uint8 _level)
        internal
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders[_level].length; s += 1){
            if (_address == stakeholders[_level][s]) return (true, s);
        }
        return (false, 0);
    }
 
 
    function addStakeholder(address _stakeholder, uint8 _level)
        internal
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder, _level);
        if(!_isStakeholder) stakeholders[_level].push(_stakeholder);
    }
 
 
    function removeStakeholder(address _stakeholder, uint8 _level)
        internal
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder, _level);
        if(_isStakeholder){
            stakeholders[_level][s] = stakeholders[_level][stakeholders[_level].length - 1];
            stakeholders[_level].pop();
        } 
    }
    // ---------- REWARDS ----------
 
 
    function getTotalRewards()
        public
        view
        returns(uint256)
    {
        return totalRewards;
    }
 
    // ---- Staking APY  setters ---- 
 
    function setApyPercentage(uint _percentage, StakingPeriod _stakePeriod) public onlyOwner {
        apr[_stakePeriod] = _percentage;
    }
 
    function setOldApyPercentage(uint _percentage, StakingPeriod _stakePeriod, uint8 _index) public onlyOwner {
        apr_old[_stakePeriod][_index] = _percentage;
    }
 
    function remainingTokens() public view returns (uint256) {
        return Math.min(myToken.balanceOf(owner()), myToken.allowance(owner(), address(this)));
    }
 
}