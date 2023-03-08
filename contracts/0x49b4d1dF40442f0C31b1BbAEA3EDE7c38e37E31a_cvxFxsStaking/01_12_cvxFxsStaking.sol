// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/MathUtil.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IFxsDepositor.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract cvxFxsStaking is ERC20, ReentrancyGuard{
    using SafeERC20 for IERC20;


    /* ========== STATE VARIABLES ========== */

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    address public constant vefxsProxy = address(0x59CFCD384746ec3035299D90782Be065e466800B);
    address public constant cvxfxs = address(0xFEEf77d3f69374f66429C91d732A244f074bdf74);
    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant fxsDepositor = address(0x8f55d7c21bDFf1A51AFAa60f3De7590222A3181e);

    //rewards
    address[] public rewardTokens;
    mapping(address => Reward) public rewardData;
    mapping(address => address) public rewardRedirect;

    // Duration that rewards are streamed over
    uint256 public constant rewardsDuration = 86400 * 7;

    // reward token -> distributor -> is approved to add rewards
    mapping(address => mapping(address => bool)) public rewardDistributors;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    /* ========== CONSTRUCTOR ========== */

    constructor() ERC20(
            "Staked CvxFxs",
            "stkCvxFxs"
        ){
        IERC20(fxs).approve(fxsDepositor,type(uint256).max);
    }

    /* ========== ADMIN CONFIGURATION ========== */

    // Add a new reward token to be distributed to stakers
    function addReward(
        address _rewardsToken,
        address _distributor
    ) public onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0);
        require(_rewardsToken != cvxfxs && _rewardsToken != address(this), "invalid token");

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
        rewardDistributors[_rewardsToken][_distributor] = true;
        emit RewardAdded(_rewardsToken, _distributor);
    }

    // Modify approval for an address to call notifyRewardAmount
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime > 0);
        rewardDistributors[_rewardsToken][_distributor] = _approved;
        emit RewardDistributorApproved(_rewardsToken, _distributor);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    //deposit fxs for cvxfxs and stake
    function deposit(uint256 _amount, bool _lock) public nonReentrant{
        require(_amount > 0, 'RewardPool : Cannot deposit 0');

        //mint will call _updateReward
        _mint(msg.sender, _amount);

        //transfer fxs
        IERC20(fxs).safeTransferFrom(msg.sender, address(this), _amount);
        //deposit, cvxfxs will be returned here
        IFxsDepositor(fxsDepositor).deposit(_amount,_lock);
        
        emit Staked(msg.sender, _amount);
    }

    //deposit fxs for cvxfxs and stake
    function deposit(uint256 _amount) external{
        deposit(_amount, false);
    }

    //deposit cvxfxs
    function stake(uint256 _amount) public nonReentrant{
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        //mint will call _updateReward
        _mint(msg.sender, _amount);

        //pull cvxfxs
        IERC20(cvxfxs).safeTransferFrom(msg.sender, address(this), _amount);
        
        emit Staked(msg.sender, _amount);
    }

    //deposit all cvxfxs
    function stakeAll() external{
        uint256 balance = IERC20(cvxfxs).balanceOf(msg.sender);
        stake(balance);
    }

    //deposit cvxfxs and accredit a different address
    function stakeFor(address _for, uint256 _amount) external nonReentrant{
        require(_amount > 0, 'RewardPool : Cannot stake 0');
        
        //give to _for
        //mint will call _updateReward
        _mint(_for, _amount);

        //pull from sender
        IERC20(cvxfxs).safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);
    }

    //withdraw cvxfxs
    function withdraw(uint256 _amount) external nonReentrant{
        require(_amount > 0, 'RewardPool : Cannot withdraw 0');

        //burn will call _updateReward
        _burn(msg.sender, _amount);

        //send cvxfxs
        IERC20(cvxfxs).safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }


    /* ========== VIEWS ========== */

    function _rewardPerToken(address _rewardsToken) internal view returns(uint256) {
        if (totalSupply() == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        rewardData[_rewardsToken].rewardPerTokenStored 
        + (
            (_lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish) - rewardData[_rewardsToken].lastUpdateTime)     
            * rewardData[_rewardsToken].rewardRate
            * 1e18
            / totalSupply()
        );
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance
    ) internal view returns(uint256) {
        return (_balance * (_rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[_user][_rewardsToken] ) / 1e18) + rewards[_user][_rewardsToken];
    }

    function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns(uint256){
        return MathUtil.min(block.timestamp, _finishTime);
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns(uint256) {
        return _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) external view returns(uint256) {
        return _rewardPerToken(_rewardsToken);
    }

    function getRewardForDuration(address _rewardsToken) external view returns(uint256) {
        return rewardData[_rewardsToken].rewardRate * rewardsDuration;
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address _account) external view returns(EarnedData[] memory userRewards) {
        userRewards = new EarnedData[](rewardTokens.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            address token = rewardTokens[i];
            userRewards[i].token = token;
            userRewards[i].amount = _earned(_account, token,  balanceOf(_account));
        }
        return userRewards;
    }

    //set any claimed rewards to automatically go to a different address
    //set address to zero to disable
    function setRewardRedirect(address _to) external nonReentrant{
        rewardRedirect[msg.sender] = _to;
        emit RewardRedirected(msg.sender, _to);
    }

    // Claim all pending rewards
    function getReward(address _address) public nonReentrant updateReward(_address) {
        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[_address][_rewardsToken];
            if (reward > 0) {
                rewards[_address][_rewardsToken] = 0;
                if(rewardRedirect[_address] != address(0)){
                    IERC20(_rewardsToken).safeTransfer(rewardRedirect[_address], reward);
                }else{
                    IERC20(_rewardsToken).safeTransfer(_address, reward);
                }
                emit RewardPaid(_address, _rewardsToken, reward);
            }
        }
    }

    // Claim all pending rewards and forward
    function getReward(address _address, address _forwardTo) public nonReentrant updateReward(_address) {
        //if forwarding, require caller is self
        require(msg.sender == _address, "!self");

        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[_address][_rewardsToken];
            if (reward > 0) {
                rewards[_address][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(_forwardTo, reward);
                emit RewardPaid(_address, _rewardsToken, reward);
            }
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function rewardTokenLength() external view returns(uint256){
        return rewardTokens.length;
    }

    function _notifyReward(address _rewardsToken, uint256 _reward) internal {
        Reward storage rdata = rewardData[_rewardsToken];

        if (block.timestamp >= rdata.periodFinish) {
            rdata.rewardRate = _reward / rewardsDuration;
        } else {
            uint256 remaining = rdata.periodFinish - block.timestamp;
            uint256 leftover = remaining * rdata.rewardRate;
            rdata.rewardRate = (_reward + leftover) / rewardsDuration;
        }

        rdata.lastUpdateTime = block.timestamp;
        rdata.periodFinish = block.timestamp + rewardsDuration;
    }

    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external nonReentrant updateReward(address(0)) {
        require(rewardDistributors[_rewardsToken][msg.sender]);
        require(_reward > 0 && _reward < 1e30, "bad reward value");

        _notifyReward(_rewardsToken, _reward);

        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the _reward amount
        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _reward);
        
        emit RewardAdded(_rewardsToken, _reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external nonReentrant onlyOwner {
        require(rewardData[_tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
        require(_tokenAddress != cvxfxs, "Cannot withdraw staking token");
        IERC20(_tokenAddress).safeTransfer(IBooster(IVoterProxy(vefxsProxy).operator()).rewardManager(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function _updateReward(address _account) internal{
        uint256 userBal = balanceOf(_account);
        for (uint i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = _rewardPerToken(token);
            rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish);
            if (_account != address(0)) {
                rewards[_account][token] = _earned(_account, token, userBal );
                userRewardPerTokenPaid[_account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 ) internal override {
        //checkpoint from and to, can skip if address 0 so no extra gas
        //is used when minting burning
        if(_from != address(0)){
            _updateReward(_from);
        }
        if(_to != address(0)){
            _updateReward(_to);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(vefxsProxy).operator()).rewardManager() == msg.sender, "!owner");
        _;
    }

    modifier updateReward(address _account) {
        _updateReward(_account);
        _;
    }

    /* ========== EVENTS ========== */
    event RewardAdded(address indexed _token, uint256 _reward);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
    event Recovered(address _token, uint256 _amount);
    event RewardAdded(address indexed _reward, address indexed _distributor);
    event RewardDistributorApproved(address indexed _reward, address indexed _distributor);
    event RewardRedirected(address indexed _account, address _forward);
}