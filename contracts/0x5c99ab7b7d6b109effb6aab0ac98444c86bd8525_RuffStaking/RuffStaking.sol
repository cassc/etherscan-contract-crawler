/**
 *Submitted for verification at Etherscan.io on 2023-07-28
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





pragma solidity >=0.7.0 <0.9.0;



contract RuffStaking is Ownable {

    
    IERC20 public RuffToken;

    bool public RuffstakingClosed = true;

    uint256 public decimalsRuff = 1000000000000000000;
    
    uint256 public RuffPoolStaked = 0;

    uint256 public RuffPoolStakers = 0;

    uint256 public TotalRuffPaid = 0;

 
    uint256 public RuffRewardRate30 = 1 wei;//per day
    uint256 public RuffRewardRate90 = 1 wei;//per day


   

   
    uint256 public unstakePenaltyRuff = 15;//across all pools
   

  

    struct StakerRuff {
        uint256 stakedRuff;
        uint256 stakedSince;
        uint256 stakedTill;
        uint256 RufflastClaim;
        uint256 RuffClaimed;
        uint256 RuffDays;
        bool isStaked;
        uint256 ClaimInterval;
    }

   


   
    mapping(address => StakerRuff) public stakerVaultRuff;
  

    constructor(address _RuffAddress) {
       
        RuffToken = IERC20(_RuffAddress);
        
        
    }

   
    address public ruffWallet = 0xA2B775869ca0CBdaCfe8eA36A043FB221747e91b;


 

//Ruff STAKE
    function stakeRuff(uint256 _amount, uint256 _days) public {
        require(stakerVaultRuff[msg.sender].isStaked == false, "STAKED_IN_POOL");
        require(!RuffstakingClosed, "STAKING_IS_CLOSED_TO_NEW_STAKERS");
        require( _days == 30 || _days == 90, "INVALID_STAKING_DURATION");
        RuffToken.transferFrom(msg.sender, address(this), _amount);
        stakerVaultRuff[msg.sender].stakedRuff += _amount;
        stakerVaultRuff[msg.sender].stakedSince = block.timestamp;
       
        if (_days == 30) {
            stakerVaultRuff[msg.sender].stakedTill = block.timestamp + 30 days;
            stakerVaultRuff[msg.sender].RuffDays = 30;
            stakerVaultRuff[msg.sender].ClaimInterval = block.timestamp + 7 days;
        }
        if (_days == 90) {
            stakerVaultRuff[msg.sender].stakedTill = block.timestamp + 90 days;
            stakerVaultRuff[msg.sender].RuffDays = 90;
            stakerVaultRuff[msg.sender].ClaimInterval = block.timestamp + 7 days;
        }
        stakerVaultRuff[msg.sender].RufflastClaim = block.timestamp;
        stakerVaultRuff[msg.sender].isStaked = true;
        RuffPoolStakers += 1;
        RuffPoolStaked += _amount;
    }





    //UNSTAKE Ruff
    function unStakeRuff() public {

        require(stakerVaultRuff[msg.sender].isStaked == true, "NOT_STAKED");

        if(stakerVaultRuff[msg.sender].stakedTill >= block.timestamp) {
            uint256 stakedTokens = stakerVaultRuff[msg.sender].stakedRuff;
            uint256 penaltyTokens = (stakedTokens * unstakePenaltyRuff) / 100;
            uint256 AfterTaxTotal = stakedTokens - penaltyTokens;
            RuffToken.transfer(msg.sender, AfterTaxTotal);
            RuffToken.transfer(ruffWallet, penaltyTokens);
            RuffPoolStakers -= 1; 
            RuffPoolStaked -= stakerVaultRuff[msg.sender].stakedRuff;
            stakerVaultRuff[msg.sender].stakedRuff = 0;
            stakerVaultRuff[msg.sender].RufflastClaim = 0;
            stakerVaultRuff[msg.sender].isStaked = false;
            stakerVaultRuff[msg.sender].RuffDays = 0;
            stakerVaultRuff[msg.sender].stakedTill = 0;
            stakerVaultRuff[msg.sender].stakedSince = 0;
            stakerVaultRuff[msg.sender].ClaimInterval = 0;
        }

         else if(stakerVaultRuff[msg.sender].stakedTill <= block.timestamp) {
            RuffPoolStaked -= stakerVaultRuff[msg.sender].stakedRuff;
            RuffPoolStakers -= 1;
            uint256 stakedTokens = stakerVaultRuff[msg.sender].stakedRuff;
            RuffToken.transfer(msg.sender, stakedTokens);
            stakerVaultRuff[msg.sender].stakedRuff = 0;
            stakerVaultRuff[msg.sender].RufflastClaim = 0;
            stakerVaultRuff[msg.sender].isStaked = false;
            stakerVaultRuff[msg.sender].RuffDays = 0;
            stakerVaultRuff[msg.sender].stakedTill = 0;
            stakerVaultRuff[msg.sender].stakedSince = 0;
            stakerVaultRuff[msg.sender].ClaimInterval = 0;
   
        }
        
    }



    function claimRuffRewards() public {

    require(stakerVaultRuff[msg.sender].isStaked == true, "NOT_STAKED");
    require(stakerVaultRuff[msg.sender].ClaimInterval <= block.timestamp, "Claim Not Reached Weekly Basis");



    if(stakerVaultRuff[msg.sender].RuffDays == 30){
       
        uint256 reward = ((block.timestamp - stakerVaultRuff[msg.sender].RufflastClaim) * (RuffRewardRate30 / 86400) * stakerVaultRuff[msg.sender].stakedRuff) /decimalsRuff;
        TotalRuffPaid += reward;
        RuffToken.transferFrom(address(this),msg.sender, reward);
        stakerVaultRuff[msg.sender].RufflastClaim = block.timestamp;
        stakerVaultRuff[msg.sender].RuffClaimed += reward;
        stakerVaultRuff[msg.sender].ClaimInterval = block.timestamp + 7 days;
        
    }

    if(stakerVaultRuff[msg.sender].RuffDays == 90){
        uint256 reward = ((block.timestamp - stakerVaultRuff[msg.sender].RufflastClaim) * (RuffRewardRate90 / 86400) * stakerVaultRuff[msg.sender].stakedRuff) / decimalsRuff;
        TotalRuffPaid += reward;
        RuffToken.transferFrom(address(this), msg.sender, reward);
        stakerVaultRuff[msg.sender].RufflastClaim = block.timestamp;
        stakerVaultRuff[msg.sender].RuffClaimed += reward;
        stakerVaultRuff[msg.sender].ClaimInterval = block.timestamp + 7 days;
    }
       
    }

    function disableFees() public onlyOwner {

        unstakePenaltyRuff = 0;
       
    }


    function setFees(uint256 _penaltyRuff) public onlyOwner{

        require(_penaltyRuff <= 20, "fee to high try again 20% max");      
        unstakePenaltyRuff = _penaltyRuff;
       
    }


    function WEIsetRewardRatesPerDayPerTokenStaked(uint256 _RuffRewardRate30, uint256 _RuffRewardRate90) public onlyOwner{
       
        RuffRewardRate30 = _RuffRewardRate30;
        RuffRewardRate90 = _RuffRewardRate90;

       
    }


    function setRuffToken(address _newToken, uint256 _penaltyRuff) public onlyOwner {
        require(_penaltyRuff <= 20, "fee to high try again 20% max");
        RuffToken = IERC20(_newToken);
        RuffPoolStaked = 0;
        RuffPoolStakers = 0;
        TotalRuffPaid = 0;
        unstakePenaltyRuff = _penaltyRuff;


    }

    function setRuffToken(address _newToken) public onlyOwner {
        RuffToken = IERC20(_newToken);
    }


    function setRuffWallet(address _newAddress) public onlyOwner {
        ruffWallet = _newAddress;
    }



    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }


   

    function CloseRuffStaking(bool _state) public onlyOwner {
        RuffstakingClosed = _state;
    }



    function calculateRuffRewards(address staker) public view returns (uint256 _rewards){

        if (stakerVaultRuff[staker].RuffDays == 30) {
           _rewards = ((block.timestamp - stakerVaultRuff[staker].RufflastClaim) * (RuffRewardRate30 / 86400) * stakerVaultRuff[staker].stakedRuff) / decimalsRuff;
             return _rewards;
        }
        if (stakerVaultRuff[staker].RuffDays == 90) {
            
           _rewards = ((block.timestamp - stakerVaultRuff[staker].RufflastClaim) * (RuffRewardRate90 / 86400) * stakerVaultRuff[staker].stakedRuff) / decimalsRuff;
           return _rewards;
           
        }

        
      
    }



    function estimateRuffRewards(address user, uint256 _days) public view returns (uint256 _rewards){

         uint256 tokenAmt;
         tokenAmt = RuffToken.balanceOf(user);

        if (_days == 30) {
          _rewards = ((tokenAmt * RuffRewardRate30) * 30) / decimalsRuff; 
             return _rewards;
        }
        if (_days == 90) {
            
          _rewards = ((tokenAmt * RuffRewardRate90) * 90) / decimalsRuff; 
           return _rewards;
           
        }
      
    }



    function RuffPoolInfo() public view returns (uint256 Stakers, uint256 TokenAmt){

         Stakers = RuffPoolStakers;

         TokenAmt = RuffPoolStaked;

      
    }


     function setDecimalsRuff(uint256 newDecimals) external onlyOwner {
        decimalsRuff = newDecimals;
    }



     receive() external payable {
    }


}