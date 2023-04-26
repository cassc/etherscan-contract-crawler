// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Crowdsale
 * @dev Borrow from https://github.dev/OpenZeppelin/openzeppelin-contracts/blob/docs-v2.x/contracts/crowdsale/Crowdsale.ol and upgrade to solidity v0.8.0
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	// The token being sold
	IERC20 public _token;

	// The token used to pruchase
	IERC20 public _usdt;

	// Maximum investment per investor (in USDT)
    uint256 public _maxInvestment;

    // Minimum investment per investor (in USDT)
    uint256 public _minInvestment;

	// Address where funds are collected
	address payable public _wallet;

	// How many token units a buyer gets per wei.
	// The rate is the conversion between wei and the smallest and indivisible token unit.
	// So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
	// 1 wei will give you 1 unit, or 0.001 TOK.
	uint256 public _rate;

	// Amount of wei raised
	uint256 public _weiRaised;

	/**
	 * Event for token purchase logging
	 * @param purchaser who paid for the tokens
	 * @param beneficiary who got the tokens
	 * @param value weis paid for purchase
	 * @param amount amount of tokens purchased
	 */
	event TokensPurchased(
		address indexed purchaser,
		address indexed beneficiary,
		uint256 value,
		uint256 amount
	);

	/**
	 * @param rate Number of token units a buyer gets per wei
	 * @dev The rate is the conversion between wei and the smallest and indivisible
	 * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
	 * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
	 * @param wallet Address where collected funds will be forwarded to
	 * @param token Address of the token being sold
	 */
	constructor(
		uint256 rate,
		address payable wallet,
		IERC20 token,
		IERC20 usdt,

		uint256 maxInvestment,
        uint256 minInvestment
	) {
		require(rate > 0, "Crowdsale: rate is 0");
		require(wallet != address(0), "Crowdsale: wallet is the zero address");
		require(
			address(token) != address(0),
			"Crowdsale: token is the zero address"
		);
		require(maxInvestment > 0, "SHIACrowdsale: max investment is 0");
        require(minInvestment > 0, "SHIACrowdsale: min investment is 0");

		_rate = rate;
		_wallet = wallet;
		_token = token;
		_usdt = usdt;
		_maxInvestment = maxInvestment;
        _minInvestment = minInvestment;
	}


	/**
	 * @dev fallback function ***DO NOT OVERRIDE***
	 * Note that other contracts will transfer funds with a base gas stipend
	 * of 2300, which is not enough to call buyTokens. Consider calling
	 * buyTokens directly when purchasing tokens from a contract.
	 */
	// receive() external payable {
	// 	buyTokens(_msgSender());
	// }

	/**
	 * @dev This function updates the minimum investment
	 * This function has a non-reentrancy guard, so it shouldn't be called by
	 * another `nonReentrant` function.
	 * @param newMaxInvestment new max investment required
	 */
	function updateMaximumInvestment(uint256 newMaxInvestment) public onlyOwner nonReentrant  {
		// update rate
		_maxInvestment = newMaxInvestment;
	}

	/**
	 * @dev This function updates the minimum investment
	 * This function has a non-reentrancy guard, so it shouldn't be called by
	 * another `nonReentrant` function.
	 * @param newMinInvesetment new minimum investment required
	 */
	function updateMinimumInvestment(uint256 newMinInvesetment) public onlyOwner nonReentrant  {
		// update rate
		_minInvestment = newMinInvesetment;
	}

	/**
	 * @dev This function chnages the reciepient walet
	 * This function has a non-reentrancy guard, so it shouldn't be called by
	 * another `nonReentrant` function.
	 * @param newWallet New wallet
	 */
	function updateWallet(address payable newWallet) public onlyOwner nonReentrant  {
		// update rate
		_wallet = newWallet;
	}
	
	/**
	 * @dev This function chnages the rate
	 * This function has a non-reentrancy guard, so it shouldn't be called by
	 * another `nonReentrant` function.
	 * @param newRate Value in usdt involved in the purchase
	 */
	function updateRate(uint256 newRate) public onlyOwner nonReentrant  {
		// update rate
		_rate = newRate;
	}


	/**
	 * @dev low level token purchase ***DO NOT OVERRIDE***
	 * This function has a non-reentrancy guard, so it shouldn't be called by
	 * another `nonReentrant` function.
	 * @param beneficiary Recipient of the token purchase
	 * @param usdtAmount Value in usdt involved in the purchase
	 */
	function buyTokens(address beneficiary, uint256 usdtAmount) public nonReentrant {
		_preValidatePurchase(beneficiary, usdtAmount);

		// calculate token amount to be created
		uint256 tokenAmount = _getTokenAmount(usdtAmount);

		// update state
		_weiRaised = _weiRaised + usdtAmount;

		_processPurchase(beneficiary, tokenAmount);
		emit TokensPurchased(_msgSender(), beneficiary, usdtAmount, tokenAmount);

		_updatePurchasingState(beneficiary, usdtAmount);

		_forwardFunds(usdtAmount);
		_postValidatePurchase(beneficiary, usdtAmount);
	}

	/**
	 * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
	 * Use `super` in contracts that inherit from Crowdsale to extend their validations.
	 * Example from CappedCrowdsale.sol's _preValidatePurchase method:
	 *     super._preValidatePurchase(beneficiary, usdtAmount);
	 *     require(weiRaised().add(usdtAmount) <= cap);
	 * @param beneficiary Address performing the token purchase
	 * @param usdtAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address beneficiary, uint256 usdtAmount)
		internal
		view
		virtual
	{
		require(
			beneficiary != address(0),
			"Crowdsale: beneficiary is the zero address"
		);
		require(usdtAmount != 0, "Crowdsale: usdtAmount is 0");
		require(usdtAmount >= _minInvestment, "SHIACrowdsale: investment amount is less than minimum");
        require(usdtAmount <= _maxInvestment, "SHIACrowdsale: investment amount is greater than maximum");

		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
	}

	/**
	 * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
	 * conditions are not met.
	 * @param beneficiary Address performing the token purchase
	 * @param usdtAmount Value in wei involved in the purchase
	 */
	function _postValidatePurchase(address beneficiary, uint256 usdtAmount)
		internal
		view
	{
		// solhint-disable-previous-line no-empty-blocks
	}

	/**
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
	 * its tokens.
	 * @param beneficiary Address performing the token purchase
	 * @param tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address beneficiary, uint256 tokenAmount)
		internal
		virtual
	{
		_token.safeTransfer(beneficiary, tokenAmount);
	}

	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
	 * tokens.
	 * @param beneficiary Address receiving the tokens
	 * @param tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address beneficiary, uint256 tokenAmount)
		internal
	{
		_deliverTokens(beneficiary, tokenAmount);
	}

	/**
	 * @dev Override for extensions that require an internal state to check for validity (current user contributions,
	 * etc.)
	 * @param beneficiary Address receiving the tokens
	 * @param usdtAmount Value in wei involved in the purchase
	 */
	function _updatePurchasingState(address beneficiary, uint256 usdtAmount)
		internal
	{
		// solhint-disable-previous-line no-empty-blocks
	}

	/**
	 * @dev Override to extend the way in which ether is converted to tokens.
	 * @param usdtAmount Value in usdt to be converted into tokens
	 * @return Number of tokens that can be purchased with the specified _weiAmount
	 */
	function _getTokenAmount(uint256 usdtAmount)
		internal
		view
		returns (uint256)
	{
		return usdtAmount * _rate;
	}


	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds(uint256 usdtAmount) internal {
		// conver usdtAmount to kwei because usdt is 6 decimals
		uint256 kweiAmount = usdtAmount / 10 ** 12;
		
		require(_wallet != address(0), "SHIACrowdsale: wallet is the zero address");
        require(_usdt.balanceOf(msg.sender) >= kweiAmount, "SHIACrowdsale: insufficient USDT balance");
        SafeERC20.safeTransferFrom(_usdt, msg.sender, _wallet, kweiAmount);
	}
}