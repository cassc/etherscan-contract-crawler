/**
 *Submitted for verification at BscScan.com on 2023-04-25
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
    IERC20 public PWRDToken;
   

    
    bool public PWRDstakingPaused = true;
   

    
    uint256 public decimalsPWRD = 100000000000000000;
    uint256 public decimalsMAXX = 100000000000000000;
   

   
    uint256 public PWRDPoolStaked = 0;

    uint256 public PWRDPoolStakers = 0;

    uint256 public TotalPWRDPaid = 0;

    address public maxxWallet;
 
    uint256 public PWRDFee = 10; // 10% burned at claim


    uint256 public PWRDRewardRate15 = 1 wei;//per day
    uint256 public PWRDRewardRate30 = 1 wei;//per day


   

   
    uint256 public unstakePenaltyPWRD = 15;//across all pools
   

  

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
  

    constructor(address _maxxAddress, address _PWRDAddress, address _maxxWallet) {
        maxxToken = IERC20(_maxxAddress);
        PWRDToken = IERC20(_PWRDAddress);
        
        maxxWallet = _maxxWallet;
    }


 

//PWRD STAKE
    function stakePWRD(uint256 _amount, uint256 _days) public {
        require(stakerVaultPWRD[msg.sender].isStaked == false, "STAKED_IN_POOL");
        require(!PWRDstakingPaused, "STAKING_IS_PAUSED");
        require( _days == 15 || _days == 30, "INVALID_STAKING_DURATION");
        maxxToken.transferFrom(msg.sender, address(this), _amount);
        stakerVaultPWRD[msg.sender].stakedMAXXPWRD += _amount;
        stakerVaultPWRD[msg.sender].stakedSince = block.timestamp;
       
        if (_days == 15) {
            stakerVaultPWRD[msg.sender].stakedTill = block.timestamp + 15 days;
            stakerVaultPWRD[msg.sender].PWRDDays = 15;
        }
        if (_days == 30) {
            stakerVaultPWRD[msg.sender].stakedTill = block.timestamp + 30 days;
            stakerVaultPWRD[msg.sender].PWRDDays = 30;
        }
        stakerVaultPWRD[msg.sender].PWRDlastClaim = block.timestamp;
        stakerVaultPWRD[msg.sender].isStaked = true;
        PWRDPoolStakers += 1;
        PWRDPoolStaked += _amount;
    }





    //UNSTAKE PWRD
    function unStakePWRD() public {

        require(stakerVaultPWRD[msg.sender].isStaked == true, "NOT_STAKED");

        if(stakerVaultPWRD[msg.sender].stakedTill >= block.timestamp) {
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
        }

         else if(stakerVaultPWRD[msg.sender].stakedTill <= block.timestamp) {
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
   
        }
        
    }



    function claimPWRDRewards() public {

    require(!PWRDstakingPaused, "STAKING_IS_PAUSED");
    require(stakerVaultPWRD[msg.sender].isStaked == true, "NOT_STAKED");


    if(stakerVaultPWRD[msg.sender].PWRDDays == 15){
       
        uint256 reward = ((block.timestamp - stakerVaultPWRD[msg.sender].PWRDlastClaim) * (PWRDRewardRate15 / 86400) * stakerVaultPWRD[msg.sender].stakedMAXXPWRD) /decimalsPWRD;
        TotalPWRDPaid += reward;
        uint256 burnAmount = (reward * PWRDFee) / 100;
        PWRDToken.transfer(maxxWallet, burnAmount); 
        reward -= burnAmount;
        PWRDToken.transfer(msg.sender, reward);
        stakerVaultPWRD[msg.sender].PWRDlastClaim = block.timestamp;
        stakerVaultPWRD[msg.sender].PWRDClaimed += reward;
    }

    if(stakerVaultPWRD[msg.sender].PWRDDays == 30){
        uint256 reward = ((block.timestamp - stakerVaultPWRD[msg.sender].PWRDlastClaim) * (PWRDRewardRate30 / 86400) * stakerVaultPWRD[msg.sender].stakedMAXXPWRD) / decimalsPWRD;
        TotalPWRDPaid += reward;
        uint256 burnAmount = (reward * PWRDFee) / 100;
        PWRDToken.transfer(maxxWallet, burnAmount); 
        reward -= burnAmount;
        PWRDToken.transfer(msg.sender, reward);
        stakerVaultPWRD[msg.sender].PWRDlastClaim = block.timestamp;
        stakerVaultPWRD[msg.sender].PWRDClaimed += reward;
    }
       
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


    function WEIsetRewardRatesPerDayPerTokenStaked(uint256 _PWRDRewardRate15, uint256 _PWRDRewardRate30) public onlyOwner{
       
        PWRDRewardRate15 = _PWRDRewardRate15;
        PWRDRewardRate30 = _PWRDRewardRate30;

       
    }


    function setPWRDToken(address _newToken, uint256 _PWRDFee, uint256 _penaltyPWRD) public onlyOwner {
        require(_PWRDFee <= 20, "fee to high try again 20% max");
        require(_penaltyPWRD <= 20, "fee to high try again 20% max");
        PWRDToken = IERC20(_newToken);
        PWRDPoolStaked = 0;
        PWRDPoolStakers = 0;
        TotalPWRDPaid = 0;
        PWRDFee = _PWRDFee;
        unstakePenaltyPWRD = _penaltyPWRD;


    }


   


    function setMAXXToken(address _newToken) public onlyOwner {
        maxxToken = IERC20(_newToken);
    }


    function setMAXXWallet(address _newAddress) public onlyOwner {
        maxxWallet = _newAddress;
    }



    function withdrawPOM() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }


   

    function pausePWRDStaking(bool _state) public onlyOwner {
        PWRDstakingPaused = _state;
        unstakePenaltyPWRD = 0;
    }



    function calculatePWRDRewards(address staker) public view returns (uint256 _rewards){

        if (stakerVaultPWRD[staker].PWRDDays == 15) {
           _rewards = ((block.timestamp - stakerVaultPWRD[staker].PWRDlastClaim) * (PWRDRewardRate15 / 86400) * stakerVaultPWRD[staker].stakedMAXXPWRD) / decimalsPWRD;
             return _rewards;
        }
        if (stakerVaultPWRD[staker].PWRDDays == 30) {
            
           _rewards = ((block.timestamp - stakerVaultPWRD[staker].PWRDlastClaim) * (PWRDRewardRate30 / 86400) * stakerVaultPWRD[staker].stakedMAXXPWRD) / decimalsPWRD;
           return _rewards;
           
        }

        
      
    }



    function estimatePWRDRewards(address user, uint256 _days) public view returns (uint256 _rewards){

         uint256 tokenAmt;
         tokenAmt = maxxToken.balanceOf(user);

        if (_days == 15) {
          _rewards = ((tokenAmt * PWRDRewardRate15) * 15) / decimalsPWRD; 
             return _rewards;
        }
        if (_days == 30) {
            
          _rewards = ((tokenAmt * PWRDRewardRate30) * 30) / decimalsPWRD; 
           return _rewards;
           
        }
      
    }



    function PWRDPoolInfo() public view returns (uint256 Stakers, uint256 TokenAmt){

         Stakers = PWRDPoolStakers;

         TokenAmt = PWRDPoolStaked;

      
    }



     receive() external payable {
    }


}