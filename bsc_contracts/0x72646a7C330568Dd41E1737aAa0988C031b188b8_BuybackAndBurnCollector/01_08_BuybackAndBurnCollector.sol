// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUniswapV2Router } from "./IUniswapV2Router.sol";

interface ITokenSource
{
	function collect() external returns (uint256 _amount);
}

contract BuybackAndBurnCollector is Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address public immutable router;
	address public immutable wrappedToken;

	mapping(address => bool) public whitelist;

	modifier whitelisted()
	{
		require(whitelist[msg.sender], "access denied");
		_;
	}

	constructor(address _router)
	{
		router = _router;
		wrappedToken = IUniswapV2Router(router).WETH();
	}

	function updateWhitelist(address _account, bool _enabled) external onlyOwner
	{
		whitelist[_account] = _enabled;
	}

	function buybackAndBurn(address _tokenSource, address _tokenIn, address _tokenOut, bool _directRoute, uint256 _minAmountOut) external whitelisted nonReentrant returns (uint256 _amountOut)
	{
		uint256 _amountIn = ITokenSource(_tokenSource).collect();
		if (_amountIn == 0) return 0;

		if (_tokenIn == _tokenOut) {
			IERC20(_tokenIn).safeTransfer(FURNACE, _amountIn);
			_amountOut = _amountIn;
		} else {
			IERC20(_tokenIn).safeApprove(router, _amountIn);
			address[] memory _path;
			if (_directRoute) {
				_path = new address[](2);
				_path[0] = _tokenIn;
				_path[1] = _tokenOut;
			} else {
				_path = new address[](3);
				_path[0] = _tokenIn;
				_path[1] = wrappedToken;
				_path[2] = _tokenOut;
			}
			_amountOut = IUniswapV2Router(router).swapExactTokensForTokens(_amountIn, _minAmountOut, _path, FURNACE, block.timestamp)[_path.length - 1];
		}

		emit BuybackAndBurn(_tokenIn, _tokenOut, _amountIn, _amountOut);

		return _amountOut;
	}

	event BuybackAndBurn(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOut);
}