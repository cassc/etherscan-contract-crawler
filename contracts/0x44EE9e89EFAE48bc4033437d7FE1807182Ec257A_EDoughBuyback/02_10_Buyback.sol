// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Buyback contract
 * @notice Exchange a buyback token for another token depposited in the contract
 * @author jordaniza
 */
contract Buyback is Ownable, Pausable, ReentrancyGuard  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Variables ========== */

    /** @notice the token that is being bought by the DAO, must have 18 decimals */
    IERC20 public immutable tokenIn;

    /** @notice the token that the user will receive in exchange for tokenIn */
    IERC20 public immutable tokenOut;

    /** 
     * @notice decimals of the tokenIn
     * @dev this must be set to 18 for calculations to work effectively
     */
    uint8 public immutable tokenInDecimals;

    /** @notice decimals of the tokenOut */
    uint8 public immutable tokenOutDecimals;

    /**
     * @notice the current price the DAO will offer for one tokenIn token
     * @param value price expressed to 6 figures of precision.
     * @param deadline latest block.timestamp where the price will be considered valid
     */
    struct Price {
        /*
         *  Price is expressed as x * 10 ** 6
         *  Where x price of 1 buy token
         *  Example: DOUGH is 0.04 USDC
         *  value: 40_000
         */
        uint64 value;
        uint192 deadline;
    }
    Price public price;

    /** @dev divisor after multiplying by price.value */
    uint256 private constant BASE_UNIT = 10**6;

    /* ========== Constructor ========== */

    constructor(
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint8 _tokenOutDecimals
    ) {
        require(
            address(_tokenIn) != address(0) && address(_tokenOut) != address(0),
            "Cannot set tokens to zero address"
        );
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        tokenOutDecimals = _tokenOutDecimals;
        // we force 18 decimals here because it reduces complexity in price calcs
        tokenInDecimals = 18;
    }

    /* ========== Admin Setters ========== */

    /**
     * @notice prevents external methods being executed until `unpause` is called
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice if the contract is paused, calling this will resume calling external methods
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice sets the price for the tokenIn in terms of the tokenOut
     * @param _price 1_000_000 = 1 unit of tokenOut for 1 unit of tokenIn
     * @param _deadline the timestamp after which the price will be considered invalid
     */
    function setPrice(uint64 _price, uint192 _deadline)
        external
        onlyOwner
        whenNotPaused
    {
        require(_price > 0, "Price cannot be zero");
        require(_deadline > block.timestamp, "Invalid deadline");
        price = Price({value: _price, deadline: _deadline});
        emit PriceUpdated(_price, _deadline);
    }

    /* ========== Buyback Mutative Methods ========== */

    /**
     * @notice tops up the contract with tokenOut
     * @dev anyone can call this function
     * @param _quantity the number of tokens to deposit
     */
    function deposit(uint256 _quantity) external whenNotPaused {
        tokenOut.safeTransferFrom(msg.sender, address(this), _quantity);
        emit Deposited(tokenOut, _quantity);
    }

    /**
     * @notice exchanges tokenIn for the tokenOut at the price determined by the contract
     * @dev override to add additional access control restrictions (ie.e whitelisting)
     * @param _tokenInQty number of DOUGH to exchange
     */
    function buyback(uint256 _tokenInQty, address _receiver)
        external
        virtual
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        return _buyback(_tokenInQty, _receiver);
    }

    /**
     * @notice internal method that actions the buyback
     * @dev add reentrancy modifiers to external functions calling this method
     * @dev if _tokenOut balance is too low, will buy what we can at current prices
     * @param _tokenInQty number of tokenIn to exchange
     * @param _receiver address to send tokenOut tokens to
     * @return success     
     */
    function _buyback(uint256 _tokenInQty, address _receiver)
        internal
        returns (bool)
    {
        require(price.deadline > block.timestamp, "Price has expired");

        (uint256 quoteTokenIn, uint256 quoteTokenOut) = getBuybackQuote(
            _tokenInQty
        );
        require(quoteTokenIn > 0, "Nothing to buyback");

        // tokenIn must be approved before executing the Tx
        tokenIn.safeTransferFrom(msg.sender, address(this), quoteTokenIn);
        tokenOut.safeTransfer(_receiver, quoteTokenOut);

        // log the original caller with tx.origin
        emit BuybackProcessed(_receiver, quoteTokenIn, quoteTokenOut);

        return true;
    }

    /**
     * @notice withdraw any tokens in this contract
     * @param _token address of the token to withdraw
     * @param _quantity number of the tokens to withdraw
     */
    function withdraw(IERC20 _token, uint256 _quantity)
        external
        onlyOwner
    {
        _token.safeTransfer(msg.sender, _quantity);
        emit Withdrawn(_token, _quantity);
    }

    /* ========== Getters ========== */

    /**
     * @notice computes quantity of exchangeToken that will be exchanged for a given quantity of DOUGH
     * @param _tokenInQty how many tokens to quote for
     * @return quoteTokenIn how many tokens the contract will buy (will be < tokenInQty if balance is too low)
     * @return quoteTokenOut how many tokenOut the user will receive
     */
    function getBuybackQuote(uint256 _tokenInQty)
        public
        view
        returns (uint256 quoteTokenIn, uint256 quoteTokenOut)
    {
        // check that we have enough tokens to fulfil the entire order, if not quote for what we can
        uint256 maxTokenIn = maxAvailableToBuy();
        quoteTokenIn = maxTokenIn < _tokenInQty ? maxTokenIn : _tokenInQty;
        quoteTokenOut = (quoteTokenIn.mul(price.value)  // price in tokenOut
            .div(BASE_UNIT))                              // scale by price precision 
            .div(_differenceInTokenDecimals());           // reduce decimals to tokenOut.decimals (if needed)
    }

    /**
     * @notice calculates the maximum amount of tokenIn for balance of tokenOut, given price
     * @dev rounding errors in tests have maxed out at about $15 USD
     * @dev if the token balance is >2**238 this function may cause overflow exceptions until tokens withdrawn
     */
    function maxAvailableToBuy() public view returns (uint256) {
        require(price.value > 0, "Price is not set");
        uint256 balance = tokenOut.balanceOf(address(this));
        return
            balance
            .mul(_differenceInTokenDecimals()) // scale up to 18 decimals
            .mul(BASE_UNIT)                    // add 6 decimals of precision
            .div(price.value);                 // price in tokenIn
    }

    /**
     * @notice different token decimals require adjusting so we can normalise calculations
     * @dev this will only work when tokenInDecimals >= tokenOutDecimals, so we force 18 decimals for tokenIn
     */
    function _differenceInTokenDecimals() internal view returns (uint256) {
        return uint256(10)**(tokenInDecimals - tokenOutDecimals);
    }

    /* ========== Events ========== */

    /** @notice emitted when the Price changes */
    event PriceUpdated(uint64 price, uint192 deadline);

    /** @notice emitted when a buyback is actioned */
    event BuybackProcessed(
        address indexed seller,
        uint256 tokenInBought,
        uint256 tokenOutSold
    );

    /** @notice emitted when tokens are withdrawn from the contract by the owner */
    event Withdrawn(IERC20 indexed token, uint256 quantity);

    /** @notice emitted whenever someone uses the deposit helper function to increase the token balance */
    event Deposited(IERC20 indexed token, uint256 quantity);
}