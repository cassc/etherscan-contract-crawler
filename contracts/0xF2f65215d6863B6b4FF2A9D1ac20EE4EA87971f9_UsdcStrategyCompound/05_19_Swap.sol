// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import './external/uniswap/ISwapRouter02.sol';
import './external/sushiswap/ISushiRouter.sol';
import {IAsset, IVault} from './external/balancer/IVault.sol';
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
		SushiSwap,
		BalancerBatch
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

	IVault internal constant balancer = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

	/// @dev tokenIn => tokenOut => routeInfo
	mapping(address => mapping(address => RouteInfo)) public routes;

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
		address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
		address CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
		address LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

		address STG = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;
		address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

		_setRoute(CRV, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));
		_setRoute(CVX, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
		_setRoute(LDO, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));

		_setRoute(CRV, USDC, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
		_setRoute(
			CVX,
			USDC,
			RouteInfo({
				route: Route.UniswapV3Path,
				info: abi.encodePacked(CVX, uint24(10_000), WETH, uint24(500), USDC)
			})
		);

		_setRoute(USDC, USDT, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(100))}));

		IAsset[] memory assets = new IAsset[](4);
		assets[0] = IAsset(STG);
		assets[1] = IAsset(0xA13a9247ea42D743238089903570127DdA72fE44); // bb-a-USD
		assets[2] = IAsset(0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83); // bb-a-USDC
		assets[3] = IAsset(USDC);

		IVault.BatchSwapStep[] memory steps = new IVault.BatchSwapStep[](3);

		// STG -> bb-a-USD
		steps[0] = IVault.BatchSwapStep({
			poolId: 0x4ce0bd7debf13434d3ae127430e9bd4291bfb61f00020000000000000000038b,
			assetInIndex: 0,
			assetOutIndex: 1,
			amount: 0,
			userData: ''
		});

		// bb-a-USD -> bb-a-USDC
		steps[1] = IVault.BatchSwapStep({
			poolId: 0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d,
			assetInIndex: 1,
			assetOutIndex: 2,
			amount: 0,
			userData: ''
		});

		// bb-a-USDC -> USDC
		steps[2] = IVault.BatchSwapStep({
			poolId: 0x82698aecc9e28e9bb27608bd52cf57f704bd1b83000000000000000000000336,
			assetInIndex: 2,
			assetOutIndex: 3,
			amount: 0,
			userData: ''
		});

		_setRoute(STG, USDC, RouteInfo({route: Route.BalancerBatch, info: abi.encode(steps, assets)}));
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

		ERC20 tokenIn = ERC20(_tokenIn);
		tokenIn.safeTransferFrom(msg.sender, address(this), _amount);

		Route route = routeInfo.route;
		bytes memory info = routeInfo.info;

		if (route == Route.UniswapV2) {
			received = _uniswapV2(_amount, _minReceived, info);
		} else if (route == Route.UniswapV3Direct) {
			received = _uniswapV3Direct(_tokenIn, _tokenOut, _amount, _minReceived, info);
		} else if (route == Route.UniswapV3Path) {
			received = _uniswapV3Path(_amount, _minReceived, info);
		} else if (route == Route.SushiSwap) {
			received = _sushiswap(_amount, _minReceived, info);
		} else if (route == Route.BalancerBatch) {
			received = _balancerBatch(_amount, _minReceived, info);
		} else revert UnsupportedRoute(_tokenIn, _tokenOut);

		// return unswapped amount to sender
		uint256 balance = tokenIn.balanceOf(address(this));
		if (balance > 0) tokenIn.safeTransfer(msg.sender, balance);
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

		// just check that this doesn't throw an error
		if (route == Route.UniswapV3Direct) abi.decode(info, (uint24));

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

		address router = route == Route.SushiSwap ? address(sushiswap) : route == Route.BalancerBatch
			? address(balancer)
			: address(uniswap);

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
		bytes memory _info
	) internal returns (uint256) {
		uint24 fee = abi.decode(_info, (uint24));

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
		bytes memory _path
	) internal returns (uint256) {
		return
			uniswap.exactInput(
				ISwapRouter02.ExactInputParams({
					path: _path,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived
				})
			);
	}

	function _balancerBatch(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _info
	) internal returns (uint256) {
		(IVault.BatchSwapStep[] memory steps, IAsset[] memory assets) = abi.decode(
			_info,
			(IVault.BatchSwapStep[], IAsset[])
		);

		steps[0].amount = _amount;

		int256[] memory limits = new int256[](assets.length);

		limits[0] = int256(_amount);
		limits[limits.length - 1] = int256(_minReceived);

		int256[] memory received = balancer.batchSwap(
			IVault.SwapKind.GIVEN_IN,
			steps,
			assets,
			IVault.FundManagement({
				sender: address(this),
				fromInternalBalance: false,
				recipient: payable(address(msg.sender)),
				toInternalBalance: false
			}),
			limits,
			block.timestamp + 30 minutes
		);

		return uint256(received[received.length - 1]);
	}
}