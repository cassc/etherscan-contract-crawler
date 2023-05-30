// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import './external/uniswap/ISwapRouter02.sol';
import './external/sushiswap/ISushiRouter.sol';
import './libraries/Ownable.sol';
import './libraries/Path.sol';

/**
 * @notice
 * Swap contract used by strategies to:
 * 1. swap strategy rewards to 'asset'
 * 2. zap similar tokens to asset (e.g. USDT to USDC)
 */
contract Swap is Ownable {
	using SafeTransferLib for ERC20;
	using Path for bytes;

	enum Route {
		Unsupported,
		UniswapV2,
		UniswapV3Direct,
		UniswapV3Path,
		SushiSwap
	}

	/**
		@dev info depends on route:
		UniswapV2: address[] path
		UniswapV3Direct: uint24 fee
		UniswapV3Path: bytes path (address, uint24 fee, address, uint24 fee, address)
	 */
	struct RouteInfo {
		Route route;
		bytes info;
	}

	ISushiRouter internal constant sushiswap = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
	/// @dev single address which supports both uniswap v2 and v3 routes
	ISwapRouter02 internal constant uniswap = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	/// @dev tokenIn => tokenOut => routeInfo
	mapping(address => mapping(address => RouteInfo)) public routes;

	address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

	address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

	address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

	address internal constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
	address internal constant PNT = 0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD;

	/*//////////////////
	/      Events      /
	//////////////////*/

	event RouteSet(address indexed tokenIn, address indexed tokenOut, RouteInfo routeInfo);
	event RouteRemoved(address indexed tokenIn, address indexed tokenOut);

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error UnsupportedRoute(address tokenIn, address tokenOut);
	error InvalidRouteInfo();

	constructor() Ownable() {
		// Solidity arrays are dumb
		address[] memory path = new address[](3);
		path[0] = CRV;
		path[1] = WETH;
		path[2] = USDC;

		_setRoute(CRV, USDC, RouteInfo({route: Route.UniswapV2, info: abi.encode(path)}));

		path[2] = WBTC;
		_setRoute(CRV, WBTC, RouteInfo({route: Route.SushiSwap, info: abi.encode(path)}));

		_setRoute(CRV, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));

		_setRoute(
			CVX,
			USDC,
			RouteInfo({
				route: Route.UniswapV3Path,
				info: abi.encodePacked(CVX, uint24(10_000), WETH, uint24(500), USDC)
			})
		);
		_setRoute(
			CVX,
			WBTC,
			RouteInfo({
				route: Route.UniswapV3Path,
				info: abi.encodePacked(CVX, uint24(10_000), WETH, uint24(500), WBTC)
			})
		);

		address[] memory shortPath = new address[](2);
		shortPath[0] = CVX;
		shortPath[1] = WETH;

		_setRoute(CVX, WETH, RouteInfo({route: Route.SushiSwap, info: abi.encode(shortPath)}));

		shortPath[0] = LDO;
		_setRoute(LDO, WETH, RouteInfo({route: Route.SushiSwap, info: abi.encode(shortPath)}));

		path[0] = PNT;
		_setRoute(PNT, WBTC, RouteInfo({route: Route.UniswapV2, info: abi.encode(path)}));

		_setRoute(USDT, USDC, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(100))}));
		_setRoute(DAI, USDC, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(100))}));
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function getRoute(address _tokenIn, address _tokenOut) external view returns (RouteInfo memory routeInfo) {
		return routes[_tokenIn][_tokenOut];
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received) {
		RouteInfo memory routeInfo = routes[_tokenIn][_tokenOut];
		Route route = routeInfo.route;

		ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);

		bytes memory info = routeInfo.info;

		if (route == Route.UniswapV2) return _uniswapV2(_amount, _minReceived, info);
		if (route == Route.UniswapV3Direct) return _uniswapV3Direct(_tokenIn, _tokenOut, _amount, _minReceived, info);
		if (route == Route.UniswapV3Path) return _uniswapV3Path(_amount, _minReceived, info);
		if (route == Route.SushiSwap) return _sushiswap(_amount, _minReceived, info);

		revert UnsupportedRoute(_tokenIn, _tokenOut);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function setRoute(
		address _tokenIn,
		address _tokenOut,
		RouteInfo memory _routeInfo
	) external onlyOwner {
		_setRoute(_tokenIn, _tokenOut, _routeInfo);
	}

	function unsetRoute(address _tokenIn, address _tokenOut) external onlyOwner {
		delete routes[_tokenIn][_tokenOut];
		emit RouteRemoved(_tokenIn, _tokenOut);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _setRoute(
		address _tokenIn,
		address _tokenOut,
		RouteInfo memory _routeInfo
	) internal {
		Route route = _routeInfo.route;
		bytes memory info = _routeInfo.info;

		if (route == Route.UniswapV2 || route == Route.SushiSwap) {
			address[] memory path = abi.decode(info, (address[]));

			if (path[0] != _tokenIn) revert InvalidRouteInfo();
			if (path[path.length - 1] != _tokenOut) revert InvalidRouteInfo();
		}

		if (route == Route.UniswapV3Direct) {
			// just check that this doesn't throw an error
			abi.decode(info, (uint24));
		}

		if (route == Route.UniswapV3Path) {
			bytes memory path = info;

			// check first tokenIn
			(address tokenIn, , ) = path.decodeFirstPool();
			if (tokenIn != _tokenIn) revert InvalidRouteInfo();

			// check last tokenOut
			while (path.hasMultiplePools()) path = path.skipToken();
			(, address tokenOut, ) = path.decodeFirstPool();
			if (tokenOut != _tokenOut) revert InvalidRouteInfo();
		}

		address router = route == Route.SushiSwap ? address(sushiswap) : address(uniswap);
		ERC20(_tokenIn).safeApprove(router, 0);
		ERC20(_tokenIn).safeApprove(router, type(uint256).max);

		routes[_tokenIn][_tokenOut] = _routeInfo;
		emit RouteSet(_tokenIn, _tokenOut, _routeInfo);
	}

	function _uniswapV2(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		address[] memory path = abi.decode(_path, (address[]));

		return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
	}

	function _sushiswap(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		address[] memory path = abi.decode(_path, (address[]));

		uint256[] memory received = sushiswap.swapExactTokensForTokens(
			_amount,
			_minReceived,
			path,
			msg.sender,
			block.timestamp + 30 minutes
		);

		return received[received.length - 1];
	}

	function _uniswapV3Direct(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived,
		bytes memory info
	) internal returns (uint256) {
		uint24 fee = abi.decode(info, (uint24));

		return
			uniswap.exactInputSingle(
				ISwapRouter02.ExactInputSingleParams({
					tokenIn: _tokenIn,
					tokenOut: _tokenOut,
					fee: fee,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived,
					sqrtPriceLimitX96: 0
				})
			);
	}

	function _uniswapV3Path(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory path
	) internal returns (uint256) {
		return
			uniswap.exactInput(
				ISwapRouter02.ExactInputParams({
					path: path,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived
				})
			);
	}
}