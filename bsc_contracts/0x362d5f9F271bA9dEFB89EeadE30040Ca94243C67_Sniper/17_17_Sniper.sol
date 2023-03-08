//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ICakeRouter} from "./ICakeRouter.sol";
import {ICakeFactory} from "./ICakeFactory.sol";
import {ICakePair} from "./ICakePair.sol";

contract Sniper is AccessControlUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

	// CONSTANTS
	uint public constant DENOMINATOR = 100; // used for expected return calc
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
	address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
	ICakeRouter public constant router =
		ICakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
	ICakeFactory public constant factory =
		ICakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

	// EVENTS
	event Sniped(address indexed token, uint amountToken, uint amountBNB);
	event Liquidate(address indexed token, uint amountToken, uint amountBNB);

	// VARIABLES
	address payable public recipient;
	uint public minReservesBNB;
	uint public maxWaitingTime;
	uint public expectedReturn;

	struct Token {
		uint amountToken;
		uint amountBNB;
		uint sellTime;
		bool active;
	}
	mapping(address => Token) public tokenInfo;
	EnumerableSetUpgradeable.AddressSet private tokens;

	function initialize(
		address payable _recipient,
		address gelato,
		uint _minReservesBNB,
		uint _maxWaitingTime,
		uint _expectedReturn
	) external initializer {
		recipient = _recipient;
		minReservesBNB = _minReservesBNB;
		maxWaitingTime = _maxWaitingTime;
		expectedReturn = _expectedReturn;

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(MANAGER_ROLE, _msgSender());
		_setupRole(MANAGER_ROLE, gelato);
	}

	function _checkReserves(address token) internal view {
		address pair = factory.getPair(WBNB, token);

		address token0 = ICakePair(pair).token0();
		address token1 = ICakePair(pair).token1();
		(uint reserve0, uint reserve1, ) = ICakePair(pair).getReserves();

		if (token0 == WBNB) require(reserve0 >= minReservesBNB, "LOW_RESERVES");
		if (token1 == WBNB) require(reserve1 >= minReservesBNB, "LOW_RESERVES");
	}

	function snipe(address token, bool getTokens) external payable {
		_checkReserves(token);

		address[] memory path = new address[](2);
		path[0] = WBNB;
		path[1] = token;

		// Swap 1% of total Swap to test pool
		uint received = router.swapExactETHForTokens{value: msg.value / 100}(
			1,
			path,
			address(this),
			block.timestamp
		)[1];

		path[0] = token;
		path[1] = WBNB;

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
			path[0] = WBNB;
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
		} catch {
			revert("INVALID_POOL");
		}
	}

	function liquidate(
		address token,
		bool checkEarnings
	) external onlyRole(MANAGER_ROLE) {
		address[] memory path = new address[](2);
		path[0] = token;
		path[1] = WBNB;

		uint amountToken = tokenInfo[token].amountToken;
		uint minAmountOut = 1;

		if (checkEarnings)
			minAmountOut =
				(tokenInfo[token].amountBNB * expectedReturn) /
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

		assert(address(this).balance == 0);

		emit Liquidate(token, amountToken, received);
	}

	function checker()
		external
		view
		returns (bool canExec, bytes memory execPayload)
	{
		for (uint256 i = 0; i < tokens.length(); i++) {
			address tokenAddress = tokens.at(i);
			Token memory _token = tokenInfo[tokenAddress];

			address[] memory path;
			path[0] = tokenAddress;
			path[1] = WBNB;

			uint received = router.getAmountsOut(_token.amountToken, path)[1];
			uint expectedAmt = (_token.amountBNB * expectedReturn) /
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
	function removeToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require(tokens.contains(_token), "!EXISTS");
		tokens.remove(_token);

		// Send tokens to user
		IERC20Upgradeable(_token).safeTransfer(
			_msgSender(),
			IERC20Upgradeable(_token).balanceOf(address(this))
		);
	}

	function setMinReservesBNB(
		uint _minReservesBNB
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		minReservesBNB = _minReservesBNB;
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

	receive() external payable {}
}