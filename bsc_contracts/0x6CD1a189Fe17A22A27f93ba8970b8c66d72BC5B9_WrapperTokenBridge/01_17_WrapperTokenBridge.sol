// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";
import { IUniswapV2Router } from "./IUniswapV2Router.sol";
import { MasterChef } from "./MasterChef.sol";
import { BitcornWrapperToken } from "./BitcornWrapperToken.sol";

interface IWrapperToken
{
	function token() external view returns (address _token);

	function wrap(uint256 _amount) external;
	function unwrap(uint256 _amount) external;
}

interface IMagikVault
{
	function want() external view returns (address _want);

	function deposit(uint256 _amount) external;
	function withdraw(uint256 _shares) external;
}

interface IWETH
{
	function deposit() external payable;
	function withdraw(uint256 _amount) external;
}

interface ICounterpartyPool
{
	function reserveToken() external view returns (address _reserveToken);

	function deposit(uint256 _amount, uint256 _minShares) external returns (uint256 _shares);
	function withdraw(uint256 _shares, uint256 _minAmount) external returns (uint256 _amount);
}

contract ExtraHop
{
	using SafeERC20 for IERC20;

	function insertExtraHop(address _token, uint256 _amount) external
	{
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
		IERC20(_token).safeTransfer(address(this), IERC20(_token).balanceOf(address(this)));
		IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
	}
}

contract WrapperTokenBridge is Initializable, ReentrancyGuard
{
	using Address for address payable;
	using SafeERC20 for IERC20;

	uint256[2] public fee = [9975, 10000];

	address public masterChef;

	address public router;
	address public wrappedToken;

	address public extraHop = address(new ExtraHop());

	constructor(address _masterChef, address _router)
	{
		initialize(_masterChef, _router);
	}

	function initialize(address _masterChef, address _router) public initializer
	{
		fee = [9975, 10000];

		extraHop = address(new ExtraHop());

		masterChef = _masterChef;
		router = _router;
		wrappedToken = IUniswapV2Router(_router).WETH();
	}

	function initializeExtraHop() external
	{
		require(extraHop == address(0), "invalid state");
		extraHop = address(new ExtraHop());
	}

	function deposit(uint256 _pid, uint256 _type, address _routeToken, uint256 _minAmountOut) external payable nonReentrant returns (uint256 _amountOut)
	{
		uint256 _amountIn = msg.value;
		if (_routeToken == wrappedToken) {
			IWETH(wrappedToken).deposit{value: _amountIn}();
		} else {
			address[] memory _path = new address[](2);
			_path[0] = wrappedToken;
			_path[1] = _routeToken;
			IUniswapV2Router(router).swapExactETHForTokens{value: _amountIn}(1, _path, address(this), block.timestamp);
			if (_type == 4) {
				_insertExtraHop(_routeToken);
			}
			_amountIn = IERC20(_routeToken).balanceOf(address(this));
		}
		return _deposit(msg.sender, _pid, _type, _routeToken, _amountIn, _minAmountOut, address(0));
	}

	function deposit(uint256 _pid, uint256 _type, address _routeToken, uint256 _minAmountOut, address _referral) external payable nonReentrant returns (uint256 _amountOut)
	{
		uint256 _amountIn = msg.value;
		if (_routeToken == wrappedToken) {
			IWETH(wrappedToken).deposit{value: _amountIn}();
		} else {
			address[] memory _path = new address[](2);
			_path[0] = wrappedToken;
			_path[1] = _routeToken;
			IUniswapV2Router(router).swapExactETHForTokens{value: _amountIn}(1, _path, address(this), block.timestamp);
			if (_type == 4) {
				_insertExtraHop(_routeToken);
			}
			_amountIn = IERC20(_routeToken).balanceOf(address(this));
		}
		return _deposit(msg.sender, _pid, _type, _routeToken, _amountIn, _minAmountOut, _referral);
	}

	function deposit(uint256 _pid, uint256 _type, address _tokenIn, uint256 _amountIn, address _routeToken, bool _directRoute, uint256 _minAmountOut) external nonReentrant returns (uint256 _amountOut)
	{
		IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
		_amountIn = IERC20(_tokenIn).balanceOf(address(this));
		if (_routeToken != _tokenIn) {
			IERC20(_tokenIn).safeApprove(router, _amountIn);
			address[] memory _path;
			if (_directRoute) {
				_path = new address[](2);
				_path[0] = _tokenIn;
				_path[1] = _routeToken;
			} else {
				_path = new address[](3);
				_path[0] = _tokenIn;
				_path[1] = wrappedToken;
				_path[2] = _routeToken;
			}
			IUniswapV2Router(router).swapExactTokensForTokens(_amountIn, 1, _path, address(this), block.timestamp);
			if (_type == 4) {
				_insertExtraHop(_routeToken);
			}
			_amountIn = IERC20(_routeToken).balanceOf(address(this));
		}
		return _deposit(msg.sender, _pid, _type, _routeToken, _amountIn, _minAmountOut, address(0));
	}

	function deposit(uint256 _pid, uint256 _type, address _tokenIn, uint256 _amountIn, address _routeToken, bool _directRoute, uint256 _minAmountOut, address _referral) external nonReentrant returns (uint256 _amountOut)
	{
		IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
		_amountIn = IERC20(_tokenIn).balanceOf(address(this));
		if (_routeToken != _tokenIn) {
			IERC20(_tokenIn).safeApprove(router, _amountIn);
			address[] memory _path;
			if (_directRoute) {
				_path = new address[](2);
				_path[0] = _tokenIn;
				_path[1] = _routeToken;
			} else {
				_path = new address[](3);
				_path[0] = _tokenIn;
				_path[1] = wrappedToken;
				_path[2] = _routeToken;
			}
			IUniswapV2Router(router).swapExactTokensForTokens(_amountIn, 1, _path, address(this), block.timestamp);
			if (_type == 4) {
				_insertExtraHop(_routeToken);
			}
			_amountIn = IERC20(_routeToken).balanceOf(address(this));
		}
		return _deposit(msg.sender, _pid, _type, _routeToken, _amountIn, _minAmountOut, _referral);
	}

	function withdraw(uint256 _pid, uint256 _type, uint256 _amountIn, address _routeToken, uint256 _minAmountOut) external nonReentrant returns (uint256 _amountOut)
	{
		_amountOut = _withdraw(msg.sender, _pid, _type, _routeToken, _amountIn);
		if (_routeToken == wrappedToken) {
			IWETH(wrappedToken).withdraw(_amountOut);
			payable(msg.sender).sendValue(_amountOut);
		} else {
			if (_type == 4) {
				_insertExtraHop(_routeToken);
			}
			IERC20(_routeToken).safeApprove(router, _amountOut);
			address[] memory _path = new address[](2);
			_path[0] = _routeToken;
			_path[1] = wrappedToken;
			_amountOut = IUniswapV2Router(router).swapExactTokensForETH(_amountOut, 1, _path, msg.sender, block.timestamp)[_path.length - 1];
		}
		require(_amountOut >= _minAmountOut, "high slippage");
		return _amountOut;
	}

	function withdraw(uint256 _pid, uint256 _type, address _tokenOut, uint256 _amountIn, address _routeToken, bool _directRoute, uint256 _minAmountOut) external nonReentrant returns (uint256 _amountOut)
	{
		_amountOut = _withdraw(msg.sender, _pid, _type, _routeToken, _amountIn);
		if (_routeToken == _tokenOut) {
			IERC20(_tokenOut).safeTransfer(msg.sender, _amountOut);
		} else {
			if (_type == 4) {
				_insertExtraHop(_routeToken);
			}
			IERC20(_routeToken).safeApprove(router, _amountOut);
			address[] memory _path;
			if (_directRoute) {
				_path = new address[](2);
				_path[0] = _routeToken;
				_path[1] = _tokenOut;
			} else {
				_path = new address[](3);
				_path[0] = _routeToken;
				_path[1] = wrappedToken;
				_path[2] = _tokenOut;
			}
			_amountOut = IUniswapV2Router(router).swapExactTokensForTokens(_amountOut, 1, _path, msg.sender, block.timestamp)[_path.length - 1];
		}
		require(_amountOut >= _minAmountOut, "high slippage");
		return _amountOut;
	}

	receive() external payable
	{
	}

	function _deposit(address _sender, uint256 _pid, uint256 _type, address _tokenIn, uint256 _amountIn, uint256 _minAmountOut, address _referral) internal returns (uint256 _amountOut)
	{
		require(_type < 5, "invalid type");
		(address _poolToken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
		if (_type == 1) {
			_poolToken = IWrapperToken(_poolToken).token();
		}
		else
		if (_type == 2) {
			_poolToken = IMagikVault(_poolToken).want();
		}
		else
		if (_type == 3) {
			_poolToken = ICounterpartyPool(_poolToken).reserveToken();
		}
		else
		if (_type == 4) {
			_poolToken = BitcornWrapperToken(_poolToken).token();
		}
		if (_tokenIn == _poolToken) {
			_amountOut = _amountIn;
		}
		else {
			address _token0 = IUniswapV2Pair(_poolToken).token0();
			address _token1 = IUniswapV2Pair(_poolToken).token1();
			if (_tokenIn == _token0) {
				(uint256 _swapInAmount0, uint256 _swapOutAmount1) = _zapin0(_poolToken, _token0, fee, _amountIn, address(this));
				_amountOut = _mint(_poolToken, _token0, _token1, _amountIn - _swapInAmount0, _swapOutAmount1, address(this));
			}
			else
			if (_tokenIn == _token1) {
				(uint256 _swapInAmount1, uint256 _swapOutAmount0) = _zapin1(_poolToken, _token1, fee, _amountIn, address(this));
				_amountOut = _mint(_poolToken, _token0, _token1, _swapOutAmount0, _amountIn - _swapInAmount1, address(this));
			}
			else {
				revert("invalid token");
			}
		}
		if (_type == 1) {
			(address _wrapperToken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
			IERC20(_poolToken).safeApprove(_wrapperToken, _amountOut);
			IWrapperToken(_wrapperToken).wrap(_amountOut);
			_amountOut = IERC20(_wrapperToken).balanceOf(address(this));
			IERC20(_wrapperToken).safeApprove(masterChef, _amountOut);
		}
		else
		if (_type == 2) {
			(address _vaultToken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
			IERC20(_poolToken).safeApprove(_vaultToken, _amountOut);
			IMagikVault(_vaultToken).deposit(_amountOut);
			_amountOut = IERC20(_vaultToken).balanceOf(address(this));
			IERC20(_vaultToken).safeApprove(masterChef, _amountOut);
		}
		else
		if (_type == 3) {
			(address _counterpartyToken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
			IERC20(_poolToken).safeApprove(_counterpartyToken, _amountOut);
			ICounterpartyPool(_counterpartyToken).deposit(_amountOut, 0);
			_amountOut = IERC20(_counterpartyToken).balanceOf(address(this));
			IERC20(_counterpartyToken).safeApprove(masterChef, _amountOut);
		}
		else
		if (_type == 4) {
			(address _vaultToken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
			IERC20(_poolToken).safeApprove(_vaultToken, _amountOut);
			BitcornWrapperToken(_vaultToken).deposit(_amountOut, _sender);
			_amountOut = IERC20(_vaultToken).balanceOf(address(this));
			IERC20(_vaultToken).safeApprove(masterChef, _amountOut);
		}
		else {
			IERC20(_poolToken).safeApprove(masterChef, _amountOut);
		}
		require(_amountOut >= _minAmountOut, "high slippage");
		MasterChef(masterChef).depositOnBehalfOf(_pid, _amountOut, msg.sender, _referral);
		return _amountOut;
	}

	function _withdraw(address _sender, uint256 _pid, uint256 _type, address _tokenOut, uint256 _amountIn) internal returns (uint256 _amountOut)
	{
		require(_type < 5, "invalid type");
		(address _poolToken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
		MasterChef(masterChef).withdrawOnBehalfOf(_pid, _amountIn, msg.sender);
		_amountIn = IERC20(_poolToken).balanceOf(address(this));
		if (_type == 1) {
			IWrapperToken(_poolToken).unwrap(_amountIn);
			_poolToken = IWrapperToken(_poolToken).token();
			_amountIn = IERC20(_poolToken).balanceOf(address(this));
		}
		else
		if (_type == 2) {
			IMagikVault(_poolToken).withdraw(_amountIn);
			_poolToken = IMagikVault(_poolToken).want();
			_amountIn = IERC20(_poolToken).balanceOf(address(this));
		}
		else
		if (_type == 3) {
			ICounterpartyPool(_poolToken).withdraw(_amountIn, 0);
			_poolToken = ICounterpartyPool(_poolToken).reserveToken();
			_amountIn = IERC20(_poolToken).balanceOf(address(this));
		}
		else
		if (_type == 4) {
			BitcornWrapperToken(_poolToken).withdraw(_amountIn, _sender);
			BitcornWrapperToken(_poolToken).claim(_sender);
			_poolToken = BitcornWrapperToken(_poolToken).token();
			_amountIn = IERC20(_poolToken).balanceOf(address(this));
		}
		if (_tokenOut == _poolToken) {
			_amountOut = _amountIn;
		}
		else {
			address _token0 = IUniswapV2Pair(_poolToken).token0();
			address _token1 = IUniswapV2Pair(_poolToken).token1();
			if (_tokenOut == _token0) {
				(uint256 _burnOutAmount0, uint256 _burnOutAmount1) = _burn(_poolToken, _amountIn, address(this));
				uint256 _swapOutAmount0 = _swap1(_poolToken, _token1, fee, _burnOutAmount1, address(this));
				_amountOut = _burnOutAmount0 + _swapOutAmount0;
			}
			else
			if (_tokenOut == _token1) {
				(uint256 _burnOutAmount0, uint256 _burnOutAmount1) = _burn(_poolToken, _amountIn, address(this));
				uint256 _swapOutAmount1 = _swap0(_poolToken, _token0, fee, _burnOutAmount0, address(this));
				_amountOut = _burnOutAmount1 + _swapOutAmount1;
			}
			else {
				revert("invalid token");
			}
		}
		return _amountOut;
	}

	function _insertExtraHop(address _token) internal
	{
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		IERC20(_token).safeApprove(extraHop, _balance);
		ExtraHop(extraHop).insertExtraHop(_token, _balance);
	}

	function _zapin0(address _pair, address _token0, uint256[2] memory _fee, uint256 _amount0, address _to) internal returns (uint256 _swapInAmount0, uint256 _swapOutAmount1)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_pair).getReserves();
		_swapInAmount0 = _calcZapin(_fee, _reserve0, _amount0);
		_swapOutAmount1 = _calcSwapOut(_fee, _reserve0, _reserve1, _swapInAmount0);
		IERC20(_token0).safeTransfer(_pair, _swapInAmount0);
		IUniswapV2Pair(_pair).swap(0, _swapOutAmount1, _to, new bytes(0));
		return (_swapInAmount0, _swapOutAmount1);
	}

	function _zapin1(address _pair, address _token1, uint256[2] memory _fee, uint256 _amount1, address _to) internal returns (uint256 _swapInAmount1, uint256 _swapOutAmount0)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_pair).getReserves();
		_swapInAmount1 = _calcZapin(_fee, _reserve1, _amount1);
		_swapOutAmount0 = _calcSwapOut(_fee, _reserve1, _reserve0, _swapInAmount1);
		IERC20(_token1).safeTransfer(_pair, _swapInAmount1);
		IUniswapV2Pair(_pair).swap(_swapOutAmount0, 0, _to, new bytes(0));
		return (_swapInAmount1, _swapOutAmount0);
	}

	function _swap0(address _pair, address _token0, uint256[2] memory _fee, uint256 _amount0, address _to) internal returns (uint256 _amount1)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_pair).getReserves();
		_amount1 = _calcSwapOut(_fee, _reserve0, _reserve1, _amount0);
		IERC20(_token0).safeTransfer(_pair, _amount0);
		IUniswapV2Pair(_pair).swap(0, _amount1, _to, new bytes(0));
		return _amount1;
	}

	function _swap1(address _pair, address _token1, uint256[2] memory _fee, uint256 _amount1, address _to) internal returns (uint256 _amount0)
	{
		(uint256 _reserve0, uint256 _reserve1,) = IUniswapV2Pair(_pair).getReserves();
		_amount0 = _calcSwapOut(_fee, _reserve1, _reserve0, _amount1);
		IERC20(_token1).safeTransfer(_pair, _amount1);
		IUniswapV2Pair(_pair).swap(_amount0, 0, _to, new bytes(0));
		return _amount0;
	}

	function _mint(address _pair, address _token0, address _token1, uint256 _amount0, uint256 _amount1, address _to) internal returns (uint256 _amount2)
	{
		IERC20(_token0).safeTransfer(_pair, _amount0);
		IERC20(_token1).safeTransfer(_pair, _amount1);
		return IUniswapV2Pair(_pair).mint(_to);
	}

	function _burn(address _pair, uint256 _amount2, address _to) internal returns (uint256 _amount0, uint256 _amount1)
	{
		IERC20(_pair).safeTransfer(_pair, _amount2);
		return IUniswapV2Pair(_pair).burn(_to);
	}

	function _calcZapin(uint256[2] memory _fee, uint256 _reserveIn, uint256 _amountIn) internal pure returns (uint256 _amountSwapIn)
	{
		return (_sqrt(_reserveIn * (_amountIn * 4 * _fee[0] * _fee[1] + _reserveIn * (_fee[0] * _fee[0] + _fee[1] * (_fee[1] + 2 * _fee[0])))) - _reserveIn * (_fee[1] + _fee[0])) / (2 * _fee[1]);
	}

	function _calcSwapOut(uint256[2] memory _fee, uint256 _reserveIn, uint256 _reserveOut, uint256 _amountIn) private pure returns (uint256 _amountOut)
	{
		uint256 _amountInWithFee = _amountIn * _fee[0];
		return (_reserveOut * _amountInWithFee) / (_reserveIn * _fee[1] + _amountInWithFee);
	}

	function _sqrt(uint256 _x) internal pure returns (uint256 _y)
	{
		_y = _x;
		uint256 _z = (_x + 1) / 2;
		while (_z < _y) {
			_y = _z;
			_z = (_x / _z + _z) / 2;
		}
		return _y;
	}
}