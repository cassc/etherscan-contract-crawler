//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IUniRouter} from "./IUniRouter.sol";
import {IUniFactory} from "./IUniFactory.sol";
import {IUniPair} from "./IUniPair.sol";
import {IWETH} from "./IWETH.sol";

contract Sniper is AccessControlUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// CONSTANTS
	uint public constant DENOMINATOR = 100; // used for expected return calc
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	// EVENTS
	event Sniped(address indexed token, uint amountToken, uint amountNative);
	event Liquidate(address indexed token, uint amountToken, uint amountNative);

	// VARIABLES
	address public WETH;
	IUniRouter public router;
	IUniFactory public factory;
	address payable public recipient;
	uint public minReservesNative;
	uint public maxWaitingTime;
	uint public expectedReturn;
	uint public lastPairChecked;
	uint public amountTrade;

	struct Token {
		uint amountToken;
		uint amountNative;
		uint sellTime;
		bool active;
	}
	mapping(address => Token) public tokenInfo;
	EnumerableSetUpgradeable.AddressSet private tokens;

	function initialize(
		IUniRouter _router,
		IUniFactory _factory,
		address _WETH,
		address payable _recipient,
		address gelato,
		uint _minReservesNative,
		uint _maxWaitingTime,
		uint _expectedReturn,
		uint _lastPairChecked,
		uint _amountTrade
	) external initializer {
		router = _router;
		factory = _factory;
		WETH = _WETH;
		recipient = _recipient;
		minReservesNative = _minReservesNative;
		maxWaitingTime = _maxWaitingTime;
		expectedReturn = _expectedReturn;
		lastPairChecked = _lastPairChecked;
		amountTrade = _amountTrade;

		_setupRole(DEFAULT_ADMIN_ROLE, recipient);
		_setupRole(MANAGER_ROLE, recipient);
		_setupRole(MANAGER_ROLE, gelato);
	}

	function _checkReserves(address token) internal view {
		address pair = factory.getPair(WETH, token);

		address token0 = IUniPair(pair).token0();
		address token1 = IUniPair(pair).token1();
		(uint reserve0, uint reserve1, ) = IUniPair(pair).getReserves();

		if (token0 == WETH)
			require(reserve0 >= minReservesNative, "LOW_RESERVES");
		if (token1 == WETH)
			require(reserve1 >= minReservesNative, "LOW_RESERVES");
	}

	function _checkReservesByPair(
		address pair
	) internal view returns (bool reservesGood, address token) {
		address token0 = IUniPair(pair).token0();
		address token1 = IUniPair(pair).token1();
		(uint reserve0, uint reserve1, ) = IUniPair(pair).getReserves();

		if (token0 == WETH) {
			token = token1;
			reservesGood = reserve0 >= minReservesNative;
		}

		if (token1 == WETH) {
			token = token0;
			reservesGood = reserve1 >= minReservesNative;
		}
	}

	function snipe(address token, uint pairIndex, bool getTokens) external {
		_checkReserves(token);

		address[] memory path = new address[](2);
		path[0] = WETH;
		path[1] = token;

		// Swap 1% of total Swap to test pool
		uint received = router.swapExactETHForTokens{value: amountTrade / 100}(
			1,
			path,
			address(this),
			block.timestamp
		)[1];

		path[0] = token;
		path[1] = WETH;

		IERC20Upgradeable(token).safeApprove(address(router), received);

		try
			router.swapExactTokensForETH(
				received,
				1,
				path,
				address(this),
				block.timestamp
			)
		returns (uint256[] memory amounts) {
			// shhhh
			amounts;

			// Sells are valid, buy whole amount

			uint balance = address(this).balance;
			path[0] = WETH;
			path[1] = token;

			uint received2 = router.swapExactETHForTokens{value: balance}(
				1,
				path,
				address(this),
				block.timestamp
			)[1];

			if (getTokens) {
				// Send tokens to user
				IERC20Upgradeable(token).safeTransfer(
					_msgSender(),
					IERC20Upgradeable(token).balanceOf(address(this))
				);
			} else {
				// Store token info for selling later
				tokenInfo[token] = Token(
					received2,
					balance,
					block.timestamp + maxWaitingTime,
					true
				);
				tokens.add(token);
			}

			assert(address(this).balance == 0);

			emit Sniped(token, received2, balance);
		} catch {}

		if (pairIndex > 0) lastPairChecked = pairIndex;
	}

	function liquidate(
		address token,
		bool checkEarnings
	) external onlyRole(MANAGER_ROLE) {
		address[] memory path = new address[](2);
		path[0] = token;
		path[1] = WETH;

		uint amountToken = tokenInfo[token].amountToken;
		uint minAmountOut = 1;

		if (checkEarnings)
			minAmountOut =
				(tokenInfo[token].amountNative * expectedReturn) /
				DENOMINATOR;

		IERC20Upgradeable(token).safeApprove(address(router), amountToken);

		uint received = router.swapExactTokensForETH(
			amountToken,
			minAmountOut,
			path,
			address(this),
			block.timestamp
		)[1];

		(bool success, ) = recipient.call{value: received}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);

		delete tokenInfo[token];

		emit Liquidate(token, amountToken, received);
	}

	function totalPairs() public view returns (uint) {
		return factory.allPairsLength();
	}

	function pairsChecked() public view returns (uint) {
		return totalPairs() - lastPairChecked;
	}

	function checkerSnipe()
		external
		view
		returns (bool canExec, bytes memory execPayload)
	{
		for (uint256 i = lastPairChecked + 1; i < totalPairs(); i++) {
			address pair = factory.allPairs(i);

			(bool reservesGood, address tokenAddress) = _checkReservesByPair(
				pair
			);

			if (reservesGood && !tokens.contains(tokenAddress)) {
				canExec = true;
				execPayload = abi.encodeWithSelector(
					this.snipe.selector,
					tokenAddress,
					false
				);
				break;
			}
		}
	}

	function checkerLiquidate()
		external
		view
		returns (bool canExec, bytes memory execPayload)
	{
		for (uint256 i = 0; i < tokens.length(); i++) {
			address tokenAddress = tokens.at(i);
			Token memory _token = tokenInfo[tokenAddress];

			address[] memory path;
			path[0] = tokenAddress;
			path[1] = WETH;

			uint received = router.getAmountsOut(_token.amountToken, path)[1];
			uint expectedAmt = (_token.amountNative * expectedReturn) /
				DENOMINATOR;

			canExec =
				(block.timestamp >= _token.sellTime ||
					expectedAmt >= received) &&
				_token.active;

			if (canExec) {
				execPayload = abi.encodeWithSelector(
					this.liquidate.selector,
					tokenAddress,
					true
				);
				break;
			}
		}
	}

	// ADMIN ROLE FUNCTIONS
	function removeToken(
		address _token,
		bool getToken
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require(tokens.contains(_token), "!EXISTS");
		tokens.remove(_token);

		// Send tokens to user
		if (getToken)
			IERC20Upgradeable(_token).safeTransfer(
				_msgSender(),
				IERC20Upgradeable(_token).balanceOf(address(this))
			);
	}

	function setMinReservesNative(
		uint _minReservesNative
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		minReservesNative = _minReservesNative;
	}

	function setMaxWaitingTime(
		uint _maxWaitingTime
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		maxWaitingTime = _maxWaitingTime;
	}

	function setExpectedReturn(
		uint _expectedReturn
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		expectedReturn = _expectedReturn;
	}

	function setLastPairChecked(
		uint _lastPairChecked
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		lastPairChecked = _lastPairChecked;
	}

	function setAmountTrade(
		uint _amountTrade
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		amountTrade = _amountTrade;
	}

	receive() external payable {}
}