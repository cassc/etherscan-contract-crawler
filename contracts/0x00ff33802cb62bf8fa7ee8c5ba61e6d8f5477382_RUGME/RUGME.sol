/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*

Try To Rug Me ($RUGME)
- 1 trillion supply
- 100% of supply is used as liquidity
- 10% transfer and buy fee (no sell fee), all disbursed to holders
- a puzzle 'onion' to solve which can rug the liquidity (see bottom of file)
- when rugged, 20% goes to the rugger and 80% is refunded to holders

Obviously don't buy the token unless you know the risks.
Good luck and have fun!

*/

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface WETH {
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
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
	struct DecreaseLiquidityParams {
		uint256 tokenId;
		uint128 liquidity;
		uint256 amount0Min;
		uint256 amount1Min;
		uint256 deadline;
	}
}

interface PositionManager is Params {
	function mint(MintParams calldata) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
	function collect(CollectParams calldata) external payable returns (uint256 amount0, uint256 amount1);
	function decreaseLiquidity(DecreaseLiquidityParams calldata) external payable returns (uint256 amount0, uint256 amount1);
	function positions(uint256) external view returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1);
}


contract TickMath {

	int24 internal constant MIN_TICK = -887272;
	int24 internal constant MAX_TICK = -MIN_TICK;
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;


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


contract RUGME is TickMath, Params {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private UINT_MAX = type(uint256).max;
	uint128 constant private UINT128_MAX = type(uint128).max;
	uint256 constant private INITIAL_SUPPLY = 1e30; // 1 trillion
	Router constant private ROUTER = Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
	address constant private RUG_SIGNER = 0x00F01dA987bab23Cfe2DCe67FE527631f108fb7c;
	uint256 constant private INITIAL_ETH_MC = 1e3 ether; // 1,000 ETH initial market cap price
	uint256 constant private CONCENTRATED_PERCENT = 10; // 10% of tokens will be sold at the min price (100 ETH)
	uint256 constant private UPPER_ETH_MC = 1e5 ether; // 100,000 ETH max market cap price
	uint256 constant private RUGGER_PERCENT = 20; // 20% to the rugger, 80% refunded to all remaining tokens
	uint256 constant private TRANSFER_FEE = 10; // 10%

	string constant public name = "Try To Rug Me";
	string constant public symbol = "RUGME";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		bool rugged;
		address owner;
		address pool;
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
	event Reward(uint256 amount);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
		info.rugged = false;
		info.owner = 0xFaDED72464D6e76e37300B467673b36ECc4d2ccF;
		address _this = address(this);
		address _weth = ROUTER.WETH9();
		(uint160 _initialSqrtPrice, ) = _getPriceAndTickFromValues(_weth < _this, INITIAL_SUPPLY, INITIAL_ETH_MC);
		info.pool = Factory(ROUTER.factory()).createPool(_this, _weth, 10000);
		Pool(pool()).initialize(_initialSqrtPrice);
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function collectTradingFees() external _onlyOwner {
		bool _weth0 = ROUTER.WETH9() < address(this);
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		_pm.collect(CollectParams({
			tokenId: info.lowerPositionId,
			recipient: owner(),
			amount0Max: _weth0 ? UINT128_MAX : 0,
			amount1Max: !_weth0 ? UINT128_MAX : 0
		}));
		_pm.collect(CollectParams({
			tokenId: info.upperPositionId,
			recipient: owner(),
			amount0Max: _weth0 ? UINT128_MAX : 0,
			amount1Max: !_weth0 ? UINT128_MAX : 0
		}));
	}

	
	function initialize() external {
		require(!rugged());
		require(totalSupply() == 0);
		address _this = address(this);
		address _weth = ROUTER.WETH9();
		bool _weth0 = _weth < _this;
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		info.totalSupply = INITIAL_SUPPLY;
		info.users[_this].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), _this, INITIAL_SUPPLY);
		_approve(_this, address(_pm), INITIAL_SUPPLY);
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
			amount0Desired: _weth0 ? 0 : INITIAL_SUPPLY - _concentratedTokens,
			amount1Desired: !_weth0 ? 0 : INITIAL_SUPPLY - _concentratedTokens,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
	}

	function rug(bytes memory _signature) external {
		require(!rugged());
		require(_signature.length == 65);
		bytes32 r; bytes32 s; uint8 v;
		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := byte(0, mload(add(_signature, 96)))
		}
		require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender)))), v, r, s) == RUG_SIGNER);
		address _this = address(this);
		uint256 _balanceBefore = balanceOf(_this);
		WETH _weth = WETH(ROUTER.WETH9());
		bool _weth0 = address(_weth) < _this;
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		_pm.collect(CollectParams({
			tokenId: info.lowerPositionId,
			recipient: _this,
			amount0Max: _weth0 ? 0 : UINT128_MAX,
			amount1Max: !_weth0 ? 0 : UINT128_MAX
		}));
		( , , , , , , , uint128 _liquidity, , , uint128 _tokensOwedBefore0, uint128 _tokensOwedBefore1) = _pm.positions(info.lowerPositionId);
		_pm.decreaseLiquidity(DecreaseLiquidityParams({
			tokenId: info.lowerPositionId,
			liquidity: _liquidity,
			amount0Min: 0,
			amount1Min: 0,
			deadline: block.timestamp
		}));
		( , , , , , , , , , , uint128 _tokensOwed0, uint128 _tokensOwed1) = _pm.positions(info.lowerPositionId);
		_pm.collect(CollectParams({
			tokenId: info.lowerPositionId,
			recipient: _this,
			amount0Max: _weth0 ? _tokensOwed0 - _tokensOwedBefore0 : UINT128_MAX,
			amount1Max: !_weth0 ? _tokensOwed1 - _tokensOwedBefore1 : UINT128_MAX
		}));
		_pm.collect(CollectParams({
			tokenId: info.upperPositionId,
			recipient: _this,
			amount0Max: _weth0 ? 0 : UINT128_MAX,
			amount1Max: !_weth0 ? 0 : UINT128_MAX
		}));
		( , , , , , , , _liquidity, , , _tokensOwedBefore0, _tokensOwedBefore1) = _pm.positions(info.upperPositionId);
		_pm.decreaseLiquidity(DecreaseLiquidityParams({
			tokenId: info.upperPositionId,
			liquidity: _liquidity,
			amount0Min: 0,
			amount1Min: 0,
			deadline: block.timestamp
		}));
		( , , , , , , , , , , _tokensOwed0, _tokensOwed1) = _pm.positions(info.upperPositionId);
		_pm.collect(CollectParams({
			tokenId: info.upperPositionId,
			recipient: _this,
			amount0Max: _weth0 ? _tokensOwed0 - _tokensOwedBefore0 : UINT128_MAX,
			amount1Max: !_weth0 ? _tokensOwed1 - _tokensOwedBefore1 : UINT128_MAX
		}));
		_burn(_this, balanceOf(_this) - _balanceBefore);
		_weth.transfer(msg.sender, RUGGER_PERCENT * _weth.balanceOf(_this) / 100);
		info.rugged = true;
	}

	function refund() external {
		unchecked {
			require(rugged());
			claimRewards();
			uint256 _balance = balanceOf(msg.sender);
			require(_balance > 0);
			WETH _weth = WETH(ROUTER.WETH9());
			uint256 _refund = _weth.balanceOf(address(this)) * _balance / totalSupply();
			_burn(msg.sender, _balance);
			_weth.transfer(msg.sender, _refund);
		}
	}

	function claimRewards() public {
		unchecked {
			uint256 _rewards = rewardsOf(msg.sender);
			if (_rewards > 0) {
				info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
				_transfer(address(this), msg.sender, _rewards);
				emit ClaimRewards(msg.sender, _rewards);
			}
		}
	}
	
	function burn(uint256 _tokens) public {
		require(!rugged());
		_burn(msg.sender, _tokens);
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
	

	function rugged() public view returns (bool) {
		return info.rugged;
	}

	function owner() public view returns (address) {
		return info.owner;
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

	function rewardsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerToken * balanceOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function positions() external view returns (uint256 lower, uint256 upper) {
		return (info.lowerPositionId, info.upperPositionId);
	}

	function allInfoFor(address _user) external view returns (bool isRugged, uint256 totalTokens, uint256 wethBalance, uint256 userBalance, uint256 userRewards) {
		isRugged = rugged();
		totalTokens = totalSupply();
		wethBalance = WETH(ROUTER.WETH9()).balanceOf(address(this));
		userBalance = balanceOf(_user);
		userRewards = rewardsOf(_user);
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
			uint256 _fee = 0;
			if (!(_from == _this || _to == _this || _to == pool())) {
				_fee = _tokens * TRANSFER_FEE / 100;
				info.users[_this].balance += _fee;
				info.users[_this].scaledPayout += int256(_fee * info.scaledRewardsPerToken);
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
				info.scaledRewardsPerToken += _amount * FLOAT_SCALAR / (totalSupply() - balanceOf(pool()) - balanceOf(address(this)));
				emit Reward(_amount);
			}
		}
	}
}


/*

"The world is swirling with so many mysteries and secrets that
nobody will ever track down all of them. But with a book you can
stay up very late, reading until all the secrets are clear to
you. The questions of the world are hidden forever, but the
answers in a book are hiding in plain sight."
- Lemony Snicket

-----BEGIN PGP MESSAGE-----

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
Cg==
=gz7Q
-----END PGP MESSAGE-----

*/