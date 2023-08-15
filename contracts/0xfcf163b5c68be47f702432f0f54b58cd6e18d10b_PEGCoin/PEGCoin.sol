/**
 *Submitted for verification at Etherscan.io on 2023-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*

SUPER PEG COIN ($PEG)

https://superpegcoin.com/
https://t.me/SUPERPEGCOINETH/

- Ownerless launch
- LP burnt to contract
- Max wallet limits: 0.5% for 5 minutes and 1% for 10 minutes.
	- During the first 10 minutes sells are not allowed to limit sniping and keep the maxwallet logic simple.

*/

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Router {
	function factory() external view returns (address);
	function positionManager() external view returns (address);
	function WETH9() external view returns (address);
}

interface Factory {
	function createPool(address _tokenA, address _tokenB, uint24 _fee) external returns (address);
}

interface Pool {
	function initialize(uint160 _sqrtPriceX96) external;
}

interface PositionManager {
	struct MintParams {
		address token0;
		address token1;
		uint24 fee;
		int24 tickLower;
		int24 tickUpper;
		uint256 amount0Desired;
		uint256 amount1Desired;
		uint256 amount0Min;
		uint256 amount1Min;
		address recipient;
		uint256 deadline;
	}
	struct CollectParams {
		uint256 tokenId;
		address recipient;
		uint128 amount0Max;
		uint128 amount1Max;
	}
	function mint(MintParams calldata) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
	function collect(CollectParams calldata) external payable returns (uint256 amount0, uint256 amount1);
}


contract PEGCoin {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private UINT_MAX = type(uint256).max;
	uint128 constant private UINT128_MAX = type(uint128).max;
	
	uint256 constant private TOTAL_SUPPLY = 6_969_696_969 * 1e18; 
	uint256 constant private CEX_SUPPLY = TOTAL_SUPPLY * 5 / 100; // 5%
	uint256 constant private INITIAL_SUPPLY = TOTAL_SUPPLY * 95 / 100; // 95%

	Router constant private ROUTER = Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
	uint256 constant private INITIAL_ETH_MC = 40 ether; // 40 ETH initial market cap price
	uint256 constant private CONCENTRATED_PERCENT = 30; // 30% of tokens will be sold at the min price (12 ETH)
	uint256 constant private UPPER_ETH_MC = 2e6 ether; // 2,000,000 ETH max market cap price

	int24 constant private MIN_TICK = -887272;
	int24 constant private MAX_TICK = -MIN_TICK;
	uint160 constant private MIN_SQRT_RATIO = 4295128739;
	uint160 constant private MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	string constant public name = "SUPER PEG COIN";
	string constant public symbol = "PEG";

	address constant public cexWallet = address(0xB3551972737ed432894046D5eE88eFE24EeD6191);
	uint256 constant public maxWalletLevel1 = TOTAL_SUPPLY * 5 / 1000; // 0.5% for the first 5 minutes
	uint256 constant public maxWalletLevel2 = TOTAL_SUPPLY * 1 / 100; // 1% for the first 10 minutes
	uint256 public launchTimestamp;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		address owner;
		address pool;
		uint256 totalSupply;
		mapping(address => User) users;
		uint256 lowerPositionId1;
		uint256 lowerPositionId2;
		uint256 upperPositionId1;
		uint256 upperPositionId2;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	constructor() {
	}

	function createPool() external {
		require(info.pool == address(0));
		address _this = address(this);
		address _weth = ROUTER.WETH9();
		(uint160 _initialSqrtPrice, ) = _getPriceAndTickFromValues(_weth < _this, INITIAL_SUPPLY, INITIAL_ETH_MC);
		info.pool = Factory(ROUTER.factory()).createPool(_this, _weth, 10000);
		Pool(pool()).initialize(_initialSqrtPrice);
	}

	function initialize() external {
		require(totalSupply() == 0);
		address _this = address(this);
		address _weth = ROUTER.WETH9();
		bool _weth0 = _weth < _this;
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		info.totalSupply = TOTAL_SUPPLY;
		info.users[_this].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), _this, INITIAL_SUPPLY);
		info.users[cexWallet].balance = CEX_SUPPLY;
		emit Transfer(address(0x0), cexWallet, CEX_SUPPLY);
		_approve(_this, address(_pm), INITIAL_SUPPLY);
		( , int24 _minTick) = _getPriceAndTickFromValues(_weth0, INITIAL_SUPPLY, INITIAL_ETH_MC);
		( , int24 _maxTick) = _getPriceAndTickFromValues(_weth0, INITIAL_SUPPLY, UPPER_ETH_MC);
		uint256 _concentratedTokens = CONCENTRATED_PERCENT * INITIAL_SUPPLY / 100;
		(info.lowerPositionId1, , , ) = _pm.mint(PositionManager.MintParams({
			token0: _weth0 ? _weth : _this,
			token1: !_weth0 ? _weth : _this,
			fee: 10000,
			tickLower: _weth0 ? _minTick - 200 : _minTick,
			tickUpper: !_weth0 ? _minTick + 200 : _minTick,
			amount0Desired: _weth0 ? 0 : _concentratedTokens / 2,
			amount1Desired: !_weth0 ? 0 : _concentratedTokens / 2,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
		(info.lowerPositionId2, , , ) = _pm.mint(PositionManager.MintParams({
			token0: _weth0 ? _weth : _this,
			token1: !_weth0 ? _weth : _this,
			fee: 10000,
			tickLower: _weth0 ? _minTick - 200 : _minTick,
			tickUpper: !_weth0 ? _minTick + 200 : _minTick,
			amount0Desired: _weth0 ? 0 : _concentratedTokens / 2,
			amount1Desired: !_weth0 ? 0 : _concentratedTokens / 2,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
		(info.upperPositionId1, , , ) = _pm.mint(PositionManager.MintParams({
			token0: _weth0 ? _weth : _this,
			token1: !_weth0 ? _weth : _this,
			fee: 10000,
			tickLower: _weth0 ? _maxTick : _minTick + 200,
			tickUpper: !_weth0 ? _maxTick : _minTick - 200,
			amount0Desired: _weth0 ? 0 : (INITIAL_SUPPLY - _concentratedTokens) / 2,
			amount1Desired: !_weth0 ? 0 : (INITIAL_SUPPLY - _concentratedTokens) / 2,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
		(info.upperPositionId2, , , ) = _pm.mint(PositionManager.MintParams({
			token0: _weth0 ? _weth : _this,
			token1: !_weth0 ? _weth : _this,
			fee: 10000,
			tickLower: _weth0 ? _maxTick : _minTick + 200,
			tickUpper: !_weth0 ? _maxTick : _minTick - 200,
			amount0Desired: _weth0 ? 0 : (INITIAL_SUPPLY - _concentratedTokens) / 2,
			amount1Desired: !_weth0 ? 0 : (INITIAL_SUPPLY - _concentratedTokens) / 2,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
		launchTimestamp = block.timestamp;
	}

	function collectTradingFees() external {
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		_pm.collect(PositionManager.CollectParams({
			tokenId: info.lowerPositionId1,
			recipient: 0x624ccd220Df76D39A02cAc355826CCbeaBFAc50d,
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
		_pm.collect(PositionManager.CollectParams({
			tokenId: info.lowerPositionId2,
			recipient: 0x60659e7954B676d373fDD536D626f4082be46E9B,
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
		_pm.collect(PositionManager.CollectParams({
			tokenId: info.upperPositionId1,
			recipient: 0x624ccd220Df76D39A02cAc355826CCbeaBFAc50d,
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
		_pm.collect(PositionManager.CollectParams({
			tokenId: info.upperPositionId2,
			recipient: 0x60659e7954B676d373fDD536D626f4082be46E9B,
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		return _approve(msg.sender, _spender, _tokens);
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		uint256 _allowance = allowance(_from, msg.sender);
		require(_allowance >= _tokens);
		if (_allowance != UINT_MAX) {
			info.users[_from].allowance[msg.sender] -= _tokens;
		}
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}

	function pool() public view returns (address) {
		return info.pool;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function positions() external view returns (uint256 lower1, uint256 lower2, uint256 upper1, uint256 upper2) {
		return (info.lowerPositionId1, info.lowerPositionId2, info.upperPositionId1, info.upperPositionId2);
	}

	function _approve(address _owner, address _spender, uint256 _tokens) internal returns (bool) {
		info.users[_owner].allowance[_spender] = _tokens;
		emit Approval(_owner, _spender, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		if (launchTimestamp > 0) { // during launch there are no limits
			if (block.timestamp - launchTimestamp  <= 5 minutes) {
				require(info.users[_to].balance + _tokens <= maxWalletLevel1, "Max wallet 0.5% for first 5 minutes");
			} else if (block.timestamp - launchTimestamp <= 10 minutes) {
				require(info.users[_to].balance + _tokens <= maxWalletLevel2, "Max wallet 1% for first 10 minutes");
			}
		}

		unchecked {
			require(balanceOf(_from) >= _tokens);
			info.users[_from].balance -= _tokens;
			info.users[_to].balance += _tokens;
			emit Transfer(_from, _to, _tokens);
			return true;
		}
	}

	function _getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		unchecked {
			uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
			require(absTick <= uint256(int256(MAX_TICK)), 'T');

			uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
			if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
			if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
			if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
			if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
			if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
			if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
			if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
			if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
			if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
			if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
			if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
			if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
			if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
			if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
			if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
			if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
			if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
			if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
			if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

			if (tick > 0) ratio = type(uint256).max / ratio;

			sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
		}
	}

	function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
		unchecked {
			require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
			uint256 ratio = uint256(sqrtPriceX96) << 32;

			uint256 r = ratio;
			uint256 msb = 0;

			assembly {
				let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(5, gt(r, 0xFFFFFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(4, gt(r, 0xFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(3, gt(r, 0xFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(2, gt(r, 0xF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(1, gt(r, 0x3))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := gt(r, 0x1)
				msb := or(msb, f)
			}

			if (msb >= 128) r = ratio >> (msb - 127);
			else r = ratio << (127 - msb);

			int256 log_2 = (int256(msb) - 128) << 64;

			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(63, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(62, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(61, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(60, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(59, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(58, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(57, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(56, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(55, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(54, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(53, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(52, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(51, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(50, f))
			}

			int256 log_sqrt10001 = log_2 * 255738958999603826347141;

			int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
			int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

			tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
		}
	}

	function _sqrt(uint256 _n) internal pure returns (uint256 result) {
		unchecked {
			uint256 _tmp = (_n + 1) / 2;
			result = _n;
			while (_tmp < result) {
				result = _tmp;
				_tmp = (_n / _tmp + _tmp) / 2;
			}
		}
	}

	function _getPriceAndTickFromValues(bool _weth0, uint256 _tokens, uint256 _weth) internal pure returns (uint160 price, int24 tick) {
		uint160 _tmpPrice = uint160(_sqrt(2**192 / (!_weth0 ? _tokens : _weth) * (_weth0 ? _tokens : _weth)));
		tick = _getTickAtSqrtRatio(_tmpPrice);
		tick = tick - (tick % 200);
		price = _getSqrtRatioAtTick(tick);
	}
}


contract Deploy {
	PEGCoin public PEG;
	constructor() {
	}

	function createPEG() external {
		if (address(PEG) == address(0)) PEG = new PEGCoin();
	}

	function createPool() external {
		if (address(PEG) == address(0)) PEG = new PEGCoin();
		if (PEG.pool() == address(0)) PEG.createPool();
	}

	function launch() external {
		if (address(PEG) == address(0)) PEG = new PEGCoin();
		if (PEG.pool() == address(0)) PEG.createPool();
		PEG.initialize();
	}

}