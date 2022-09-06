pragma solidity 0.6.6;

import "./openzeppelinupgradeable/math/MathUpgradeable.sol";
import "./openzeppelinupgradeable/math/SafeMathUpgradeable.sol";
import "./openzeppelinupgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./openzeppelinupgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./openzeppelinupgradeable/utils/PausableUpgradeable.sol";
import "./openzeppelinupgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/INFT.sol";
import "./openzeppelin/TokensRecoverableUpg.sol";


abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}

// supports ERC721 NFT boosts only

contract PiStakingRewards is Initializable, TokensRecoverableUpg, RewardsDistributionRecipient, ReentrancyGuardUpgradeable, PausableUpgradeable  {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardsToken1;

    IERC20Upgradeable public stakingToken;
    IERC20Upgradeable public stakingTokenMultiplier;

    uint256 public periodFinish;
    
    uint256 public rewardRate1; 

    uint256 public rewardsDuration ;
    uint256 public lastUpdateTime;
    uint256 public rewardPerToken1Stored;

    address public stakingPoolFeeAdd;
    address public devFundAdd;

    uint256 public stakingPoolFeeWithdraw;
    uint256 public devFundFeeWithdraw;

    mapping(address => uint256) public userRewardPerToken1Paid;

    mapping(address => uint256) public rewards1;

    uint256 private _totalSupply;
    uint256 private _totalSupplyMultiplier;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesMultiplier;
    
    mapping(address => uint256) public lockingPeriodStaking;

    mapping(address => uint256) public multiplierFactor;

    uint256 public lockTimeStakingToken; 

    uint256 public totalToken1ForReward;
    
    uint256[3] public multiplierRewardToken1Amt;

    mapping(address=>uint256) public multiplierFactorNFT; // user address => NFT's M.F.
    mapping(address=>mapping(address=>bool)) public boostedByNFT; // user address => NFT contract => true if boosted by that particular NFT
    // avoids double boost 

    address[] NFTboostedAddresses; // all addresses who boosted by NFT

    mapping(address=>uint256) public totalNFTsBoostedBy; // total NFT boosts done by user

    mapping(address=>uint256) public boostPercentNFT; // set by owner 1*10^17 = 10% boost
    address[] public erc721NFTContracts;
    mapping(address=>bool) allowedERC721NFTContracts;


    function initialize(        
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken,
        address _stakingTokenMultiplier
        )  public initializer  {
        
        __Ownable_init_unchained();
        rewardsToken1 = IERC20Upgradeable(_rewardsToken1);

        stakingToken = IERC20Upgradeable(_stakingToken);
        stakingTokenMultiplier = IERC20Upgradeable(_stakingTokenMultiplier);
        rewardsDistribution = _rewardsDistribution;

        periodFinish = 0;
        rewardRate1 = 0;
        totalToken1ForReward=0;
        rewardsDuration = 60 days; 

        multiplierRewardToken1Amt = [2000000 ether, 3000000 ether, 4000000 ether];

        stakingPoolFeeAdd = 0xb0bBfAF6492B70359a001Fd30E673A4fcE875c6C;
        devFundAdd = 0x16352774BF9287E0324E362897c1380ABC8B2b35;
        
        stakingPoolFeeWithdraw = 0; 
        devFundFeeWithdraw = 10000; // 10% fee on early withdraw
        lockTimeStakingToken = 30 days;

    }

   
    /* ========== VIEWS ========== */
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupplyMultiplier() external view returns (uint256) {
        return _totalSupplyMultiplier;
    }

    function balanceOfMultiplier(address account) external view returns (uint256) {
        return _balancesMultiplier[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerToken1() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerToken1Stored;
        }
        return
            rewardPerToken1Stored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate1).mul(1e18).div(_totalSupply)
            );
    }
    
   
    // divide by 10^6 and add decimals => 6 d.p.
    function getMultiplyingFactor(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0 && multiplierFactorNFT[account] == 0) {
            return 1000000;
        }
        uint256 MFwei = multiplierFactor[account].add(multiplierFactorNFT[account]);
        if(multiplierFactor[account]==0)
            MFwei = MFwei.add(1e18);
        return MFwei.div(1e12);
    }


    function getMultiplyingFactorWei(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0 && multiplierFactorNFT[account] == 0) {
            return 1e18;
        }
        uint256 MFWei = multiplierFactor[account].add(multiplierFactorNFT[account]);
        if(multiplierFactor[account]==0)
            MFWei = MFWei.add(1e18);
        return MFWei;
    }

    function earnedtokenRewardToken1(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account]))
        .div(1e18).add(rewards1[account]);
    }
    
    
    function totalEarnedRewardToken1(address account) public view returns (uint256) {
        return (_balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account]))
        .div(1e18).add(rewards1[account])).mul(getMultiplyingFactorWei(account)).div(1e18);
    }
    
    function getReward1ForDuration() external view returns (uint256) {
        return rewardRate1.mul(rewardsDuration);
    }


    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForYear = rewardRate1.mul(31536000); 
        if(_totalSupply<=1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

  

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForWeek = rewardRate1.mul(604800); 
        if(_totalSupply<=1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }


   


    /* ========== MUTATIVE FUNCTIONS ========== */

    // feeAmount = 100 => 1%
    function setTransferParams(address _stakingPoolFeeAdd, address _devFundAdd, uint256 _stakingPoolFeeStaking, uint256 _devFundFeeStaking
        ) external onlyOwner{

        stakingPoolFeeAdd = _stakingPoolFeeAdd;
        devFundAdd = _devFundAdd;
        stakingPoolFeeWithdraw = _stakingPoolFeeStaking;
        devFundFeeWithdraw = _devFundFeeStaking;
    }

    function setTimelockStakingToken(uint256 lockTime) external onlyOwner{
         lockTimeStakingToken=lockTime;   
    }
    
    function pause() external onlyOwner{
        _pause();
    }
    function unpause() external onlyOwner{
        _unpause();
    }


    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        lockingPeriodStaking[msg.sender]= block.timestamp.add(lockTimeStakingToken);

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function boostByToken(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");

        _totalSupplyMultiplier = _totalSupplyMultiplier.add(amount);
        _balancesMultiplier[msg.sender] = _balancesMultiplier[msg.sender].add(amount);
        
        // send the whole multiplier fee to dev fund address
        stakingTokenMultiplier.safeTransferFrom(msg.sender, devFundAdd, amount);
        getTotalMultiplier(msg.sender);
        emit BoostedStake(msg.sender, amount);
    }



    // _boostPercent = 10000 => 10% => 10^4 * 10^13
    function addNFTasMultiplier(address _erc721NFTContract, uint256 _boostPercent) external onlyOwner {
        
        require(block.timestamp >= periodFinish, 
            "Cannot set NFT boosts after staking starts"
        );
        
        require(allowedERC721NFTContracts[_erc721NFTContract]==false,"This NFT is already allowed for boosts");
        allowedERC721NFTContracts[_erc721NFTContract]=true;

        erc721NFTContracts.push(_erc721NFTContract);
        boostPercentNFT[_erc721NFTContract] = _boostPercent.mul(1e13);
    }


    // if next cycle of staking starts it resets for all users
    function _resetNFTasMultiplierForUser() internal {

        for(uint i=0;i<NFTboostedAddresses.length;i++){
            totalNFTsBoostedBy[NFTboostedAddresses[i]]=0;

            for(uint j=0;j<erc721NFTContracts.length;j++)
                    boostedByNFT[NFTboostedAddresses[i]][erc721NFTContracts[j]]=false;

            multiplierFactorNFT[NFTboostedAddresses[i]]=0;
        }

        delete NFTboostedAddresses;
    }

    // reset possible after Previous rewards period finishes
    function resetNFTasMultiplier() external onlyOwner {
        require(block.timestamp > periodFinish,
            "Previous rewards period must be complete before resetting"
        );

        for(uint i=0;i<erc721NFTContracts.length;i++){
            boostPercentNFT[erc721NFTContracts[i]] = 0;
            allowedERC721NFTContracts[erc721NFTContracts[i]]=false;
        }

        _resetNFTasMultiplierForUser();
        delete erc721NFTContracts;
    }


    // can get total boost possible by user's NFTs
    function getNFTBoostPossibleByAddress(address NFTowner) public view returns(uint256){

        uint256 multiplyFactor = 0;
        for(uint i=0;i<erc721NFTContracts.length;i++){

            if(IERC721(erc721NFTContracts[i]).balanceOf(NFTowner)>=1)
                multiplyFactor = multiplyFactor.add(boostPercentNFT[erc721NFTContracts[i]]);

        }

        uint256 boostWei= multiplierFactor[NFTowner].add(multiplyFactor);
        return boostWei.div(1e12);

    }


    // approve NFT to contract before you call this function
    function boostByNFT(address _erc721NFTContract, uint256 _tokenId) external nonReentrant whenNotPaused {
    
        require(block.timestamp <= periodFinish, 
            "Cannot use NFT boosts before staking starts"
        );
        
        require(allowedERC721NFTContracts[_erc721NFTContract]==true,"This NFT is not allowed for boosts");
        
        uint256 multiplyFactor = boostPercentNFT[_erc721NFTContract];

        if(totalNFTsBoostedBy[msg.sender]==0){
            NFTboostedAddresses.push(msg.sender);
        }

        // bool NFTallowed = false;
        // for(uint i=0;i<erc721NFTContracts.length;i++){
        //     if(_erc721NFTContract == erc721NFTContracts[i]){
        //         NFTallowed=true;
        //         break;
        //     }
        // }

        // require(NFTallowed==true, "This NFT is not allowed for boosts");

        // CHECK already boosted by same NFT contract??
        require(boostedByNFT[msg.sender][_erc721NFTContract]==false,"Already boosted by this NFT");


        multiplierFactorNFT[msg.sender]= multiplierFactorNFT[msg.sender].add(multiplyFactor);
        IERC721(_erc721NFTContract).transferFrom(msg.sender, devFundAdd, _tokenId);

        totalNFTsBoostedBy[msg.sender]=totalNFTsBoostedBy[msg.sender].add(1);
        boostedByNFT[msg.sender][_erc721NFTContract] = true;

        require(totalNFTsBoostedBy[msg.sender]<=erc721NFTContracts.length,"Total boosts cannot be more than MAX NfT boosts available");


        emit NFTMultiplier(msg.sender, _erc721NFTContract, _tokenId);
    }

    
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(amount<=_balances[msg.sender],"Staked amount is lesser");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if(block.timestamp < lockingPeriodStaking[msg.sender]){
            uint256 devFee = amount.mul(devFundFeeWithdraw).div(100000); // feeWithdraw = 100000 = 100%
            stakingToken.safeTransfer(devFundAdd, devFee);
            uint256 stakingFee = amount.mul(stakingPoolFeeWithdraw).div(100000); // feeWithdraw = 100000 = 100%
            stakingToken.safeTransfer(stakingPoolFeeAdd, stakingFee);
            uint256 remAmount = amount.sub(devFee).sub(stakingFee);
            stakingToken.safeTransfer(msg.sender, remAmount);
        }
        else    
            stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }


    function getReward() public nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 reward1 = rewards1[msg.sender].mul(getMultiplyingFactorWei(msg.sender)).div(1e18);
        
        if (reward1 > 0) {
            rewards1[msg.sender] = 0;
            rewardsToken1.safeTransfer(msg.sender, reward1);
            totalToken1ForReward=totalToken1ForReward.sub(reward1);
        }       

        emit RewardPaid(msg.sender, reward1);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    // reward 1  => DMagic
    function notifyRewardAmount(uint256 rewardToken1Amount) external onlyRewardsDistribution updateReward(address(0)) {

        totalToken1ForReward = totalToken1ForReward.add(rewardToken1Amount);

        // using x% of reward amount, remaining locked for multipliers 
        // x * 1.3 (max M.F.) = 100
        uint256 multiplyFactor = 1e18 + 3e17; // 130%
        for(uint i=0;i<erc721NFTContracts.length;i++){
                multiplyFactor = multiplyFactor.add(boostPercentNFT[erc721NFTContracts[i]]);
        }

        uint256 denominatorForMF = 1e20;

        // reward * 100 / 130 ~ 76% (if NO NFT boost)
        uint256 reward1Available = rewardToken1Amount.mul(denominatorForMF).div(multiplyFactor).div(100); 
        // uint256 reward2Available = rewardToken2.mul(denominatorForMF).div(multiplyFactor).div(100);

        if (block.timestamp >= periodFinish) {
            rewardRate1 = reward1Available.div(rewardsDuration);
            _resetNFTasMultiplierForUser();
        } 
        else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover1 = remaining.mul(rewardRate1);
            rewardRate1 = reward1Available.add(leftover1).div(rewardsDuration);
        }
        
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance1 = rewardsToken1.balanceOf(address(this));
        require(rewardRate1 <= balance1.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);

        emit RewardAdded(reward1Available);
    }


    // only left over reward provided by owner can be withdrawn after reward period finishes
    function withdrawNotified() external onlyOwner {
        require(block.timestamp >= periodFinish, 
            "Cannot withdraw before reward time finishes"
        );
        
        address owner = OwnableUpgradeable.owner();
        // only left over reward amount will be left
        IERC20Upgradeable(rewardsToken1).safeTransfer(owner, totalToken1ForReward);
        
        emit Recovered(address(rewardsToken1), totalToken1ForReward);
        
        totalToken1ForReward=0;
    }

    // only reward provided by owner can be withdrawn in emergency, user stakes are safe
    function withdrawNotifiedEmergency(uint256 reward1Amount) external onlyOwner {

        require(reward1Amount<=totalToken1ForReward,"Total reward left to distribute is lesser");

        address owner = OwnableUpgradeable.owner();
        // only left over reward amount will be left
        IERC20Upgradeable(rewardsToken1).safeTransfer(owner, reward1Amount);
        
        emit Recovered(address(rewardsToken1), reward1Amount);
        
        totalToken1ForReward=totalToken1ForReward.sub(reward1Amount);

    }
    
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken) && tokenAddress != address(stakingTokenMultiplier) && tokenAddress != address(rewardsToken1) ,
            "Cannot withdraw the staking or rewards tokens"
        );
        address owner = OwnableUpgradeable.owner();
        IERC20Upgradeable(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }


    function setOnMultiplierAmount(uint256[3] calldata _values) external onlyOwner {
        multiplierRewardToken1Amt = _values;
    }

    // view function for input as multiplier token amount
    // returns Multiply Factor in 6 decimal place
    function getMultiplierForAmount(uint256 _amount) public view returns(uint256) {
        uint256 multiplier=0;        
        uint256 parts=0;
        uint256 totalParts=1;

        if(_amount>=multiplierRewardToken1Amt[0] && _amount < multiplierRewardToken1Amt[1]) {
            totalParts = multiplierRewardToken1Amt[1].sub(multiplierRewardToken1Amt[0]);
            parts = _amount.sub(multiplierRewardToken1Amt[0]); 
            multiplier = parts.mul(1e17).div(totalParts).add(10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[1] && _amount < multiplierRewardToken1Amt[2]) {
            totalParts = multiplierRewardToken1Amt[2].sub(multiplierRewardToken1Amt[1]);
            parts = _amount.sub(multiplierRewardToken1Amt[1]); 
            multiplier = parts.mul(1e17).div(totalParts).add(2 * 10 ** 17); 
        }
     
        else if(_amount>=multiplierRewardToken1Amt[2]){
            multiplier = 3 * 10 ** 17;
        }

      
         uint256 multiplyFactor = multiplier.add(1e18);
         return multiplyFactor.div(1e12);
    }


    function getTotalMultiplier(address account) internal{
        uint256 multiplier=0;        
        uint256 parts=0;
        uint256 totalParts=1;

        uint256 _amount = _balancesMultiplier[account];

        if(_amount>=multiplierRewardToken1Amt[0] && _amount < multiplierRewardToken1Amt[1]) {
            totalParts = multiplierRewardToken1Amt[1].sub(multiplierRewardToken1Amt[0]);
            parts = _amount.sub(multiplierRewardToken1Amt[0]); 
            multiplier = parts.mul(1e17).div(totalParts).add(10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[1] && _amount < multiplierRewardToken1Amt[2]) {
            totalParts = multiplierRewardToken1Amt[2].sub(multiplierRewardToken1Amt[1]);
            parts = _amount.sub(multiplierRewardToken1Amt[1]); 
            multiplier = parts.mul(1e17).div(totalParts).add(2 * 10 ** 17); 
        }

        else if(_amount>=multiplierRewardToken1Amt[2]){
            multiplier = 3 * 10 ** 17;
        }

         uint256 multiplyFactor = multiplier.add(1e18);
         multiplierFactor[msg.sender]=multiplyFactor;
    }
    
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerToken1Stored = rewardPerToken1();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards1[account] = earnedtokenRewardToken1(account);
            userRewardPerToken1Paid[account] = rewardPerToken1Stored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward1);
    event Staked(address indexed user, uint256 amount);
    event BoostedStake(address indexed user, uint256 amount);
    event NFTMultiplier(address indexed user, address ERC721NFTContract, uint256 tokenId);
    
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnMultiplier(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward1);

    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    

}