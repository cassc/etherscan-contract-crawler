/**
 *Submitted for verification at Etherscan.io on 2023-08-12
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// File: maxx.sol



pragma solidity >=0.7.0 <0.9.0;



contract MAXXStaking is Ownable {

    IERC20 public maxxToken;

    IERC20 public PwrdToken;
   
    bool public PWRDstakingPaused = true;

    address Dead = 0x000000000000000000000000000000000000dEaD;//DUH ADDRESS
   
    uint256 public PWRDPoolStaked = 1;//total staked Maxx

    uint256 public PWRDPoolExp = block.timestamp;//expiry time of pool 

    uint256 public PWRDPoolTimeRemain = 0;//Remaining Time on pool

    uint256 public PWRPool = 1;// current PWR balance allocation

    uint256 public PWRDPoolStakers = 0;//total stakers

    uint256 public TotalPWRDPaid = 0;//total paid out

    uint256 public lastAction = 0;//last interaction with contract

    uint256 public timeDif = 0;//diff between last action and current timestamp

    uint256 public currentRwdsRate = 0 ;// set rate per token per second

    address public maxxWallet;//fee reciever
 
    uint256 public PWRDFee = 10; // 10% burned at claim

    uint256 public unstakePenaltyPWRD = 15;// Unstake early fee

    uint256 public amtSub = 0; //Amount to Sub



 

   function calculateRwdsPerTknPerSec() internal {
    require(PWRDPoolStaked > 0, "Cannot divide by zero");
    calculateTimeRemain();


    uint256 rawRwdsRate = (PWRPool * 1e18) / (PWRDPoolStaked * PWRDPoolTimeRemain);

    currentRwdsRate = rawRwdsRate;


}




    //update time left in stake
      function calculateTimeRemain() internal {
    
    PWRDPoolTimeRemain = PWRDPoolExp - block.timestamp;
    }


   function viewPotentialDayReturn(address user) public view returns(uint256) {
    uint256 userBal = maxxToken.balanceOf(user);

    uint256 rewardWei = ((((PWRPool * userBal) * 86400) * 30) / (PWRDPoolStaked + userBal));
    return rewardWei;
}


    // update pwr balance
  function subtractPool() internal {
    uint256 currentBal = PWRPool;

    uint256 amtToSubRaw = (PWRDPoolStaked * timeDif * currentRwdsRate);

    uint256 amtToSubWei = amtToSubRaw / 1e18;


    amtSub = amtToSubWei;

    require(currentBal >= amtToSubWei, "Insufficient balance for subtraction");


    PWRPool = currentBal - amtToSubWei;
  }

    struct StakerPWRD {
        uint256 stakedMAXXPWRD;
        uint256 stakedSince;
        uint256 stakedTill;
        uint256 PWRDlastClaim;
        uint256 PWRDClaimed;
        uint256 PWRDDays;
        bool isStaked;
    }

    
    mapping(address => StakerPWRD) public stakerVaultPWRD;
  

    constructor(address _maxxAddress, address _pwrdToken, address _maxxWallet) {
        maxxToken = IERC20(_maxxAddress);
        PwrdToken = IERC20(_pwrdToken);
        maxxWallet = _maxxWallet;
    }


 

//PWRD STAKE
    function stakePWRD(uint256 _amount, uint256 _days) public {
        require(!PWRDstakingPaused, "STAKING_IS_PAUSED");
        require( _days == 15 || _days == 30, "INVALID_STAKING_DURATION");
        maxxToken.approve(address(this), _amount);
        maxxToken.transferFrom(msg.sender, address(this), _amount);
        
        
       
       
        if (_days == 15 && stakerVaultPWRD[msg.sender].isStaked == true) {
            claimPWRDRewards();
            stakerVaultPWRD[msg.sender].stakedMAXXPWRD += _amount;
            stakerVaultPWRD[msg.sender].stakedTill = block.timestamp + 15 days;
            stakerVaultPWRD[msg.sender].PWRDDays = 15;
            stakerVaultPWRD[msg.sender].stakedSince = block.timestamp;
        }

        if (_days == 15 && stakerVaultPWRD[msg.sender].isStaked == false) {
            stakerVaultPWRD[msg.sender].stakedMAXXPWRD += _amount;
            stakerVaultPWRD[msg.sender].stakedTill = block.timestamp + 15 days;
            stakerVaultPWRD[msg.sender].PWRDDays = 15;
            PWRDPoolStakers += 1;
            stakerVaultPWRD[msg.sender].isStaked = true;
            stakerVaultPWRD[msg.sender].stakedSince = block.timestamp;
        }

        if (_days == 30 && stakerVaultPWRD[msg.sender].isStaked == true) {
            claimPWRDRewards();
            stakerVaultPWRD[msg.sender].stakedMAXXPWRD += _amount;
            stakerVaultPWRD[msg.sender].stakedTill = block.timestamp + 30 days;
            stakerVaultPWRD[msg.sender].PWRDDays = 30;
            stakerVaultPWRD[msg.sender].stakedSince = block.timestamp;
        }

         if (_days == 30 && stakerVaultPWRD[msg.sender].isStaked == false) {
            stakerVaultPWRD[msg.sender].stakedMAXXPWRD += _amount;
            stakerVaultPWRD[msg.sender].stakedTill = block.timestamp + 30 days;
            stakerVaultPWRD[msg.sender].PWRDDays = 30;
            PWRDPoolStakers += 1;
            stakerVaultPWRD[msg.sender].isStaked = true;
            stakerVaultPWRD[msg.sender].stakedSince = block.timestamp;
        }


        timeDif = block.timestamp - lastAction;
        stakerVaultPWRD[msg.sender].PWRDlastClaim = block.timestamp;
        PWRDPoolStaked += _amount;
        lastAction = block.timestamp;
        calculateRwdsPerTknPerSec();
        subtractPool();
    }





    //UNSTAKE PWRD
    function unStakePWRD() public {

        require(stakerVaultPWRD[msg.sender].isStaked == true, "NOT_STAKED");

        if(stakerVaultPWRD[msg.sender].stakedTill >= block.timestamp) {
            claimPWRDRewards();
            uint256 stakedTokens = stakerVaultPWRD[msg.sender].stakedMAXXPWRD;
            uint256 penaltyTokens = (stakedTokens * unstakePenaltyPWRD) / 100;
            uint256 AfterTaxTotal = stakedTokens - penaltyTokens;
            maxxToken.transfer(msg.sender, AfterTaxTotal);
            maxxToken.transfer(maxxWallet, penaltyTokens);
            PWRDPoolStakers -= 1; 
            PWRDPoolStaked -= stakerVaultPWRD[msg.sender].stakedMAXXPWRD;
            stakerVaultPWRD[msg.sender].stakedMAXXPWRD = 0;
            stakerVaultPWRD[msg.sender].PWRDlastClaim = 0;
            stakerVaultPWRD[msg.sender].isStaked = false;
            stakerVaultPWRD[msg.sender].PWRDDays = 0;
            stakerVaultPWRD[msg.sender].stakedTill = 0;
            stakerVaultPWRD[msg.sender].stakedSince = 0;
            timeDif = block.timestamp - lastAction;
            lastAction = block.timestamp;
            calculateRwdsPerTknPerSec();
            subtractPool();
        }

         else if(stakerVaultPWRD[msg.sender].stakedTill <= block.timestamp) {
            claimPWRDRewards();
            PWRDPoolStaked -= stakerVaultPWRD[msg.sender].stakedMAXXPWRD;
            PWRDPoolStakers -= 1;
            uint256 stakedTokens = stakerVaultPWRD[msg.sender].stakedMAXXPWRD;
            maxxToken.transfer(msg.sender, stakedTokens);
            stakerVaultPWRD[msg.sender].stakedMAXXPWRD = 0;
            stakerVaultPWRD[msg.sender].PWRDlastClaim = 0;
            stakerVaultPWRD[msg.sender].isStaked = false;
            stakerVaultPWRD[msg.sender].PWRDDays = 0;
            stakerVaultPWRD[msg.sender].stakedTill = 0;
            stakerVaultPWRD[msg.sender].stakedSince = 0;
             timeDif = block.timestamp - lastAction;
            lastAction = block.timestamp;
            calculateRwdsPerTknPerSec();
            subtractPool();
   
        }
        
    }


//claiming rwds
    function claimPWRDRewards() public {

    require(!PWRDstakingPaused, "STAKING_IS_PAUSED");
    require(stakerVaultPWRD[msg.sender].isStaked == true, "NOT_STAKED");


    if(stakerVaultPWRD[msg.sender].PWRDDays == 15){
       
        uint256 reward = (((block.timestamp -  stakerVaultPWRD[msg.sender].PWRDlastClaim) * currentRwdsRate * stakerVaultPWRD[msg.sender].stakedMAXXPWRD) * 80 / 100) / 1000000000000000000;
        TotalPWRDPaid += reward;
        uint256 burnAmount = (reward * PWRDFee) / 100;
        PwrdToken.transfer(Dead,burnAmount);
        reward -= burnAmount;
        PwrdToken.transfer(msg.sender,reward);
        stakerVaultPWRD[msg.sender].PWRDlastClaim = block.timestamp;
        stakerVaultPWRD[msg.sender].PWRDClaimed += reward;
         timeDif = block.timestamp - lastAction;
            lastAction = block.timestamp;
            calculateTimeRemain();
            calculateRwdsPerTknPerSec();
            subtractPool();
    }

    if(stakerVaultPWRD[msg.sender].PWRDDays == 30){
       uint256 reward = ((((block.timestamp -  stakerVaultPWRD[msg.sender].PWRDlastClaim) * currentRwdsRate) * stakerVaultPWRD[msg.sender].stakedMAXXPWRD)) / 1000000000000000000;
        TotalPWRDPaid += reward;
        uint256 burnAmount = (reward * PWRDFee) / 100;
        PwrdToken.transfer(Dead,burnAmount);
        reward -= burnAmount;
         PwrdToken.transfer(msg.sender,reward);
        stakerVaultPWRD[msg.sender].PWRDlastClaim = block.timestamp;
        stakerVaultPWRD[msg.sender].PWRDClaimed += reward;
        timeDif = block.timestamp - lastAction;
            lastAction = block.timestamp;
            calculateRwdsPerTknPerSec();
            subtractPool();
    }
       
    }

     function viewRewardsEst(address user) public view returns(uint256){
       uint256 reward = ((((block.timestamp -  stakerVaultPWRD[user].PWRDlastClaim) * currentRwdsRate) * stakerVaultPWRD[user].stakedMAXXPWRD)) / 1000000000000000000;
       return reward;
    }


    function disableFees() public onlyOwner {
        PWRDFee = 0;
        unstakePenaltyPWRD = 0;
    }


    function setFees(uint256 _PWRDFee, uint256 _penaltyPWRD) public onlyOwner{
       
        require(_PWRDFee <= 20, "fee to high try again 20% max");
        require(_penaltyPWRD <= 20, "fee to high try again 20% max");      
        PWRDFee = _PWRDFee;
        unstakePenaltyPWRD = _penaltyPWRD;
       
    }

    //Deposit PWR into contract
    function DepositPWRDInWEI(uint256 amount) external onlyOwner {
        PwrdToken.approve(address(this), amount);
        PwrdToken.transferFrom(msg.sender,address(this),amount);
        PWRPool += amount;
        timeDif = block.timestamp - lastAction;
        lastAction = block.timestamp;
        calculateRwdsPerTknPerSec();
     
    }

    //set pool expiry date in timestamp
    function SetExpiryOnStake(uint256 blocktimestamp) external onlyOwner{
        PWRDPoolExp = blocktimestamp;
        timeDif = block.timestamp - lastAction;
        lastAction = block.timestamp;
        calculateRwdsPerTknPerSec();
        
    }


    function setMAXXToken(address _newToken) public onlyOwner {
        maxxToken = IERC20(_newToken);
    }


    function setMAXXWallet(address _newAddress) public onlyOwner {
        maxxWallet = _newAddress;
    }



    function withdrawPWRorETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
        
    }


    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        PWRPool -= _tokenAmount;
        timeDif = block.timestamp - lastAction;
        lastAction = block.timestamp;
        calculateRwdsPerTknPerSec();


    }


    function pausePWRDStaking(bool _state) public onlyOwner {
        PWRDstakingPaused = _state;
        
    }


    function PWRDPoolInfo() public view returns (uint256 Stakers, uint256 TokenAmt){

         Stakers = PWRDPoolStakers;

         TokenAmt = PWRDPoolStaked;
   
    }

    receive() external payable {

    }


}