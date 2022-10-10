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
    IERC721Upgradeable public stakingToken;
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

    // all nft ids in smart contract staked (not updated during withdraw)
    uint32[] public allNFTIds;
    // nft id => owner address (not updated during withdraw)
    mapping(uint32=>address) public ownerOfNFT;
    // nft id => bool (updated during withdraw)
    mapping(uint32=>bool) public isStaked;

    IBLL public BLLContract;

    /* ========== CONSTRUCTOR ========== */

    function initialize(        
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken, // ERC721 token 
        address _BLLContract
        )  public initializer  {
        
        __Ownable_init_unchained();
        rewardsToken = IERC20Upgradeable(_rewardsToken1);
        stakingToken = IERC721Upgradeable(_stakingToken);
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


    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint32[] memory tokenIds) external  nonReentrant whenNotPaused updateReward(_msgSender()) {

        for(uint32 i=0;i<tokenIds.length;i++){
            // need to get value 1 by 1 for each tokenId so that we know "stakedAtValue[tokenIds[i]]" for each tokenId. 
            uint value = BLLContract.getPointsForTokenID(tokenIds[i]).mul(1e18);
            stakeValue(_msgSender(), value);
            stakedAtValue[tokenIds[i]] = value;
                    
            stakingToken.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

            _tokenIdsStaked[_msgSender()].push(tokenIds[i]); 

            // ownerOfNFT[tokenId] shows current/last owner of NFT, to save gas we donot update it during withdraw..
            if(ownerOfNFT[tokenIds[i]] == address(0))
                // will not delete this nft id from array if withdrawn NFT as it is gas costly, keeping isStaked[tokenId] to track status & may call call refresh_AllNFTids()
                allNFTIds.push(tokenIds[i]); 

            ownerOfNFT[tokenIds[i]] = _msgSender();
            isStaked[tokenIds[i]] = true;
        }
        _tokenBalances[_msgSender()]=_tokenBalances[_msgSender()].add(tokenIds.length);        
        emit Staked(_msgSender(), tokenIds);
    }

    function updateAllPoints() external onlyOwner{
        updatePoints(allNFTIds);
    }

    function updatePoints(uint32[] memory nftIDs) public onlyOwner{

        for(uint32 i=0;i<nftIDs.length;i++){
            uint32 tokenId = nftIDs[i];
            if(isStaked[tokenId]){
                // need to get value 1 by 1 for each tokenId so that we know "stakedAtValue[tokenIds[i]]" for each tokenId and can compare with it now. 
                uint value = BLLContract.getPointsForTokenID(tokenId).mul(1e18);
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
        emit UpdatedPoints(nftIDs);
    }

    // removes extra nft ids that are unstaked now..
    function refresh_AllNFTids() external{

        uint32 newArrSize=0;
        // find size of new arr
        for(uint32 i=0;i<allNFTIds.length;i++)
            if(isStaked[allNFTIds[i]])
                newArrSize++;

        uint32[] memory newNFTids = new uint32[](newArrSize);
        uint32 j=0;
        for(uint32 i=0;i<allNFTIds.length;i++){
            uint32 tokenId = allNFTIds[i];
            if(isStaked[tokenId]){
                newNFTids[j] = tokenId;
                j++;
            }
            else             
                ownerOfNFT[tokenId] = address(0);
        }
        allNFTIds = newNFTids;
        emit RefreshedAllNFTids();
    }

    function stakeValue(address account, uint delta) internal{
        _totalSupply = _totalSupply.add(delta);
        _balances[account] = _balances[account].add(delta);
    } 

    function unstakeValue(address account, uint delta) internal{
        _totalSupply = _totalSupply.sub(delta);
        _balances[account] = _balances[account].sub(delta);
    }

    function setBLLContract(IBLL _BLLContract) external onlyOwner{
        BLLContract = _BLLContract;
    }

    function withdraw(uint32[] memory tokenIds) public  nonReentrant updateReward(_msgSender()) {
        
        // to be removed for future contract
        if(ownerOfNFT[tokenIds[0]]==address(0)){
            uint32[] memory arrStaked = _tokenIdsStaked[_msgSender()];
            for(uint32 i=0;i<arrStaked.length;i++){
                ownerOfNFT[arrStaked[i]] = _msgSender();
            }
        }

        _tokenBalances[_msgSender()]=_tokenBalances[_msgSender()].sub(tokenIds.length);

        for(uint32 i=0;i<tokenIds.length;i++){
            require(ownerOfNFT[tokenIds[i]] == _msgSender(), "NOT_NFT_OWNER");
            require(isStaked[tokenIds[i]], "already unstaked");
            uint value = stakedAtValue[tokenIds[i]];
            _totalSupply = _totalSupply.sub(value);
            _balances[_msgSender()] = _balances[_msgSender()].sub(value);
            stakingToken.safeTransferFrom(address(this),_msgSender(), tokenIds[i]);
            isStaked[tokenIds[i]]=false;
        }
        emit Withdrawn(_msgSender(), tokenIds);
    }


    // remove redundant values in _tokenIdsStaked
    function refresh__tokenIdsStaked(address account) public{
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
        _tokenIdsStaked[account]=newArr;
        emit RefreshedTokenIdsStaked(account);
    }

    function _withdrawAll() internal updateReward(_msgSender()) {

        for(uint i=0;i<_tokenBalances[_msgSender()];i++){
            uint32 tokenId = _tokenIdsStaked[_msgSender()][i];
            uint value = stakedAtValue[tokenId];
            _totalSupply = _totalSupply.sub(value);
            _balances[_msgSender()] = _balances[_msgSender()].sub(value);
            stakingToken.safeTransferFrom(address(this),_msgSender(), tokenId);
            isStaked[tokenId]=false;
        }
        uint32[] memory newArr;
        _tokenBalances[_msgSender()]=0;
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
        refresh__tokenIdsStaked(_msgSender());
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

    // to be removed for future contract
    function refreshIndex() external onlyOwner{
        _tokenBalances[0x97a88D526232D228f15621B3bacce9C56137d789]=_tokenBalances[0x97a88D526232D228f15621B3bacce9C56137d789].add(2); // for token ids 1152 and 1164
        // so that token id owner can see these token ids in list
        isStaked[1152]=true; 
        isStaked[1164]=true;
        // total supply and balances was reduced for token ids 1152 and 1164 by these numbers
        _totalSupply = _totalSupply.add(26000000000000000000000).add(25500000000000000000000);
        _balances[0x97a88D526232D228f15621B3bacce9C56137d789] = _balances[0x97a88D526232D228f15621B3bacce9C56137d789].add(26000000000000000000000).add(25500000000000000000000);
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
    event RefreshedAllNFTids();
    event RefreshedTokenIdsStaked(address indexed user);
}