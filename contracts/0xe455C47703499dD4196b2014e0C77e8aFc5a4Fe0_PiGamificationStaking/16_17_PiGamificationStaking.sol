// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./TokensRecoverable.sol";
import "./interfaces/IBLL.sol";
import "./interfaces/INFT.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        require(_rewardsDistribution!=address(0),"_rewardsDistribution cannot be zero address");
        rewardsDistribution = _rewardsDistribution;
    }
}

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract PiGamificationStaking is Initializable, OwnableUpgradeable, RewardsDistributionRecipient, ReentrancyGuardUpgradeable, PausableUpgradeable , TokensRecoverable {
    using SafeMathUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardsToken;
    INFT public stakingToken;
    uint256 public periodFinish ;
    uint256 public rewardRate ;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // added mapping to hold balances of ERC721 sent to contract
    // NFT owner -> TokenID 
    mapping(address => uint) public _tokenBalances;
    // Account => All NFT ids staked (not updated during withdraw)
    mapping(address => uint32[]) private _tokenIdsStaked; 
    // nft id => stake value from BLL
    mapping(uint32 => uint256) public stakedAtValue;

    // total worth value of staked token ids
    uint256 private _totalSupply;
    // Account => total worth value of staked token ids for the account
    mapping(address => uint256) private _balances;

    // all nft ids in smart contract for which BLL updated 
    uint32[] public allNFTIds;
    // nft id => owner address (not updated during withdraw)
    mapping(uint32=>address) public ownerOfNFT;
    // nft id => bool (updated during withdraw)
    mapping(uint32=>bool) public isStaked;

    IBLL public BLLContract;

    // sync this with BLL contract
    mapping(uint32=>uint) public BLLPoints;

    /* ========== CONSTRUCTOR ========== */

    function initialize(        
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken, // ERC721 token 
        address _BLLContract
        )  public initializer  {
        
        __Ownable_init_unchained();
        rewardsToken = IERC20Upgradeable(_rewardsToken1);
        stakingToken = INFT(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        BLLContract = IBLL(_BLLContract);

        require(_rewardsDistribution!=address(0),"_rewardsDistribution cannot be zero address");
        require(_rewardsToken1!=address(0),"_rewardsToken1 cannot be zero address");
        require(_stakingToken!=address(0),"_stakingToken cannot be zero address");
        require(_BLLContract!=address(0),"_BLLContract cannot be zero address");

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 60 days;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external  view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external  view returns (uint256) {
        return _balances[account];
    }

    function balanceOfNFT(address account) external  view returns (uint256) {
        return _tokenBalances[account];
    }


    function lastTimeRewardApplicable() public  view returns (uint256) {
        return MathUpgradeable.min(block.timestamp,periodFinish);
    }

    function rewardPerToken() public  view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public  view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external  view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForYear = rewardRate.mul(31536000); 
        if(_totalSupply<=1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForWeek = rewardRate.mul(604800); 
        if(_totalSupply<=1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function tokenIdsStaked(address account) external view returns(uint32[] memory){
     
        uint32[] memory arrStaked = _tokenIdsStaked[account];

        uint32 newArrSize=0;
        // find size of new arr
        for(uint32 i=0;i<arrStaked.length;i++)
            if(isStaked[arrStaked[i]])
                newArrSize++;
        
        uint32[] memory newArr = new uint32[](newArrSize);
        uint32 j=0;
        for(uint32 i=0;i<arrStaked.length;i++){
            if(isStaked[arrStaked[i]]){
                newArr[j]=arrStaked[i];
                j++;
            }
        }

        return newArr;
    }


    function syncPointsForTokenIDs(uint32[] memory nftIDs) external returns(bool){
        for(uint i;i<nftIDs.length;i=unchecked_inc(i)){
            uint32 tokenIDi = nftIDs[i];
            if(BLLPoints[tokenIDi] == 0)
                // will not delete this nft id from array if withdrawn NFT as it is gas costly, keeping isStaked[tokenId] to track status & may call call refresh_AllNFTids()
                allNFTIds.push(tokenIDi); 

            BLLPoints[tokenIDi] = BLLContract.getPointsForTokenID(tokenIDi).mul(1e18);
        }
        return true;
    }

    function syncPointsForTokenIDsRange(uint32 startNFTID, uint32 endNFTID) external returns(bool){
        for(uint32 i=startNFTID;i<=endNFTID;i=unchecked_inc_32(i)){
            if(BLLPoints[i] == 0)
                // will not delete this nft id from array if withdrawn NFT as it is gas costly, keeping isStaked[tokenId] to track status & may call call refresh_AllNFTids()
                allNFTIds.push(i); 
            BLLPoints[i] = BLLContract.getPointsForTokenID(i).mul(1e18);
        }
        return true;
    }


    function unchecked_inc(uint x) private pure returns(uint){
        unchecked{return x+1;}
    }

    function unchecked_inc_32(uint32 x) private pure returns(uint32){
        unchecked{return x+1;}
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint32[] memory tokenIds) external nonReentrant whenNotPaused updateReward(_msgSender()) {
        // bulk transfer available, then uncomment below and comment safeTransferFrom in loop?
        stakingToken.batchTransferFromSmallInt(_msgSender(), address(this), tokenIds);
    
        for(uint i;i<tokenIds.length;i=unchecked_inc(i)){
            // need to get value 1 by 1 for each tokenId so that we know "stakedAtValue[tokenIds[i]]" for each tokenId. 
            uint32 tokenIDi = tokenIds[i];
            uint value = BLLPoints[tokenIDi];
            stakeValue(_msgSender(), value);

            // remain same? so can remove..
            stakedAtValue[tokenIDi] = value;

            // comment below if bulk transfer available                    
            // stakingToken.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

            _tokenIdsStaked[_msgSender()].push(tokenIDi); 

            ownerOfNFT[tokenIDi] = _msgSender();
            isStaked[tokenIDi] = true;
        }
        uint newTokenBal = _tokenBalances[_msgSender()].add(tokenIds.length);
        _tokenBalances[_msgSender()]=newTokenBal;  
        emit Staked(_msgSender(), tokenIds);
    }

    function updateAllPoints() external onlyOwner{
        updatePoints(allNFTIds);
    }

    function updatePoints(uint32[] memory nftIDs) public onlyOwner{
        for(uint32 i;i<nftIDs.length;i=unchecked_inc_32(i))
           updatePointForID(nftIDs[i]);
        emit UpdatedPoints(nftIDs);
    }

    function updatePointsRange(uint32 startNFTID, uint32 endNFTID) public onlyOwner{
        for(uint32 i=startNFTID;i<=endNFTID;i=unchecked_inc_32(i))
           updatePointForID(i);
    }

    function updatePointForID(uint32 tokenId) public onlyOwner{
        if(isStaked[tokenId]){
            // need to get value 1 by 1 for each tokenId so that we know "stakedAtValue[tokenIds[i]]" for each tokenId and can compare with it now. 
            uint value = BLLPoints[tokenId];
            uint prevValue = stakedAtValue[tokenId];
            address account = ownerOfNFT[tokenId];
            refreshReward(account);
            if(prevValue>value)
                unstakeValue(account, prevValue.sub(value));
            else
                stakeValue(account, value.sub(prevValue));
            stakedAtValue[tokenId] = value;
        }
    }

    function stakeValue(address account, uint delta) internal{
        uint newTotalSupply = _totalSupply.add(delta);
        uint newBalance = _balances[account].add(delta);
        _totalSupply = newTotalSupply;
        _balances[account] = newBalance;
    } 

    function unstakeValue(address account, uint delta) internal{
        uint newTotalSupply = _totalSupply.sub(delta);
        uint newBalance = _balances[account].sub(delta);
        _totalSupply = newTotalSupply;
        _balances[account] = newBalance;
    }

    function setBLLContract(IBLL _BLLContract) external onlyOwner{
        BLLContract = _BLLContract;
    }

    function withdraw(uint32[] memory tokenIds) public  nonReentrant updateReward(_msgSender()) {

        uint updatedTokenBal = _tokenBalances[_msgSender()].sub(tokenIds.length);
        _tokenBalances[_msgSender()] = updatedTokenBal;
        // bulk transfer available, then uncomment below and comment safeTransferFrom in loop?
        stakingToken.batchTransferFromSmallInt(address(this),_msgSender(), tokenIds);

        for(uint32 i=0;i<tokenIds.length;i++){
            require(ownerOfNFT[tokenIds[i]] == _msgSender(), "NOT_NFT_OWNER");
            require(isStaked[tokenIds[i]], "already unstaked");
            uint value = stakedAtValue[tokenIds[i]];
            uint newTotalSupply = _totalSupply.sub(value);
            uint newBalance = _balances[_msgSender()].sub(value);
            _totalSupply = newTotalSupply;
            _balances[_msgSender()] = newBalance;
            // stakingToken.safeTransferFrom(address(this),_msgSender(), tokenIds[i]);
            isStaked[tokenIds[i]]=false;
        }
        emit Withdrawn(_msgSender(), tokenIds);
    }


    // remove redundant values in _tokenIdsStaked
    function refresh__tokenIdsStaked(address account) public{
        uint32[] memory arrStaked = _tokenIdsStaked[account];

        uint32 newArrSize=0;
        // find size of new arr
        for(uint32 i;i<arrStaked.length;i=unchecked_inc_32(i))
            if(isStaked[arrStaked[i]])
                newArrSize++;
        
        uint32[] memory newArr = new uint32[](newArrSize);
        uint32 j;
        for(uint32 i;i<arrStaked.length;i=unchecked_inc_32(i)){
            if(isStaked[arrStaked[i]]){
                newArr[j]=arrStaked[i];
                j++;
            }
        }
        _tokenIdsStaked[account]=newArr;
        emit RefreshedTokenIdsStaked(account);
    }

    function _withdrawAll() internal updateReward(_msgSender()) {
        // bulk transfer available, then uncomment below and comment safeTransferFrom in loop?
        // stakingToken.batchTransferFrom(address(this),_msgSender(), tokenIds);
        uint totalValue;
        uint32[] memory tokenIDarr = _tokenIdsStaked[_msgSender()];
        for(uint i;i<tokenIDarr.length;i=unchecked_inc(i)){
            uint32 tokenId = tokenIDarr[i];
            if(isStaked[tokenId] && ownerOfNFT[tokenId] == _msgSender()){
                totalValue = totalValue.add(stakedAtValue[tokenId]);
                stakingToken.safeTransferFrom(address(this),_msgSender(), tokenId);
                isStaked[tokenId]=false;
            }
        }
        uint32[] memory newArr;
        _totalSupply = _totalSupply.sub(totalValue);
        _tokenBalances[_msgSender()]=0;
        _balances[_msgSender()] = 0;
        _tokenIdsStaked[_msgSender()]=newArr;
        emit WithdrawnAll(_msgSender());

    }

    function getReward() public nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.transfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    function exit() external  {
        _withdrawAll();
        getReward();
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function refreshReward(address account) internal updateReward(account){

    }

    function onERC721Received(address _operator, address _from, uint256 _id, bytes calldata _data) external  returns(bytes4){
        return 0x150b7a02;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint32[] tokenIds);
    event Withdrawn(address indexed user,  uint32[] tokenIds);
    event WithdrawnAll(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event UpdatedPoints(uint32[] nftIDs);
    event RefreshedTokenIdsStaked(address indexed user);
}