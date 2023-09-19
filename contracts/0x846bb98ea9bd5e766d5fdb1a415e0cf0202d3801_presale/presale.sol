/**
 *Submitted for verification at Etherscan.io on 2023-08-04
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: github/OpenZeppelin/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
// File: github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts/ico-eth.sol



pragma solidity ^0.6.12;





interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
    function transfer(address to, uint256 value) external;
}

contract presale is ReentrancyGuard {
    
    using SafeMath for uint256;
    AggregatorV3Interface internal price_feed;

    //buyers
    struct buyer {
        uint256 bnb_sent;
        uint256 usdt_sent;
        uint256 tokens_purchased;
        address buyer_address;
        uint256 claimed_tokens;
    }

    IERC20 public token_contract;

    address public presale_owner;

    uint256 public total_investors;
    uint256 public total_bnb_received;
    uint256 public total_usdt_received;
    uint256 public total_tokens_sent;

    uint256 public tokens_for_presale_left;
    uint256 public tokens_for_presale;

    uint256 public ratePresale; //listing price in wei
    uint256 public ratePresaleStable;

    bool public presaleEnded;
    bool public claimOpened;

    mapping(address => buyer) public buyers;

    address public token_usdt;
    IERC20 public token_usd;

    address payable private payment_wallet = 0x30f8AF0Bc036A40E5AAaA3C6fADc6d924e6c0Cb4;

    constructor() public {

        price_feed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        token_usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        token_usd = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        tokens_for_presale = 2100000000000000000000000;
        tokens_for_presale_left = tokens_for_presale;
        ratePresale = 230000000000000000;
        ratePresaleStable = 230000000000;
        presale_owner = msg.sender;
    }

    receive() external payable {}

    //ETH or BNB
    function buyTokensNative() public payable nonReentrant {

        require(msg.value > 0, "Must send BNB");
        
        uint ethUSD = get_feed_price();
        uint256 usdtAmount = msg.value.mul(ethUSD);
        uint256 amount_receieved = msg.value;

        require(!presaleEnded, "Presale has ended");

        uint256 tokens_purchased = usdtAmount * 10 ** 18; 
        tokens_purchased = tokens_purchased.div(ratePresale);

        buyers[msg.sender].bnb_sent += amount_receieved;
        buyers[msg.sender].tokens_purchased += tokens_purchased;
        buyers[msg.sender].buyer_address = msg.sender;

        total_bnb_received += amount_receieved;
        tokens_for_presale_left -= tokens_purchased;
        total_investors++;

        if(tokens_for_presale_left <= 0) {
            presaleEnded = true;
        }

        payment_wallet.transfer(address(this).balance);

        emit boughtTokens(amount_receieved, tokens_purchased, total_bnb_received);
    }

    //USDT
    function buyTokensUSDT(uint256 usdtAmount) public payable nonReentrant {
         
        require(usdtAmount > 0, "Must send USDT");

        require(!presaleEnded, "Presale has ended");

        uint256 tokens_purchased = usdtAmount * 10 ** 6; 
        tokens_purchased = tokens_purchased * 10 ** 18;
        tokens_purchased = tokens_purchased.div(ratePresaleStable);

        buyers[msg.sender].usdt_sent += usdtAmount * 10 ** 12; //convert to wei
        buyers[msg.sender].tokens_purchased += tokens_purchased;
        buyers[msg.sender].buyer_address = msg.sender;

        total_usdt_received += usdtAmount;
        tokens_for_presale_left -= tokens_purchased;
        total_investors++;

        if(tokens_for_presale_left <= 0) {
            presaleEnded = true;
        }

        IERC20_USDT(address(token_usdt)).transferFrom(msg.sender, payment_wallet, usdtAmount);

        emit boughtTokensUsdt(usdtAmount, tokens_purchased, total_usdt_received);
    }

    //either BUSD or USDC
    function buyTokensUSD(uint256 usdAmount) public payable nonReentrant {
        
        require(usdAmount > 0, "Must send USDC");

        require(!presaleEnded, "Presale has ended");

        uint256 tokens_purchased = usdAmount * 10 ** 6; 
        tokens_purchased = tokens_purchased * 10 ** 18;
        tokens_purchased = tokens_purchased.div(ratePresaleStable);

        buyers[msg.sender].usdt_sent += usdAmount * 10 ** 12; //convert to wei
        buyers[msg.sender].tokens_purchased += tokens_purchased;
        buyers[msg.sender].buyer_address = msg.sender;

        total_usdt_received += usdAmount;
        tokens_for_presale_left -= tokens_purchased;
        total_investors++;

        if(tokens_for_presale_left <= 0) {
            presaleEnded = true;
        }

        token_usd.transferFrom(msg.sender, payment_wallet, usdAmount);

        emit boughtTokensUsd(usdAmount, tokens_purchased, total_usdt_received);
    }

    //claim tokens
    function claimTokens() external payable nonReentrant {

        //check not cancelled
        require(claimOpened, "Claiming not opened.");

        //check claimant is valid
        require(isAddressInvestor(msg.sender) > 0, "Address not invested.");

        //check if address has already claimed
        require(isAddressClaimed(msg.sender) == 0, "This address has already claimed.");

        //allow to claim tokens
        distributeTokens(isAddressInvestor(msg.sender));
    }

    //is address invested
    function isAddressInvestor(address _wallet) public view returns (uint256) {
        return buyers[_wallet].tokens_purchased;
    }

    //is address claimed
    function isAddressClaimed(address _wallet) public view returns (uint256) {
        return buyers[_wallet].claimed_tokens;
    }

    function distributeTokens(uint256 tokens_to_send) internal {

        uint256 tokenBalance = token_contract.balanceOf(address(this));

        require(tokens_to_send <= tokenBalance, "Not enough tokens to claim.");

        token_contract.transfer(msg.sender, tokens_to_send);
        total_tokens_sent += tokens_to_send;
        buyers[msg.sender].claimed_tokens = tokens_to_send;
    }

    function resetBuyer(address investor, uint256 amount) external owner {

        buyers[investor].tokens_purchased = amount;
        buyers[investor].claimed_tokens = 0;
    }

    function newRound(uint256 _tokens_for_round, uint256 _rate, uint256 _rateStable) external owner {

        tokens_for_presale = tokens_for_presale.add(_tokens_for_round);
        tokens_for_presale_left = _tokens_for_round;
        ratePresale = _rate;
        ratePresaleStable = _rateStable;
    }

    function fund(address payable _to) external owner {

         _to.transfer(address(this).balance);
    }

    function fundTokens(address _contract, address _to) external owner {

         uint256 tokenBalance = IERC20(_contract).balanceOf(address(this));

         require(tokenBalance > 0, "No tokens available.");

         IERC20(_contract).transfer(_to, tokenBalance);
    }

    function fundUsdt(address _to) external owner {

         uint256 tokenBalance = IERC20(token_usdt).balanceOf(address(this));

         require(tokenBalance > 0, "No tokens available.");
         
         IERC20_USDT(address(token_usdt)).transfer(_to, tokenBalance);
    }

    function updateClaimOpened(bool _opened) external owner {

        claimOpened = _opened;
    }

    function updateSaleEnded(bool _ended) external owner {

        presaleEnded = _ended;
    }

    function updateTokensForSale(uint256 _amount) external owner {

        tokens_for_presale = _amount;
    }

    function updateRatePresale(uint256 _rate, uint256 _rateStable) external owner {

        ratePresale = _rate;
        ratePresaleStable = _rateStable;
    }

    function updateTokensLeft(uint256 _amount) external owner {

        tokens_for_presale_left = _amount;
    }

    function updateTokenContract(address _contract) external owner {
        
        token_contract = IERC20(_contract);
    }

    function get_amount_of_tokens_native(uint256 amount) public view returns (uint256) {

        uint ethUSD = get_feed_price();
        uint256 usdtAmount = amount.mul(ethUSD);
        uint256 tokens_purchased = usdtAmount * 10 ** 18; 
        tokens_purchased = tokens_purchased.div(ratePresale);

        return tokens_purchased;
    }

    function get_amount_of_tokens_usd(uint256 amount) public view returns (uint256) {

        uint256 tokens_purchased = amount * 10 ** 6; 
        tokens_purchased = tokens_purchased * 10 ** 18;
        tokens_purchased = tokens_purchased.div(ratePresaleStable);

        return tokens_purchased;
    }

    function updateFromNoneLaunchChainNative(address[] calldata _buyers, uint256[] calldata _buys, uint256[] calldata _tokens) external owner {
        
        require(_buyers.length == _buys.length, "Users does not match deposits");
        require(_buyers.length == _tokens.length, "Users does not match tokens");
        
        for(uint256 i = 0; i < _buyers.length; i++) {
            buyers[_buyers[i]].bnb_sent += _buys[i];
            buyers[_buyers[i]].tokens_purchased += _tokens[i];
            buyers[_buyers[i]].buyer_address = _buyers[i];
        }
    }

     function updateFromNoneLaunchChainUsd(address[] calldata _buyers, uint256[] calldata _buys, uint256[] calldata _tokens) external owner {
        
        require(_buyers.length == _buys.length, "Users does not match deposits");
        require(_buyers.length == _tokens.length, "Users does not match tokens");
        
        for(uint256 i = 0; i < _buyers.length; i++) {
            buyers[_buyers[i]].usdt_sent += _buys[i];
            buyers[_buyers[i]].tokens_purchased += _tokens[i];
            buyers[_buyers[i]].buyer_address = _buyers[i];
        }
    }

    function get_feed_price() public view returns (uint) {

        (
            uint80 feed_roundID, 
            int feed_price,
            uint feed_startedAt,
            uint feed_timeStamp,
            uint80 feed_answeredInRound
        ) = price_feed.latestRoundData();

        uint adjustmentPrice = uint(feed_price) / 10 ** 8;

        return adjustmentPrice;
    }

    modifier owner {

        bool isOwner = false;

        if(msg.sender == presale_owner) {
            isOwner = true;
        }

        require(isOwner == true, "Requires owner");

        _;
    }

    event boughtTokens(uint256 paid, uint256 tokens, uint256 raised);
    event boughtTokensUsdt(uint256 usdtAmount, uint256 tokens_purchased, uint256 total_usdt_received);
    event boughtTokensUsd(uint256 usdAmount, uint256 tokens_purchased, uint256 total_usdt_received);
}