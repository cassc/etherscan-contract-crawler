// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../utils/DSMath.sol";
import "../utils/BancorFormula.sol";
import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";
import "../utils/DAOUpgradeableContract.sol";

/**
@title Dynamic reserve ratio market maker
*/
contract GoodMarketMaker is DAOUpgradeableContract, DSMath {
	// Entity that holds a reserve token
	struct ReserveToken {
		// Determines the reserve token balance
		// that the reserve contract holds
		uint256 reserveSupply;
		// Determines the current ratio between
		// the reserve token and the GD token
		uint32 reserveRatio;
		// How many GD tokens have been minted
		// against that reserve token
		uint256 gdSupply;
		// Last time reserve ratio was expanded
		uint256 lastExpansion;
	}

	// The map which holds the reserve token entities
	mapping(address => ReserveToken) public reserveTokens;

	// Emits when a change has occurred in a
	// reserve balance, i.e. buy / sell will
	// change the balance
	event BalancesUpdated(
		// The account who initiated the action
		address indexed caller,
		// The address of the reserve token
		address indexed reserveToken,
		// The incoming amount
		uint256 amount,
		// The return value
		uint256 returnAmount,
		// The updated total supply
		uint256 totalSupply,
		// The updated reserve balance
		uint256 reserveBalance
	);

	// Emits when the ratio changed. The caller should be the Avatar by definition
	event ReserveRatioUpdated(address indexed caller, uint256 nom, uint256 denom);

	// Defines the daily change in the reserve ratio in RAY precision.
	// In the current release, only global ratio expansion is supported.
	// That will be a part of each reserve token entity in the future.
	uint256 public reserveRatioDailyExpansion;

	//goodDollar token decimals
	uint256 decimals;

	/**
	 * @dev Constructor
	 * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
	 * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
	 */
	function initialize(
		INameService _ns,
		uint256 _nom,
		uint256 _denom
	) public virtual initializer {
		reserveRatioDailyExpansion = (_nom * 1e27) / _denom;
		decimals = 2;
		setDAO(_ns);
	}

	function _onlyActiveToken(ERC20 _token) internal view {
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		require(rtoken.gdSupply > 0, "Reserve token not initialized");
	}

	function _onlyReserveOrAvatar() internal view {
		require(
			nameService.getAddress("RESERVE") == msg.sender ||
				nameService.getAddress("AVATAR") == msg.sender,
			"GoodMarketMaker: not Reserve or Avatar"
		);
	}

	function getBancor() public view returns (BancorFormula) {
		return BancorFormula(nameService.getAddress("BANCOR_FORMULA"));
	}

	/**
	 * @dev Allows the DAO to change the daily expansion rate
	 * it is calculated by _nom/_denom with e27 precision. Emits
	 * `ReserveRatioUpdated` event after the ratio has changed.
	 * Only Avatar can call this method.
	 * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
	 * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
	 */
	function setReserveRatioDailyExpansion(uint256 _nom, uint256 _denom) public {
		_onlyReserveOrAvatar();
		require(_denom > 0, "denominator must be above 0");
		reserveRatioDailyExpansion = (_nom * 1e27) / _denom;
		require(reserveRatioDailyExpansion < 1e27, "Invalid nom or denom value");
		emit ReserveRatioUpdated(msg.sender, _nom, _denom);
	}

	// NOTICE: In the current release, if there is a wish to add another reserve token,
	//  `end` method in the reserve contract should be called first. Then, the DAO have
	//  to deploy a new reserve contract that will own the market maker. A scheme for
	// updating the new reserve must be deployed too.

	/**
	 * @dev Initialize a reserve token entity with the given parameters
	 * @param _token The reserve token
	 * @param _gdSupply Initial supply of GD to set the price
	 * @param _tokenSupply Initial supply of reserve token to set the price
	 * @param _reserveRatio The starting reserve ratio
	 * @param _lastExpansion Last time reserve ratio was expanded
	 */
	function initializeToken(
		ERC20 _token,
		uint256 _gdSupply,
		uint256 _tokenSupply,
		uint32 _reserveRatio,
		uint256 _lastExpansion
	) public {
		_onlyReserveOrAvatar();
		reserveTokens[address(_token)] = ReserveToken({
			gdSupply: _gdSupply,
			reserveSupply: _tokenSupply,
			reserveRatio: _reserveRatio,
			lastExpansion: _lastExpansion == 0 ? block.timestamp : _lastExpansion
		});
	}

	/**
	 * @dev Calculates how much to decrease the reserve ratio for _token by
	 * the `reserveRatioDailyExpansion`
	 * @param _token The reserve token to calculate the reserve ratio for
	 * @return The new reserve ratio
	 */
	function calculateNewReserveRatio(ERC20 _token) public view returns (uint32) {
		ReserveToken memory reserveToken = reserveTokens[address(_token)];
		uint256 ratio = uint256(reserveToken.reserveRatio);
		if (ratio == 0) {
			ratio = 1e6;
		}
		ratio *= 1e21; //expand to e27 precision

		uint256 daysPassed = (block.timestamp - reserveToken.lastExpansion) /
			1 days;
		for (uint256 i = 0; i < daysPassed; i++) {
			ratio = (ratio * reserveRatioDailyExpansion) / 1e27;
		}

		return uint32(ratio / 1e21); // return to e6 precision
	}

	/**
	 * @dev Decreases the reserve ratio for _token by the `reserveRatioDailyExpansion`
	 * @param _token The token to change the reserve ratio for
	 * @return The new reserve ratio
	 */
	function expandReserveRatio(ERC20 _token) public returns (uint32) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		ReserveToken storage reserveToken = reserveTokens[address(_token)];
		uint32 ratio = reserveToken.reserveRatio;
		if (ratio == 0) {
			ratio = 1e6;
		}
		reserveToken.reserveRatio = calculateNewReserveRatio(_token);

		//set last expansion to begining of expansion day
		reserveToken.lastExpansion =
			block.timestamp -
			((block.timestamp - reserveToken.lastExpansion) % 1 days);
		return reserveToken.reserveRatio;
	}

	/**
	 * @dev Calculates the buy return in GD according to the given _tokenAmount
	 * @param _token The reserve token buying with
	 * @param _tokenAmount The amount of reserve token buying with
	 * @return Number of GD that should be given in exchange as calculated by the bonding curve
	 */
	function buyReturn(ERC20 _token, uint256 _tokenAmount)
		public
		view
		returns (uint256)
	{
		ReserveToken memory rtoken = reserveTokens[address(_token)];
		return
			getBancor().calculatePurchaseReturn(
				rtoken.gdSupply,
				rtoken.reserveSupply,
				rtoken.reserveRatio,
				_tokenAmount
			);
	}

	/**
	 * @dev Calculates the sell return in _token according to the given _gdAmount
	 * @param _token The desired reserve token to have
	 * @param _gdAmount The amount of GD that are sold
	 * @return Number of tokens that should be given in exchange as calculated by the bonding curve
	 */
	function sellReturn(ERC20 _token, uint256 _gdAmount)
		public
		view
		returns (uint256)
	{
		ReserveToken memory rtoken = reserveTokens[address(_token)];
		return
			getBancor().calculateSaleReturn(
				rtoken.gdSupply,
				rtoken.reserveSupply,
				rtoken.reserveRatio,
				_gdAmount
			);
	}

	/**
	 * @dev Updates the _token bonding curve params. Emits `BalancesUpdated` with the
	 * new reserve token information.
	 * @param _token The reserve token buying with
	 * @param _tokenAmount The amount of reserve token buying with
	 * @return (gdReturn) Number of GD that will be given in exchange as calculated by the bonding curve
	 */
	function buy(ERC20 _token, uint256 _tokenAmount) public returns (uint256) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);

		uint256 gdReturn = buyReturn(_token, _tokenAmount);
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		rtoken.gdSupply += gdReturn;
		rtoken.reserveSupply += _tokenAmount;
		emit BalancesUpdated(
			msg.sender,
			address(_token),
			_tokenAmount,
			gdReturn,
			rtoken.gdSupply,
			rtoken.reserveSupply
		);
		return gdReturn;
	}

	/**
	 * @dev Updates the bonding curve params. Decrease RR to in order to mint gd in the amount of provided
	 * new RR = Reserve supply / ((gd supply + gd mint amount) * price)
	 * @param _gdAmount Amount of gd to add reserveParams
	 * @param _token The reserve token which is currently active
	 */
	function mintFromReserveRatio(ERC20 _token, uint256 _gdAmount) public {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		uint256 reserveDecimalsDiff = uint256(27) - _token.decimals(); // //result is in RAY precision
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		uint256 priceBeforeGdSupplyChange = currentPrice(_token);
		rtoken.gdSupply += _gdAmount;
		rtoken.reserveRatio = uint32(
			((rtoken.reserveSupply * 1e27) /
				(rtoken.gdSupply * priceBeforeGdSupplyChange)) / 10**reserveDecimalsDiff
		); // Divide it decimal diff to bring it proper decimal
	}

	/**
	 * @dev Calculates the sell return with contribution in _token and update the bonding curve params.
	 * Emits `BalancesUpdated` with the new reserve token information.
	 * @param _token The desired reserve token to have
	 * @param _gdAmount The amount of GD that are sold
	 * @param _contributionGdAmount The number of GD tokens that will not be traded for the reserve token
	 * @return Number of tokens that will be given in exchange as calculated by the bonding curve
	 */
	function sellWithContribution(
		ERC20 _token,
		uint256 _gdAmount,
		uint256 _contributionGdAmount
	) public returns (uint256) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);

		require(
			_gdAmount >= _contributionGdAmount,
			"GD amount is lower than the contribution amount"
		);
		ReserveToken storage rtoken = reserveTokens[address(_token)];
		require(
			rtoken.gdSupply >= _gdAmount,
			"GD amount is higher than the total supply"
		);

		// Deduces the convertible amount of GD tokens by the given contribution amount
		uint256 amountAfterContribution = _gdAmount - _contributionGdAmount;

		// The return value after the deduction
		uint256 tokenReturn = sellReturn(_token, amountAfterContribution);
		rtoken.gdSupply -= _gdAmount;
		rtoken.reserveSupply -= tokenReturn;
		emit BalancesUpdated(
			msg.sender,
			address(_token),
			_contributionGdAmount,
			tokenReturn,
			rtoken.gdSupply,
			rtoken.reserveSupply
		);
		return tokenReturn;
	}

	/**
	 * @dev Current price of GD in `token`. currently only cDAI is supported.
	 * @param _token The desired reserve token to have
	 * @return price of GD
	 */
	function currentPrice(ERC20 _token) public view returns (uint256) {
		ReserveToken memory rtoken = reserveTokens[address(_token)];
		return
			getBancor().calculateSaleReturn(
				rtoken.gdSupply,
				rtoken.reserveSupply,
				rtoken.reserveRatio,
				(10**decimals)
			);
	}

	//TODO: need real calculation and tests
	/**
	 * @dev Calculates how much G$ to mint based on added token supply (from interest)
	 * and on current reserve ratio, in order to keep G$ price the same at the bonding curve
	 * formula to calculate the gd to mint: gd to mint =
	 * addreservebalance * (gdsupply / (reservebalance * reserveratio))
	 * @param _token the reserve token
	 * @param _addTokenSupply amount of token added to supply
	 * @return how much to mint in order to keep price in bonding curve the same
	 */
	function calculateMintInterest(ERC20 _token, uint256 _addTokenSupply)
		public
		view
		returns (uint256)
	{
		uint256 decimalsDiff = uint256(27) - decimals;
		//resulting amount is in RAY precision
		//we divide by decimalsdiff to get precision in GD (2 decimals)
		return
			((_addTokenSupply * 1e27) / currentPrice(_token)) / (10**decimalsDiff);
	}

	/**
	 * @dev Updates bonding curve based on _addTokenSupply and new minted amount
	 * @param _token The reserve token
	 * @param _addTokenSupply Amount of token added to supply
	 * @return How much to mint in order to keep price in bonding curve the same
	 */
	function mintInterest(ERC20 _token, uint256 _addTokenSupply)
		public
		returns (uint256)
	{
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		if (_addTokenSupply == 0) {
			return 0;
		}
		uint256 toMint = calculateMintInterest(_token, _addTokenSupply);
		ReserveToken storage reserveToken = reserveTokens[address(_token)];
		reserveToken.gdSupply += toMint;
		reserveToken.reserveSupply += _addTokenSupply;

		return toMint;
	}

	/**
	 * @dev Calculate how much G$ to mint based on expansion change (new reserve
	 * ratio), in order to keep G$ price the same at the bonding curve. the
	 * formula to calculate the gd to mint: gd to mint =
	 * (reservebalance / (newreserveratio * currentprice)) - gdsupply
	 * @param _token The reserve token
	 * @return How much to mint in order to keep price in bonding curve the same
	 */
	function calculateMintExpansion(ERC20 _token) public view returns (uint256) {
		ReserveToken memory reserveToken = reserveTokens[address(_token)];
		uint32 newReserveRatio = calculateNewReserveRatio(_token); // new reserve ratio
		uint256 reserveDecimalsDiff = uint256(27) - _token.decimals(); // //result is in RAY precision
		uint256 denom = (uint256(newReserveRatio) *
			1e21 *
			currentPrice(_token) *
			(10**reserveDecimalsDiff)) / 1e27; // (newreserveratio * currentprice) in RAY precision
		uint256 gdDecimalsDiff = uint256(27) - decimals;
		uint256 toMint = ((reserveToken.reserveSupply *
			(10**reserveDecimalsDiff) *
			1e27) / denom) / (10**gdDecimalsDiff); // reservebalance in RAY precision // return to gd precision
		return toMint - reserveToken.gdSupply;
	}

	/**
	 * @dev Updates bonding curve based on expansion change and new minted amount
	 * @param _token The reserve token
	 * @return How much to mint in order to keep price in bonding curve the same
	 */
	function mintExpansion(ERC20 _token) public returns (uint256) {
		_onlyReserveOrAvatar();
		_onlyActiveToken(_token);
		uint256 toMint = calculateMintExpansion(_token);
		reserveTokens[address(_token)].gdSupply += toMint;
		expandReserveRatio(_token);

		return toMint;
	}
}