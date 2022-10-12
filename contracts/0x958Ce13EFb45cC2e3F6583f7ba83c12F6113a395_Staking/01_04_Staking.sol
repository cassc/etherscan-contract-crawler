// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity  0.8.9;

contract Staking is Ownable{
    /**
     * 1- first pool: 
     */

    struct Pool {
        uint256 poolId;
        uint256 poolBalance;
        uint256 coolDown;
        uint256 totalStake;
        uint256 startTime;
        uint256 stakers;
    }

    struct StakeInfo {
        uint256 poolId;
        uint256 staked;
        bool claimed;
        uint256 coolDown;
    }

    mapping(address=>mapping(uint256=>StakeInfo)) public stakers;
    mapping(address=>bool) public whitelisted;
    mapping(uint256=>Pool) public pools;

    IERC20 public ICY;
    uint256 private ICY_ts;

    uint256 public poolOneBalance;
    uint256 public poolTwoBalance;
    uint256 public poolThreeBalance;

    Pool public PoolOne;
    Pool public PoolTwo;
    Pool public PoolThree;

    uint256 public totalFund;

    uint256 public stakeFee = 2;
    uint256 public unstakeFee = 2;
    address public marketingWallet = 0x3EaE574542E1aAC362C84f0cCb363a8EB4d13Da0;

    constructor(address icy_token){
        ICY = IERC20(icy_token);
        ICY_ts = ICY.totalSupply();

        poolOneBalance = ICY_ts / 200;
        poolTwoBalance = ICY_ts / 100;
        poolThreeBalance = (ICY_ts * 15) / 1000;

        PoolOne = Pool(0, poolOneBalance, 0, 0,  0, 0);
        PoolTwo = Pool(1, poolTwoBalance, 15 days, 0,  0, 0);
        PoolThree = Pool(2, poolThreeBalance, 30 days, 0,  0, 0);

        totalFund = poolOneBalance + poolTwoBalance + poolThreeBalance;
        whitelisted[msg.sender] = true;
        pools[0] = PoolOne;
        pools[1] = PoolTwo;
        pools[2] = PoolThree;
    }

    function setWhitelisted(address staker, bool status) public onlyOwner{
        whitelisted[staker] = status;
    }

    function StartPool(uint256 poolId) public onlyOwner{
        pools[poolId].startTime = block.timestamp;
    }

    function fundStakingContract() external onlyOwner {
        ICY.transferFrom(msg.sender, address(this), totalFund);
    }

    function deposit(uint256 stakeAmount, uint256 poolId) public {
        //validating data
        bool Iswhitelisted = whitelisted[msg.sender];
        require(stakeAmount > 0 && poolId < 3, "Invalid Operation");
        Pool memory m_pool = pools[poolId];
        require((m_pool.startTime != 0 && m_pool.startTime < block.timestamp) || Iswhitelisted == true, "Pool not started yet!");
        bool stakedBefore = false;

        //User Staking Info
        StakeInfo memory m_stakeInfo = stakers[msg.sender][poolId];
        if(m_stakeInfo.staked > 0){
            stakedBefore = true;
        }
        if(m_pool.coolDown > 0){
            m_stakeInfo.coolDown = block.timestamp + m_pool.coolDown;
        }

        //Taxes
        uint256 fee = 0;
        if(!Iswhitelisted){
            fee = (stakeAmount * stakeFee) / 100;
            ICY.transferFrom(msg.sender, marketingWallet, fee);
        }

        m_stakeInfo.staked += stakeAmount - fee;
        m_stakeInfo.poolId = poolId;
        stakers[msg.sender][poolId] = m_stakeInfo;

        //Pool Staking Info
        m_pool.totalStake += (stakeAmount - fee);
        if(!stakedBefore){
            m_pool.stakers += 1;
        }
        pools[poolId] = m_pool;


        uint256 toStake = stakeAmount - fee;
        ICY.transferFrom(msg.sender, address(this), toStake);
    }

    function withdraw(uint256 withdrawAmount, uint256 poolId) public {
        require(poolId < 3 && withdrawAmount > 0, "Invalid Operation");

        //Checking balances
        Pool memory m_pool = pools[poolId];
        StakeInfo memory m_stakeInfo = stakers[msg.sender][poolId];
        require(withdrawAmount <= m_stakeInfo.staked, "can not withdraw more than staked!");

        //Effects
        m_pool.stakers -= 1;
        m_pool.totalStake -= withdrawAmount;
        m_stakeInfo.staked -= withdrawAmount;
        stakers[msg.sender][poolId] = m_stakeInfo;
        pools[poolId] = m_pool;

        //Taxes
        uint256 fee = 0;
        if(!whitelisted[msg.sender]){
            fee = (withdrawAmount * unstakeFee) / 100;
            ICY.transfer(marketingWallet, fee);
        }

        uint256 toSend = withdrawAmount - fee;
        ICY.transfer(msg.sender, toSend);
    }

    function harvest(uint256 poolId) public {
        StakeInfo memory m_stakeInfo = stakers[msg.sender][poolId];
        Pool memory m_pool = pools[poolId];
        require(poolId < 3 && m_stakeInfo.staked > 0 && m_pool.stakers >= 5, "Invalid Operation");
        require(!m_stakeInfo.claimed, "already claimed");
        require(m_stakeInfo.coolDown < block.timestamp, "can not withdraw before cooldown");

        //Calculating Rewards
        uint256 toClaim = (m_stakeInfo.staked * m_pool.poolBalance) / m_pool.totalStake;
        m_stakeInfo.claimed = true;
        m_pool.poolBalance -= toClaim;
        pools[poolId] = m_pool;
        stakers[msg.sender][poolId] = m_stakeInfo;
        ICY.transfer(msg.sender, toClaim);
    }

    function getPendingReward(address _staker, uint256 poolId) public view returns(uint256){
        StakeInfo memory m_stakeInfo = stakers[_staker][poolId];
        Pool memory m_pool = pools[poolId];
        if(m_pool.totalStake == 0){
            return 0;
        }
        return (m_stakeInfo.staked * m_pool.poolBalance) / m_pool.totalStake;
    }

    function getPoolInfo(uint256 id) public view returns(Pool memory){
        return pools[id];
    }

    function getUserInfo(address staker, uint256 id) public view returns(StakeInfo memory){
        return stakers[staker][id];
    }

    receive() payable external{}

    fallback() payable external{}
}