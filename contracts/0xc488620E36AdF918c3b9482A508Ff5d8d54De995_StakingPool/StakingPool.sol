/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

// Official PEON Gold Mine
// https://peon.vip/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract StakingPool is Ownable {
    
    struct StakingDetails {
        uint256 stakedAt;
        uint256 tokenAmount;
        uint256 rewardedAt;
        uint256 unlockDate;
    }

    struct AccountDetails {
        uint256 totalStakedTokens;
        uint256 totalUnstakedTokens;
        uint256 totalStakeEntries;
        uint256 totalHarvestedRewards;
    }

    mapping(address => StakingDetails) public stakingDetails;
    mapping(address => AccountDetails) public accountDetails;

    struct GeneralDetails {
        uint256 totalStakedTokens;
        uint256 totalUnstakedTokens;
        uint256 totalUniqueStakers;
        uint256 totalHarvestedRewards;
    }
    GeneralDetails public generalDetails;

    IERC20 public immutable poolToken;
    address payable public poolVault;

    uint256 public rewardDivider;

    uint256 public minimumStakingAmount;
    uint256 public unstakeTaxRemovedAt;
    uint256 public unstakeTaxPercentage;

    mapping(address => bool) public isExemptFromTaxation;
    mapping(address => bool) public isBanned;

    bool public isPaused;
    bool public isEmergencyWithdrawEnabled;

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Exempted(address indexed account, bool isExempt);
    event Banned(address indexed account, bool isBanned);
    event Paused(bool isPaused);
    event EmergencyWithdrawalEnabled(bool isEnabled);
    event EmergencyWithdrawn(
        address indexed account,
        uint256 tokenAmount,
        uint256 stakedAt,
        uint256 rewardedAt
    );

    modifier onlyIfNotPaused() {
        require(!isPaused, "actions are paused");
        _;
    }

    modifier onlyIfNotBanned() {
        require( !isBanned[msg.sender], "account is banned");
        _;
    }

    constructor(address token, address payable vault) {
        poolToken = IERC20(token);
        poolVault = vault;

        //rewardMultiplier = 4757;
        rewardDivider = 1e12;

        minimumStakingAmount = 5*10**18;

        unstakeTaxRemovedAt = 10 days;
        unstakeTaxPercentage = 20;
    }

    function SetPoolAPYSettings(
        //uint256 newRewardMultiplier,
        uint256 newRewardDivider) 
        external 
        onlyOwner 
    {
        //rewardMultiplier = newRewardMultiplier;
        rewardDivider = newRewardDivider;
    }

    function SetMinimumStakingAmount(
        uint256 newMinimumStakingAmount) 
        external 
        onlyOwner 
    {
        minimumStakingAmount = newMinimumStakingAmount;
    }

    function SetExemptFromTaxation(
        address account, 
        bool isExempt) 
        external 
        onlyOwner 
    {
        isExemptFromTaxation[account] = isExempt;
        emit Exempted(account, isExempt);
    }

    function SetUnstakeTaxAndDuration(
        uint256 newUnstakeTaxPercentage,
        uint256 newUnstakeTaxRemovedAt) 
        external 
        onlyOwner 
    {
        unstakeTaxPercentage = newUnstakeTaxPercentage;
        unstakeTaxRemovedAt = newUnstakeTaxRemovedAt;
    }

    function setRewardVault(address payable newRewardVault) external onlyOwner {
        poolVault = newRewardVault;
    }

    function setBanned(address account, bool state) external onlyOwner {
        isBanned[account] = state;
        emit Banned(account, state);
    }

    function setPaused(bool state) external onlyOwner {
        isPaused = state;
        emit Paused(state);
    }

    function setAllowEmergencyWithdraw(bool state) external onlyOwner {
        isEmergencyWithdrawEnabled = state;
        emit EmergencyWithdrawalEnabled(state);
    }

    function stake(uint256 amount, uint256 _unlockDate) external onlyIfNotPaused onlyIfNotBanned {
        address account = _msgSender();

        require(_unlockDate >= stakingDetails[account].unlockDate, "New lock must be => previous one");

        require(amount >= minimumStakingAmount, "staking amount not sufficient");
        require(amount % 1 ether == 0, "Have to be integer without decimals");

        if (accountDetails[account].totalStakeEntries == 0)
            generalDetails.totalUniqueStakers++;

        uint256 rewards = calculateTokenReward(account);
       
        if (rewards > 0) {
            bool beforeLockPeriodEnds = block.timestamp <
                (stakingDetails[account].stakedAt + unstakeTaxRemovedAt);

            if (beforeLockPeriodEnds && !isExemptFromTaxation[account]) {
                uint256 taxAmount = (rewards * unstakeTaxPercentage) / 100;
                rewards -= taxAmount;
            }
            poolToken.transferFrom(poolVault, account, rewards);
            
        }

        stakingDetails[account].stakedAt = block.timestamp;

        poolToken.transferFrom(account, address(this), amount);

        stakingDetails[account].tokenAmount += amount;
        stakingDetails[account].unlockDate = _unlockDate;
        accountDetails[account].totalStakeEntries++;
        accountDetails[account].totalStakedTokens += amount;
        generalDetails.totalStakedTokens += amount;
        emit Staked(account, amount);
    }

    function unstake() external onlyIfNotPaused onlyIfNotBanned {
        address account = _msgSender();
        require(block.timestamp >= stakingDetails[account].unlockDate, "It is not time to unlock");
        require(stakingDetails[account].tokenAmount > 0, "You have 0 staked tokens");
        
        uint256 rewards = calculateTokenReward(account);
        if (rewards > 0) {
            bool beforeLockPeriodEnds = block.timestamp <
                (stakingDetails[account].stakedAt + unstakeTaxRemovedAt);

            if (beforeLockPeriodEnds && !isExemptFromTaxation[account]) {
                uint256 taxAmount = (rewards * unstakeTaxPercentage) / 100;
                rewards -= taxAmount;
            }
            poolToken.transferFrom(poolVault, account, rewards);
        }

        stakingDetails[account].rewardedAt = block.timestamp;
        uint256 amount = stakingDetails[account].tokenAmount;
        delete stakingDetails[account].tokenAmount;

        poolToken.transfer(account, amount);

        accountDetails[account].totalUnstakedTokens += amount;
        accountDetails[account].totalHarvestedRewards += rewards;
        generalDetails.totalHarvestedRewards += rewards;
        generalDetails.totalUnstakedTokens += amount;
        emit Unstaked(account, amount);
    }

    function emergencyWithdraw() external {
        address account = _msgSender();

        require(
            isEmergencyWithdrawEnabled,
            "emergency withdrawal not enabled"
        );

        uint256 tokenAmount = stakingDetails[account].tokenAmount;
        require(tokenAmount > 0, "nothing to withdraw");

        delete stakingDetails[account].tokenAmount;

        if (isBanned[account]) {
            poolToken.transfer(owner(), tokenAmount);
        } else {
            poolToken.transfer(account, tokenAmount);
        }

        emit EmergencyWithdrawn(
            account,
            tokenAmount,
            stakingDetails[account].stakedAt,
            stakingDetails[account].rewardedAt
        );
    }

    function calculateTokenReward(address account)
        public
        view
        returns (uint256 reward)
    {
        uint256 rewardDuration = stakingDetails[account].unlockDate - stakingDetails[account].stakedAt;
        uint256 rewardMultiplier;
        if(rewardDuration >= 365 days){
            rewardMultiplier = 317100; //~1000% 12 Months
        }else if(rewardDuration >= 180 days){
            rewardMultiplier = 158550; //~500% 6 Months
        }else if(rewardDuration >= 90 days){
            rewardMultiplier = 63420; //~200% 3 Months
        }else if (rewardDuration >= 14 days){
            rewardMultiplier = 6342; //~20% 2 Weeks
        }
        else if (rewardDuration < 14 days){
            rewardMultiplier = 634; //~2% Less 2 Weeks
        }

        reward = (stakingDetails[account].tokenAmount * rewardDuration * rewardMultiplier) / rewardDivider;
    }

    function checkAtTheMomentRewards(address account)public view returns (uint256 reward) {
        uint256 rewardDuration = stakingDetails[account].unlockDate - stakingDetails[account].stakedAt;
        uint256 rewardMultiplier;
        if(rewardDuration >= 365 days){
            rewardMultiplier = 317100; //~1000% 12 Months
        }else if(rewardDuration >= 180 days){
            rewardMultiplier = 158550; //~500% 6 Months
        }else if(rewardDuration >= 90 days){
            rewardMultiplier = 63420; //~200% 3 Months
        }else if (rewardDuration >= 14 days){
            rewardMultiplier = 6342; //~20% 2 Weeks
        }
        else if (rewardDuration < 14 days){
            rewardMultiplier = 634; //~2% Less 2 Weeks
        }
        
        uint256 currentRewardsDuration = block.timestamp-stakingDetails[account].stakedAt;
        if(currentRewardsDuration > rewardDuration){
            currentRewardsDuration = rewardDuration;
        }

        reward = (stakingDetails[account].tokenAmount * currentRewardsDuration * rewardMultiplier) / rewardDivider;
    }
}