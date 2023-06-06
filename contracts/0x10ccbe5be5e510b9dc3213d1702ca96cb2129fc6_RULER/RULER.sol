/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*

Become The King ($RULER)
- 1 trillion supply
- 99% of supply is used as liquidity, locked permanently
- a 'ruler' that collects the LP fees
- lock more tokens than the current ruler to usurp them
- locked tokens are returned to the original ruler when usurped
- the ruler can add to their own locked tokens
- the ruler can also unlock tokens and return them to their wallet
- 10% transfer and buy fee (no sell fee), disbursed to holders (8%) and ruler (2%)
- no fee on locks/unlocks

Obviously don't buy the token unless you know the risks.
Good luck and have fun!

https://ruler.tax

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

interface Params {
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
}

interface PositionManager is Params {
	function mint(MintParams calldata) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
	function collect(CollectParams calldata) external payable returns (uint256 amount0, uint256 amount1);
}


contract RULER is Params {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private UINT_MAX = type(uint256).max;
	uint128 constant private UINT128_MAX = type(uint128).max;
	uint256 constant private INITIAL_SUPPLY = 1e30; // 1 trillion
	Router constant private ROUTER = Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
	uint256 constant private INITIAL_ETH_MC = 1e3 ether; // 1,000 ETH initial market cap price
	uint256 constant private CONCENTRATED_PERCENT = 5; // 5% of tokens will be sold at the min price (50 ETH)
	uint256 constant private UPPER_ETH_MC = 1e5 ether; // 100,000 ETH max market cap price
	uint256 constant private INITIAL_RULER_TOKENS_PERCENT = 1; // 1%
	uint256 constant private TRANSFER_FEE = 10; // 10%
	uint256 constant private RULER_FEE = 2; // 2% of the 10% transfer fee goes to ruler, 8% to everyone else

	int24 constant internal MIN_TICK = -887272;
	int24 constant internal MAX_TICK = -MIN_TICK;
	uint160 constant internal MIN_SQRT_RATIO = 4295128739;
	uint160 constant internal MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	string constant public name = "Become The King";
	string constant public symbol = "RULER";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		address pool;
		address ruler;
		uint256 rulerLocked;
		uint256 totalSupply;
		uint256 scaledRewardsPerToken;
		mapping(address => User) users;
		uint256 lowerPositionId;
		uint256 upperPositionId;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event ClaimRewards(address indexed user, uint256 amount);
	event Locked(address indexed ruler, uint256 amount);
	event Unlocked(address indexed ruler, uint256 amount);
	event Reward(uint256 amount);


	modifier _onlyRuler() {
		require(msg.sender == ruler());
		_;
	}


	constructor() {
		address _this = address(this);
		address _weth = ROUTER.WETH9();
		(uint160 _initialSqrtPrice, ) = _getPriceAndTickFromValues(_weth < _this, INITIAL_SUPPLY, INITIAL_ETH_MC);
		info.pool = Factory(ROUTER.factory()).createPool(_this, _weth, 10000);
		Pool(pool()).initialize(_initialSqrtPrice);
	}

	function setRuler(address _ruler) external _onlyRuler {
		info.ruler = _ruler;
	}
	
	function unlock(uint256 _amount) external _onlyRuler {
		unchecked {
			require(rulerLocked() >= _amount);
			info.rulerLocked -= _amount;
			_transfer(address(this), ruler(), _amount);
			emit Unlocked(ruler(), _amount);
		}
	}

	
	function initialize() external {
		require(totalSupply() == 0);
		address _this = address(this);
		address _weth = ROUTER.WETH9();
		bool _weth0 = _weth < _this;
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		info.totalSupply = INITIAL_SUPPLY;
		info.ruler = 0xFaDED72464D6e76e37300B467673b36ECc4d2ccF;
		info.rulerLocked = INITIAL_RULER_TOKENS_PERCENT * INITIAL_SUPPLY / 100;
		emit Locked(ruler(), rulerLocked());
		info.users[_this].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), _this, INITIAL_SUPPLY);
		_approve(_this, address(_pm), INITIAL_SUPPLY - rulerLocked());
		( , int24 _minTick) = _getPriceAndTickFromValues(_weth0, INITIAL_SUPPLY, INITIAL_ETH_MC);
		( , int24 _maxTick) = _getPriceAndTickFromValues(_weth0, INITIAL_SUPPLY, UPPER_ETH_MC);
		uint256 _concentratedTokens = CONCENTRATED_PERCENT * INITIAL_SUPPLY / 100;
		(info.lowerPositionId, , , ) = _pm.mint(MintParams({
			token0: _weth0 ? _weth : _this,
			token1: !_weth0 ? _weth : _this,
			fee: 10000,
			tickLower: _weth0 ? _minTick - 200 : _minTick,
			tickUpper: !_weth0 ? _minTick + 200 : _minTick,
			amount0Desired: _weth0 ? 0 : _concentratedTokens,
			amount1Desired: !_weth0 ? 0 : _concentratedTokens,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
		(info.upperPositionId, , , ) = _pm.mint(MintParams({
			token0: _weth0 ? _weth : _this,
			token1: !_weth0 ? _weth : _this,
			fee: 10000,
			tickLower: _weth0 ? _maxTick : _minTick + 200,
			tickUpper: !_weth0 ? _maxTick : _minTick - 200,
			amount0Desired: _weth0 ? 0 : INITIAL_SUPPLY - _concentratedTokens - rulerLocked(),
			amount1Desired: !_weth0 ? 0 : INITIAL_SUPPLY - _concentratedTokens - rulerLocked(),
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
	}

	function collectTradingFees() public {
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		_pm.collect(CollectParams({
			tokenId: info.lowerPositionId,
			recipient: ruler(),
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
		_pm.collect(CollectParams({
			tokenId: info.upperPositionId,
			recipient: ruler(),
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
	}

	function lock(uint256 _amount) external {
		unchecked {
			if (msg.sender == ruler()) {
				transfer(address(this), _amount);
				info.rulerLocked += _amount;
			} else {
				require(_amount > rulerLocked());
				collectTradingFees();
				_transfer(address(this), ruler(), rulerLocked());
				emit Unlocked(ruler(), rulerLocked());
				transfer(address(this), _amount);
				info.ruler = msg.sender;
				info.rulerLocked = _amount;
			}
			emit Locked(ruler(), _amount);
		}
	}

	function claimRewards() external {
		unchecked {
			uint256 _rewards = rewardsOf(msg.sender);
			if (_rewards > 0) {
				info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
				_transfer(address(this), msg.sender, _rewards);
				emit ClaimRewards(msg.sender, _rewards);
			}
		}
	}
	
	function burn(uint256 _tokens) external {
		_burn(msg.sender, _tokens);
	}

	function transfer(address _to, uint256 _tokens) public returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		return _approve(msg.sender, _spender, _tokens);
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		unchecked {
			uint256 _allowance = allowance(_from, msg.sender);
			require(_allowance >= _tokens);
			if (_allowance != UINT_MAX) {
				info.users[_from].allowance[msg.sender] -= _tokens;
			}
			return _transfer(_from, _to, _tokens);
		}
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		unchecked {
			uint256 _balanceBefore = balanceOf(_to);
			_transfer(msg.sender, _to, _tokens);
			uint256 _tokensReceived = balanceOf(_to) - _balanceBefore;
			uint32 _size;
			assembly {
				_size := extcodesize(_to)
			}
			if (_size > 0) {
				require(Callable(_to).tokenCallback(msg.sender, _tokensReceived, _data));
			}
			return true;
		}
	}
	

	function pool() public view returns (address) {
		return info.pool;
	}

	function ruler() public view returns (address) {
		return info.ruler;
	}

	function rulerLocked() public view returns (uint256) {
		return info.rulerLocked;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function rewardsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerToken * balanceOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function positions() external view returns (uint256 lower, uint256 upper) {
		return (info.lowerPositionId, info.upperPositionId);
	}

	function allInfoFor(address _user) external view returns (address currentRuler, uint256 rulerLockedTokens, uint256 totalTokens, uint256 userBalance, uint256 userRewards) {
		return (ruler(), rulerLocked(), totalSupply(), balanceOf(_user), rewardsOf(_user));
	}


	function _burn(address _account, uint256 _tokens) internal {
		unchecked {
			require(balanceOf(_account) >= _tokens);
			info.totalSupply -= _tokens;
			info.users[_account].balance -= _tokens;
			info.users[_account].scaledPayout -= int256(_tokens * info.scaledRewardsPerToken);
			emit Transfer(_account, address(0x0), _tokens);
		}
	}
	
	function _approve(address _owner, address _spender, uint256 _tokens) internal returns (bool) {
		info.users[_owner].allowance[_spender] = _tokens;
		emit Approval(_owner, _spender, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		unchecked {
			require(balanceOf(_from) >= _tokens);
			info.users[_from].balance -= _tokens;
			info.users[_from].scaledPayout -= int256(_tokens * info.scaledRewardsPerToken);
			address _this = address(this);
			address _pm = ROUTER.positionManager();
			uint256 _fee = 0;
			if (!(_from == _this || _to == _this || _to == pool() || _from == _pm || _to == _pm)) {
				_fee = _tokens * TRANSFER_FEE / 100;
				info.users[_this].balance += _fee;
				emit Transfer(_from, _this, _fee);
			}
			uint256 _transferred = _tokens - _fee;
			info.users[_to].balance += _transferred;
			info.users[_to].scaledPayout += int256(_transferred * info.scaledRewardsPerToken);
			emit Transfer(_from, _to, _transferred);
			_disburse(_fee);
			return true;
		}
	}

	function _disburse(uint256 _amount) internal {
		unchecked {
			if (_amount > 0) {
				uint256 _rulerReward = RULER_FEE * _amount / TRANSFER_FEE;
				info.users[ruler()].scaledPayout -= int256(_rulerReward * FLOAT_SCALAR);
				info.scaledRewardsPerToken += (_amount - _rulerReward) * FLOAT_SCALAR / (totalSupply() - balanceOf(pool()) - balanceOf(address(this)));
				emit Reward(_amount);
			}
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