// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICustomMintable.sol";

/**
 * @title ERC900 Simple Staking Interface basic implementation
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract SGTStaking is Ownable, ReentrancyGuard {

    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);

    using SafeMath for uint256;

    // Token used for staking
    ERC20 stakingToken;

    // Token used for minting
    ICustomMintable mintingToken;

    // reward plan for staking
    struct RewardPlan {
        uint256 index;
        string name;
        uint256 duration;
        uint256 rewardRate;
        uint256 votingPowerRate;
        uint256 deletedAt;
    }

    // stake holder , include address and all stake from that address
    struct Stakeholder {
        address addr;
        Stake[] stakes;
    }

    // Struct for personal stakes (i.e., stakes made by this address)
    // index - index of that stake in list
    // amount - the amount of tokens in the stake
    // rewardClaimed - the reward amount of tokens when finishing stake
    // rewardPlan - the reward plan
    // lockedAt - when the stake lock (in seconds since Unix epoch)
    // unlockedAt - when the stake unlock (in seconds since Unix epoch)
    struct Stake {
        uint256 index;
        uint256 amount;
        uint256 rewardClaimed;
        RewardPlan rewardPlan;
        uint256 lockedAt;
        uint256 unlockedAt;
    }

    // list all reward plan
    RewardPlan[] private rewardPlans;

    // list stake holder
    Stakeholder[] private stakeholders;
    // maping index from address to stake holder
    mapping(address => uint256) private stakeholderIndexes;

    /**
    * @dev Constructor function
    * @param _stakingToken ERC20 The address of the token contract used for staking
    */
    constructor(address _stakingToken , address _mintingToken) {
        stakingToken = ERC20(_stakingToken);
        mintingToken = ICustomMintable(_mintingToken);
        stakeholders.push();
        // index 0 is for nothing
        createRewardPlan("6 Months" , 180 days , 0 , 50);
        createRewardPlan("12 Months" , 360 days , 0 , 75);
        createRewardPlan("18 Months" , 540 days , 0 , 100);
        createRewardPlan("24 Months" , 720 days , 0 , 150);
        createRewardPlan("30 Months" , 900 days , 0 , 200);
        createRewardPlan("36 Months" , 1080 days , 0 , 300);
        createRewardPlan("42 Months" , 1260 days , 0 , 500);
    }

    /**
     * @dev Modifier that checks that msg sender is stake holder or not
     */
    modifier onlyStakeholder() {
        require(isStakeholder(msg.sender), "SGTStake: caller is not the stakeholder");
        _;
    }

    /**
     * @dev Modifier that checks that this reward plan is avaiable or not
     * @param _index index of that reward plan
     */
    modifier validRewardPlanIndex(uint256 _index) {
        require(_index < rewardPlans.length, "SGTStake: reward plan does not exist");
        _;
    }

    /**
   * @dev Modifier that checks that this contract can transfer tokens from the
   *  balance in the stakingToken contract for the given address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
    modifier canStake(address _address, uint256 _amount) {
        require(
            stakingToken.transferFrom(_address, address(this), _amount),
            "Stake required");

        _;
    }


    /**
    * @dev Get all reward plans avaiable
    * @return RewardPlan[] list of reward plans
    */
    function getRewardPlans() external view returns (RewardPlan[] memory)
    {
        return rewardPlans;
    }

    /**
     * @dev create new reward plan
     * @param _name name of that reward plan
     * @param _duration duration of that reward plan in seconds
     * @param _rewardRate rate of that reward plan
     * @param _votingPowerRate rate of that voting power
     */
    function createRewardPlan(string memory _name, uint256 _duration, uint256 _rewardRate, uint256 _votingPowerRate) public onlyOwner {
        require(_duration > 0, "SGTStake: duration cannot be zero");
//        require(_rewardRate > 0, "SGTStake: reward rate cannot be zero");
        rewardPlans.push(RewardPlan({
            index : rewardPlans.length,
            name : _name,
            duration : _duration,
            rewardRate : _rewardRate,
            votingPowerRate : _votingPowerRate,
            deletedAt : 0
            }));
    }

    /**
     * @dev update reward plan
     * @param _index index of that reward plan
     * @param _name name of that reward plan
     * @param _rewardRate rate of that reward plan
     * @param _votingPowerRate rate of that voting power
     */
    function updateRewardPlan(uint256 _index, string memory _name, uint256 _rewardRate, uint256 _votingPowerRate) external onlyOwner validRewardPlanIndex(_index)
    {
        rewardPlans[_index].name = _name;
        rewardPlans[_index].rewardRate = _rewardRate;
        rewardPlans[_index].votingPowerRate = _votingPowerRate;
    }

    /**
     * @dev remove reward plan
     * @param _index index of that reward plan
     */
    function removeRewardPlan(uint256 _index) external onlyOwner validRewardPlanIndex(_index)
    {
        require(rewardPlans[_index].deletedAt == 0, "SGTStake: reward plan does not exist");
        rewardPlans[_index].deletedAt = block.timestamp;
    }

    /**
    * @dev calculate reward from stake
    * @param _stake stake information
    * @return uint256 calculated reward
    */
    function calculateReward(Stake memory _stake) internal pure returns (uint256)
    {
        return _stake.rewardPlan.duration * _stake.amount * _stake.rewardPlan.rewardRate / 100 / 365 days;
    }

    /**
    * @dev calculate reward from stake
    * @param _stake stake information
    * @return uint256 calculated reward
    */
    function calculateVotingPower(Stake memory _stake) internal view returns (uint256)
    {
        return _stake.rewardPlan.votingPowerRate * _stake.amount  / 100 / (10 ** stakingToken.decimals());
    }


    /**
     * @notice Address of the token being used by the staking interface
     * @return address The address of the ERC20 token used for staking
     */
    function token() external view returns (address) {
        return address(stakingToken);
    }


    /**
    * @dev Helper function to get specific properties of all of the personal stakes created by sender address
    * @return (Stake[]) staked  array
    */
    function getStakes()
    external
    view
//    onlyStakeholder
    returns (Stake[] memory)
    {
        uint256 _stakeholderIndex = stakeholderIndexes[msg.sender];
        return stakeholders[_stakeholderIndex].stakes;
    }

    /**
    * @dev Helper function to get specific properties of all of the personal stakes created by input address
    * @param _address address The address to query
    * @return (Stake[]) staked array
    */
    function getStakesFromAddress(address _address)
    external
    view
//    onlyOwner
    returns (Stake[] memory)
    {
        uint256 _stakeholderIndex = stakeholderIndexes[_address];
        return stakeholders[_stakeholderIndex].stakes;
    }

    /**
    * @dev regist an stake holder
    * @param _stakeholder address of the stack holder
    * @return uint256 index of stackholder
    */
    function register(address _stakeholder)
    internal
    returns (uint256)
    {
        stakeholders.push();
        uint256 index = stakeholders.length - 1;
        stakeholders[index].addr = _stakeholder;
        stakeholderIndexes[_stakeholder] = index;
        return index;
    }

    /**
     * @dev Helper function to create stakes for a given address
     * @param _amount uint256 The number of tokens being staked
     * @param _rewardPlanIndex uint256 The reward plan index
     */
    function createStake(
        uint256 _amount,
        uint256 _rewardPlanIndex
    )
    internal
    canStake(msg.sender, _amount)
    validRewardPlanIndex(_rewardPlanIndex)
    nonReentrant
    {
        require(
            _amount > 0,
            "SGTStake: Stake amount has to be greater than 0!");
        //
        RewardPlan memory _rewardPlan = rewardPlans[_rewardPlanIndex];
        require(_rewardPlan.deletedAt == 0, "SGTStake: reward plan does not exist");
        //

        uint256 _stakeholderIndex = stakeholderIndexes[msg.sender];
        if (!isStakeholder(msg.sender)) {
            _stakeholderIndex = register(msg.sender);
        }
        Stake memory _stake = Stake({
            index : stakeholders[_stakeholderIndex].stakes.length,
            amount : _amount,
            rewardClaimed : 0,
            rewardPlan : _rewardPlan,
            lockedAt : block.timestamp,
            unlockedAt : 0
            });
        stakeholders[_stakeholderIndex].stakes.push(_stake);
        //
        uint256 _votingPower = calculateVotingPower(_stake);
        mintingToken.mint(msg.sender , _votingPower , _stake.lockedAt + _stake.rewardPlan.duration);
        //
        emit Staked(
            msg.sender,
            _amount,
            _amount);
    }

    /**
     * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
     * @notice MUST trigger Staked event
     * @param _amount uint256 the amount of tokens to stake
     * @param _rewardPlanIndex uint256 the index of reward plan
     */
    function stake(uint256 _amount, uint256 _rewardPlanIndex) external {
        createStake(
            _amount,
            _rewardPlanIndex);
    }

    /**
     * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
     * @param _stakeIndex uint256 the stake index
     */
    function unstake(uint256 _stakeIndex) external {
        withdrawStake(
            _stakeIndex);
    }

    /**
     * @dev return token balance of an address
     * @param _address address the query address
     */
    function tokenBalance(address _address) external view returns (uint256){
        return stakingToken.balanceOf(_address);
    }

    /**
     * @dev Helper function to withdraw stakes for the msg.sender
     * @param _stakeIndex uint256 the stake index
     */
    function withdrawStake(
        uint256 _stakeIndex
    ) internal
    nonReentrant
    onlyStakeholder
    {
        uint256 _stakeholderIndex = stakeholderIndexes[msg.sender];
        Stake[] memory _stakes = stakeholders[_stakeholderIndex].stakes;
        require(_stakeIndex < _stakes.length, "SGTStake: stake does not exist");
        Stake memory _stake = _stakes[_stakeIndex];
        require(_stake.unlockedAt == 0, "SGTStake: stake does not exist");
        require(block.timestamp - _stake.lockedAt > _stake.rewardPlan.duration, "SGTStake: stake is still locked");
        //
        uint256 _amount = _stake.amount;
        uint256 _reward = calculateReward(_stake);
        uint256 _totalSend = _amount + _reward;
        // Transfer the staked tokens from this contract back to the sender
        // Notice that we are using transfer instead of transferFrom here, so
        //  no approval is needed beforehand.
        require(
            stakingToken.transfer(msg.sender, _totalSend),
            "Unable to withdraw stake");

        stakeholders[_stakeholderIndex].stakes[_stakeIndex].rewardClaimed = _reward;
        stakeholders[_stakeholderIndex].stakes[_stakeIndex].unlockedAt = block.timestamp;

        emit Unstaked(
            msg.sender,
            _amount,
            _totalSend);
    }

    /**
     * @dev Helper function to check an address is stakeholder or not
     * @param _stakeholder address the query address
     * @return bool true or false
     */
    function isStakeholder(address _stakeholder) public view returns (bool)
    {
        return stakeholderIndexes[_stakeholder] != 0;
    }
}