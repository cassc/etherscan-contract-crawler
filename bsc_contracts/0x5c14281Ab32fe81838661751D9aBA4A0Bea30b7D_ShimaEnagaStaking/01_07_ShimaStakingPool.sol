/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShimaEnagaStaking is Ownable {
    using SafeMath for uint256;

    struct Stake {
        uint256 tAmount;
        uint256 time;
        uint256 period;
        uint256 rate;
        bool isActive;
    }

    mapping(uint256 => uint256) public interestRate;
    mapping(address => Stake[]) public stakes;

    IERC20 private token;

    uint256 constant private DENOMINATOR = 10000;
    uint256 public rewardsDistributed;
    uint256 public rewardsPending;
    uint256 public totalStaked = 0;
    uint256 public earlyWithdrawFee = 2500;

    event TokenStaked(address account, uint256 stakeId, uint256 tokenAmount, uint256 timestamp, uint256 period);
    event TokenUnstaked(address account, uint256 tokenAmount, uint256 interest, uint256 timestamp);
    event StakingPeriodUpdated(uint256 period, uint256 rate);

    modifier isValidStakeId(address _address, uint256 _id) {
        require(_id < stakes[_address].length, "Id is not valid");
        _;
    }

    constructor() {
        token = IERC20(0x2979BD552940471cee400dfC5C90086f361A8839);

        interestRate[1] = 350;
        interestRate[6] = 1200;
        interestRate[12] = 3000;
    }

    function stakeToken(uint256 _amount, uint256 _period) external {
        require(interestRate[_period] != 0, "Staking period not valid");

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 stakeId = stakes[msg.sender].length;
        rewardsPending = rewardsPending.add(_amount.mul(interestRate[_period]).div(DENOMINATOR));
        stakes[msg.sender].push(Stake(_amount, block.timestamp, _period, interestRate[_period], true));
        totalStaked = totalStaked.add(_amount);
        emit TokenStaked(msg.sender, stakeId, _amount, block.timestamp, _period);
    }

    function unstakeToken(uint256 _id, bool emergencyWithdraw) external isValidStakeId(msg.sender, _id) {
        require(emergencyWithdraw || timeLeftToUnstake(msg.sender, _id) == 0, "Stake duration not over");
        require(stakes[msg.sender][_id].isActive, "Tokens already unstaked");

        Stake storage stake = stakes[msg.sender][_id];

        uint256 interest = stakingReward(msg.sender, _id);
        uint256 tAmount = stake.tAmount;
        uint256 availableAmount = token.balanceOf(address(this)).sub(totalStaked);
        require(availableAmount >= interest, "insufficient funds");

        uint256 total = tAmount.add(interest);
        uint256 earlyFee = total.mul(earlyWithdrawFee).div(DENOMINATOR);
        uint256 totalUnstaked = emergencyWithdraw ? total.sub(earlyFee) : total;

        stake.isActive = false;
        rewardsPending = rewardsPending.sub(interest);
        rewardsDistributed = rewardsDistributed.add(interest);

        require(token.transfer(msg.sender, totalUnstaked), "transfer failed");
        emit TokenUnstaked(msg.sender, tAmount, interest, block.timestamp);
    }

    function getStake(address _address, uint256 _id) external view isValidStakeId(_address, _id) returns (Stake memory) {
        return stakes[_address][_id];
    }

    function getAllStakes(address _address) external view returns (Stake[] memory) {
        return stakes[_address];
    }

    function timeLeftToUnstake(address _address, uint256 _id) public view isValidStakeId(_address, _id) returns (uint256) {
        require(stakes[_address][_id].isActive, "Tokens already unstaked");

        Stake memory stake = stakes[_address][_id];
        uint256 unstakeTime = stake.time + stake.period * 30 days;

        return (
        block.timestamp < unstakeTime ? unstakeTime - block.timestamp : 0
        );
    }

    function canUnstake(address _address, uint256 _id) public view isValidStakeId(_address, _id) returns (bool) {
        return (timeLeftToUnstake(_address, _id) == 0 && stakes[_address][_id].isActive);
    }

    function stakingReward(address _address, uint256 _id) public view isValidStakeId(_address, _id) returns (uint256) {
        Stake memory stake = stakes[_address][_id];

        return stake.tAmount.mul(stake.rate).div(DENOMINATOR);
    }

    function addStakingPeriod(uint256 _period, uint256 _rate) external onlyOwner {
        interestRate[_period] = _rate;
        emit StakingPeriodUpdated(_period, _rate);
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Allows retrieval of any ERC20 token that was sent to the contract address
    /// @return success true if the transfer succeeded, false otherwise
    function rescueToken(address tokenAddress) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(msg.sender, ERC20(tokenAddress).balanceOf(address(this)));
    }
}