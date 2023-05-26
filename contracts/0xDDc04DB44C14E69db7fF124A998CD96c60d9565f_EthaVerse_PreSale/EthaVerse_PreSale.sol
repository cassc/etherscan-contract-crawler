/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

/*********************************************


//███████╗████████╗██╗░░██╗░█████╗
//██╔════╝╚══██╔══╝██║░░██║██╔══██╗
//█████╗░░░░░██║░░░███████║███████║
//██╔══╝░░░░░██║░░░██╔══██║██╔══██║
//███████╗░░░██║░░░██║░░██║██║░░██║
//╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝

// Token: $ETHA
// Website: https://etha-verse.com
// Telegram: https://t.me/ethaverse
// Twitter: https://twitter.com/etha_verse
// Instagram: https://twitter.com/ethaverse
// Medium: https://medium.com/@ethaverse

*********************************************/

pragma solidity 0.8.20;
// SPDX-License-Identifier: MIT


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return (payable(msg.sender));
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface Token {
  function transfer(address _to, uint256 _value) external  returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  constructor (address _wallet) {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor)public onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() public onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    payable(wallet).transfer(address(this).balance);
  }

  function enableRefunds() public  onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    payable(investor).transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

/// 1. First you set the address of the wallet in the RefundVault contract that will store the deposit of ether
// 2. If the goal is reached, the state of the vault will change and the ether will be sent to the address
// 3. If the goal is not reached , the state of the vault will change to refunding and the users will be able to call claimRefund() to get their ether

/// @title EthaVerse_PreSale contract to carry out an ICO with the EthaVerse Token
/// EthaVerse_PreSale have a start and end timestamps, where investors can make
/// token purchases and the EthaVerse_PreSale will assign them tokens based
/// on a token per ETH rate. Funds collected are forwarded to a wallet
/// as they arrive.
contract EthaVerse_PreSale is Pausable, Ownable {
   using SafeMath for uint256;

   // The token being sold
   Token public token;

   // The vault that will store the ether until the goal is reached
   RefundVault public vault;

   uint256 public startTime = 1684346400; //Wed May 17 2023 18:00:00 UTC

   uint256 public endTime = 1689530400; //Sun Jul 16 2023 18:00:00 UTC

   // The wallet that holds the Wei raised on the crowdsale
   address public wallet;

   // The wallet that holds the Wei raised on the crowdsale after soft cap reached
   address public walletB;

   // The rate of tokens per ether. Only applied for the first tier, the first
   // 500 million tokens sold
   uint256 public rate = 25000000; //1 ETH = 25 Million ETHA tokens

   // The rate of tokens per ether. Only applied for the second tier, at between
   // 500 million tokens sold and upto 1.7 Billion tokens sold
   uint256 public rateTier2 = 24000000;

   // The rate of tokens per ether. Only applied for the third tier, at between
   // 1.7 Billion tokens sold and 4.9 Billion tokens sold
   uint256 public rateTier3 = 20000000;

   // The maximum amount of wei for each tier
   uint256 public limitTier1 = 5e26;
   uint256 public limitTier2 = 17e26;

   // The amount of wei raised
   uint256 public weiRaised = 0;

   // The amount of tokens raised
   uint256 public tokensRaised = 0;

   // You can only buy up to 50 M tokens during the ICO
   uint256 public constant maxTokensRaised = 49e26;

   // The minimum amount of Wei you must pay to participate in the crowdsale
   uint256 public constant minPurchase = 10 ; // 0.01 ether

   // The max amount of Wei that you can pay to participate in the crowdsale
   uint256 public constant maxPurchase = 10 ether;

   // Minimum amount of tokens to be raised. 735,000,000 tokens which is the 15%
   // of the total of 4.9 bIllion tokens sold in the crowdsale 
   uint256 public  minimumGoal = 735e24;

   // If the crowdsale wasn't successful, this will be true and users will be able
   // to claim the refund of their ether
   bool public isRefunding = false;

   // If the crowdsale has ended or not
   bool public isEnded = false;

   // The number of transactions
   uint256 public numberOfTransactions;

   // The gas price to buy tokens must be 85 gwei or below
   uint256 public limitGasPrice = 85000000000 wei;

   // How much each user paid for the crowdsale
   mapping(address => uint256) public crowdsaleBalances;

   // How many tokens each user got for the crowdsale
   mapping(address => uint256) public tokensBought;

   // To indicate who purchased what amount of tokens and who received what amount of wei
   event TokenPurchase(address indexed buyer, uint256 value, uint256 amountOfTokens);

   // Indicates if the crowdsale has ended
   event Finalized();

   // Only allow the execution of the function before the crowdsale starts
   modifier beforeStarting() {
      require(block.timestamp < startTime);
      _;
   }

   /// @notice Constructor of the crowsale to set up the main variables and create a token
   /// @param _wallet The wallet address that stores the Wei raised
   /// @param _walletB The wallet address that stores the Wei raised after soft cap reached
   /// @param _tokenAddress The token used for the ICO
   constructor(
      address _wallet,
      address _walletB,
      address _tokenAddress,
      uint256 _startTime,
      uint256 _endTime
   )  {
      require(_wallet != address(0));
      require(_tokenAddress != address(0));
      require(_walletB != address(0));

      // If you send the start and end time on the constructor, the end must be larger
      if(_startTime > 0 && _endTime > 0)
         require(_startTime < _endTime);

      wallet = _wallet;
      walletB = _walletB;
      token = Token(_tokenAddress);
      vault = new RefundVault(_wallet);

      if(_startTime > 0)
         startTime = _startTime;

      if(_endTime > 0)
         endTime = _endTime;
   }

   /// @notice Fallback function to buy tokens
   fallback () external payable {
      buyTokens();
   }

   /// @notice To buy tokens given an address
   function buyTokens() public payable whenNotPaused {
      require(validPurchase());

      uint256 tokens = 0;
      
      uint256 amountPaid = calculateExcessBalance();

      if(tokensRaised < limitTier1) {

         // Tier 1
         tokens = amountPaid.mul(rate);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier1)
            tokens = calculateExcessTokens(amountPaid, limitTier1, 1, rate);
      } else if(tokensRaised >= limitTier1 && tokensRaised < limitTier2) {

         // Tier 2
         tokens = amountPaid.mul(rateTier2);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier2)
            tokens = calculateExcessTokens(amountPaid, limitTier2, 2, rateTier2);
      } else if(tokensRaised >= limitTier2) {

         // Tier 3
         tokens = amountPaid.mul(rateTier3);
      }

      weiRaised = weiRaised.add(amountPaid);
      uint256 tokensRaisedBeforeThisTransaction = tokensRaised;
      tokensRaised = tokensRaised.add(tokens);
      token.transfer(msg.sender, tokens);

      // Keep a record of how many tokens everybody gets in case we need to do refunds
      tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);
      emit TokenPurchase(msg.sender, amountPaid, tokens);
      numberOfTransactions = numberOfTransactions.add(1);

      if(tokensRaisedBeforeThisTransaction > minimumGoal) {

        payable(walletB).transfer(amountPaid);

      } else {
         vault.deposit{value: amountPaid}(msg.sender);
         if(goalReached()) {
          vault.close();
         }
         
      }

      // If the minimum goal of the ICO has been reach, close the vault to send
      // the ether to the wallet of the crowdsale
      checkCompletedCrowdsale();
   }

   /// @notice Calculates how many ether will be used to generate the tokens in
   /// case the buyer sends more than the maximum balance but has some balance left
   /// and updates the balance of that buyer.
   /// For instance if he's 500 balance and he sends 1000, it will return 500
   /// and refund the other 500 ether
   function calculateExcessBalance() internal whenNotPaused returns(uint256) {
      uint256 amountPaid = msg.value;
      uint256 differenceWei = 0;
      uint256 exceedingBalance = 0;

      // If we're in the last tier, check that the limit hasn't been reached
      // and if so, refund the difference and return what will be used to
      // buy the remaining tokens
      if(tokensRaised >= limitTier2) {
         uint256 addedTokens = tokensRaised.add(amountPaid.mul(rateTier3));

         // If tokensRaised + what you paid converted to tokens is bigger than the max
         if(addedTokens > maxTokensRaised) {

            // Refund the difference
            uint256 difference = addedTokens.sub(maxTokensRaised);
            differenceWei = difference.div(rateTier3);
            amountPaid = amountPaid.sub(differenceWei);
         }
      }

      uint256 addedBalance = crowdsaleBalances[msg.sender].add(amountPaid);

      // Checking that the individual limit of maxPurchase ETH per user is not reached
      if(addedBalance <= maxPurchase) {
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      } else {

         // Substracting ether in wei
         exceedingBalance = addedBalance.sub(maxPurchase);
         amountPaid = amountPaid.sub(exceedingBalance);

         // Add that balance to the balances
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      }

      // Make the transfers at the end of the function for security purposes
      if(differenceWei > 0)
         payable(msg.sender).transfer(differenceWei);

      if(exceedingBalance > 0) {

         // Return the exceeding balance to the buyer
         payable(msg.sender).transfer(exceedingBalance);
      }

      return amountPaid;
   }

   /// @notice Set's the rate of tokens per ether for each tier. Use it after the
   /// smart contract is deployed to set the price according to the ether price
   /// at the start of the ICO
   /// @param tier1 The amount of tokens you get in the tier one
   /// @param tier2 The amount of tokens you get in the tier two
   /// @param tier3 The amount of tokens you get in the tier three
   function setTierRates(uint256 tier1, uint256 tier2, uint256 tier3)
      external onlyOwner whenNotPaused
   {
      require(tier1 > 0 && tier2 > 0 && tier3 > 0 );
      require(tier1 > tier2 && tier2 > tier3  );

      rate = tier1;
      rateTier2 = tier2;
      rateTier3 = tier3;
   }

   /// @notice Allow to extend ICO end date
   /// @param _endTime Endtime of ICO
   function setEndDate(uint256 _endTime)
      external onlyOwner whenNotPaused
   {
      require(block.timestamp <= _endTime);
      require(startTime < _endTime);
      
      endTime = _endTime;
   }

   function updateMinimumGoal (uint256 _mingoal) external onlyOwner whenNotPaused {
      minimumGoal = _mingoal;
   }

   /// @notice Check if the crowdsale has ended and enables refunds only in case the
   /// goal hasn't been reached
   function checkCompletedCrowdsale() public whenNotPaused {
      if(!isEnded) {
         if(hasEnded() && !goalReached()){
            vault.enableRefunds();

            isRefunding = true;
            isEnded = true;
            emit Finalized();
         } else if(hasEnded()  && goalReached()) {

                isEnded = true;
                emit Finalized();
            }  
        }
    }

   /// @notice If crowdsale is unsuccessful, investors can claim refunds here
   function claimRefund() public whenNotPaused {
     require(hasEnded() && !goalReached() && isRefunding);

     vault.refund(msg.sender);
   }

   ///  Buys the tokens for the specified tier and for the next one
   /// @param amount The amount of ether paid to buy the tokens
   /// @param tokensThisTier The limit of tokens of that tier
   /// @param tierSelected The tier selected
   /// @param _rate The rate used for that `tierSelected`
   ///  uint The total amount of tokens bought combining the tier prices
   function calculateExcessTokens(
      uint256 amount,
      uint256 tokensThisTier,
      uint256 tierSelected,
      uint256 _rate
   ) public returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisTier > 0 && _rate > 0);
      require(tierSelected >= 1 && tierSelected <= 3);

      uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
      uint weiNextTier = amount.sub(weiThisTier);
      uint tokensNextTier = 0;
      bool returnTokens = false;

      // If there's excessive wei for the last tier, refund those
      if(tierSelected != 3)
         tokensNextTier = calculateTokensTier(weiNextTier, tierSelected.add(1));
      else
         returnTokens = true;

      totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);

      // Do the transfer at the end
      if(returnTokens) payable(msg.sender).transfer(weiNextTier);
   }

   /// @notice Buys the tokens given the price of the tier one and the wei paid
   /// @param weiPaid The amount of wei paid that will be used to buy tokens
   /// @param tierSelected The tier that you'll use for thir purchase
   /// @return calculatedTokens Returns how many tokens you've bought for that wei paid
   function calculateTokensTier(uint256 weiPaid, uint256 tierSelected)
        internal view returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(tierSelected >= 1 && tierSelected <= 3);

      if(tierSelected == 1)
         calculatedTokens = weiPaid.mul(rate);
      else if(tierSelected == 2)
         calculatedTokens = weiPaid.mul(rateTier2);
      else
         calculatedTokens = weiPaid.mul(rateTier3);
   }


   /// @notice Checks if a purchase is considered valid
   /// @return bool If the purchase is valid or not
   function validPurchase() internal view returns(bool) {
      bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
      bool nonZeroPurchase = msg.value > 0;
      bool withinTokenLimit = tokensRaised < maxTokensRaised;
      bool minimumPurchase = msg.value >= minPurchase;
      bool hasBalanceAvailable = crowdsaleBalances[msg.sender] < maxPurchase;

      // We want to limit the gas to avoid giving priority to the biggest paying contributors
      //bool limitGas = tx.gasprice <= limitGasPrice;

      return withinPeriod && nonZeroPurchase && withinTokenLimit && minimumPurchase && hasBalanceAvailable;
   }

   /// @notice To see if the minimum goal of tokens of the ICO has been reached
   /// @return bool True if the tokens raised are bigger than the goal or false otherwise
   function goalReached() public view returns(bool) {
      return tokensRaised >= minimumGoal;
   }

   /// @notice Public function to check if the crowdsale has ended or not
   function hasEnded() public view returns(bool) {
      return block.timestamp > endTime || tokensRaised >= maxTokensRaised;
   }

   receive () external payable {
   }
}