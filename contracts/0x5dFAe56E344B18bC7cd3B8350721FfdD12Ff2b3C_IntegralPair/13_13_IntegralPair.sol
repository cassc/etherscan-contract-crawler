// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralPair.sol';
import 'Reserves.sol';
import 'IntegralERC20.sol';
import 'Math.sol';
import 'IERC20.sol';
import 'IIntegralFactory.sol';
import 'IIntegralOracle.sol';
import 'Normalizer.sol';

contract IntegralPair is Reserves, IntegralERC20, IIntegralPair {
    using SafeMath for uint256;
    using Normalizer for uint256;

    uint256 private constant PRECISION = 10**18;

    uint256 public override mintFee = 0;
    uint256 public override burnFee = 0;
    uint256 public override swapFee = 0;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;
    uint256 private constant TRADE_MOE = 100000001 * 10**10; // Margin Of Error

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;
    address public override token1;
    address public override oracle;
    address public override trader;

    uint256 private lastPrice;

    uint256 public override token0AbsoluteLimit = uint256(-1);
    uint256 public override token1AbsoluteLimit = uint256(-1);
    uint256 public override token0RelativeLimit = PRECISION; // 100%
    uint256 public override token1RelativeLimit = PRECISION; // 100%
    uint256 public override priceDeviationLimit = uint256(-1);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'IP_LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setMintFee(uint256 fee) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        mintFee = fee;
        emit SetMintFee(mintFee);
    }

    function setBurnFee(uint256 fee) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        burnFee = fee;
        emit SetBurnFee(burnFee);
    }

    function setSwapFee(uint256 fee) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        swapFee = fee;
        emit SetSwapFee(swapFee);
    }

    function setOracle(address _oracle) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        require(_oracle != address(0), 'IP_ADDRESS_ZERO');
        require(isContract(_oracle), 'IP_ORACLE_MUST_BE_CONTRACT');
        oracle = _oracle;
        setReferencesToReserves(0);
        emit SetOracle(oracle);
    }

    function setTrader(address _trader) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        trader = _trader;
        emit SetTrader(trader);
    }

    function setToken0AbsoluteLimit(uint256 _token0AbsoluteLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token0AbsoluteLimit = _token0AbsoluteLimit;
        emit SetToken0AbsoluteLimit(token0AbsoluteLimit);
    }

    function setToken1AbsoluteLimit(uint256 _token1AbsoluteLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token1AbsoluteLimit = _token1AbsoluteLimit;
        emit SetToken1AbsoluteLimit(token1AbsoluteLimit);
    }

    function setToken0RelativeLimit(uint256 _token0RelativeLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token0RelativeLimit = _token0RelativeLimit;
        emit SetToken0RelativeLimit(token0RelativeLimit);
    }

    function setToken1RelativeLimit(uint256 _token1RelativeLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        token1RelativeLimit = _token1RelativeLimit;
        emit SetToken1RelativeLimit(token1RelativeLimit);
    }

    function setPriceDeviationLimit(uint256 _priceDeviationLimit) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        priceDeviationLimit = _priceDeviationLimit;
        emit SetPriceDeviationLimit(priceDeviationLimit);
    }

    function collect(address to) external override lock {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        (uint256 fee0, uint256 fee1) = getFees();
        if (fee0 > 0) _safeTransfer(token0, to, fee0);
        if (fee1 > 0) _safeTransfer(token1, to, fee1);
        setFees(0, 0);
        _sync();
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'IP_TRANSFER_FAILED');
    }

    function canTrade(address user) private view returns (bool) {
        return user == trader || user == factory || trader == address(-1);
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external override {
        require(msg.sender == factory, 'IP_FORBIDDEN');
        require(_oracle != address(0), 'IP_ADDRESS_ZERO');
        require(isContract(_oracle), 'IP_ORACLE_MUST_BE_CONTRACT');
        require(isContract(_token0) && isContract(_token1), 'IP_TOKEN_MUST_BE_CONTRACT');
        token0 = _token0;
        token1 = _token1;
        oracle = _oracle;
        trader = _trader;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint256 liquidity) {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 amount0 = balance0.sub(reserve0);
        uint256 amount1 = balance1.sub(reserve1);

        _syncWithOracle();

        uint256 _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / reserve0, amount1.mul(_totalSupply) / reserve1);
        }

        require(liquidity > 0, 'IP_INSUFFICIENT_LIQUIDITY_MINTED');
        uint256 fee = liquidity.mul(mintFee).div(PRECISION);
        uint256 effectiveLiquidity = liquidity.sub(fee);
        _mint(to, effectiveLiquidity);
        _mint(factory, fee);

        adjustReserves(balance0, balance1);

        emit Mint(msg.sender, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint256 amount0, uint256 amount1) {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 liquidity = balanceOf[address(this)];
        uint256 _totalSupply = totalSupply; // gas savings

        _syncWithOracle();

        uint256 fee = 0;
        if (msg.sender != factory) {
            fee = liquidity.mul(burnFee).div(PRECISION);
            _transfer(address(this), factory, fee);
        }
        uint256 effectiveLiquidity = liquidity.sub(fee);
        _burn(address(this), effectiveLiquidity);

        amount0 = effectiveLiquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = effectiveLiquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'IP_INSUFFICIENT_LIQUIDITY_BURNED');

        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        (balance0, balance1) = getBalances(token0, token1);
        adjustReserves(balance0, balance1);

        emit Burn(msg.sender, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external override lock {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        require(to != address(0), 'IP_ADDRESS_ZERO');
        require(amount0Out > 0 || amount1Out > 0, 'IP_INSUFFICIENT_OUTPUT_AMOUNT');
        require(amount0Out == 0 || amount1Out == 0, 'IP_MULTIPLE_OUTPUTS_SPECIFIED');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'IP_INSUFFICIENT_LIQUIDITY');

        _syncWithOracle();

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'IP_INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        }
        (uint256 balance0, uint256 balance1) = getBalances(token0, token1);
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'IP_INSUFFICIENT_INPUT_AMOUNT');

        if (amount0Out > 0) {
            // trading token1 for token0
            (uint112 reference0, uint112 reference1, ) = getReferences();

            uint256 fee1 = amount1In.mul(swapFee).div(PRECISION);
            uint256 balance0After = IIntegralOracle(oracle).tradeY(balance1.sub(fee1), reference0, reference1);
            require(balance0 >= balance0After, 'IP_INVALID_SWAP');
            _checkToken0Limits(balance0After, reference0);
            uint256 fee0 = balance0.sub(balance0After);
            addFees(fee0, fee1);
            updateReserves(balance0.sub(fee0), balance1.sub(fee1));
        } else {
            // trading token0 for token1
            (uint112 reference0, uint112 reference1, ) = getReferences();

            uint256 fee0 = amount0In.mul(swapFee).div(PRECISION);
            uint256 balance1After = IIntegralOracle(oracle).tradeX(balance0.sub(fee0), reference0, reference1);
            require(balance1 >= balance1After, 'IP_INVALID_SWAP');
            _checkToken1Limits(balance1After, reference1);
            uint256 fee1 = balance1.sub(balance1After);
            addFees(fee0, fee1);
            updateReserves(balance0.sub(fee0), balance1.sub(fee1));
        }

        _checkPriceDeviationLimit();
        emit Swap(msg.sender, to);
    }

    function _checkPriceDeviationLimit() private view {
        uint256 currentPrice = getSpotPrice();

        if (lastPrice > 0) {
            uint256 difference = lastPrice > currentPrice ? lastPrice.sub(currentPrice) : currentPrice.sub(lastPrice);

            require(difference.mul(PRECISION).div(lastPrice) <= priceDeviationLimit, 'IP_P_LIMIT_EXCEEDED');
        }
    }

    function _checkToken0Limits(uint256 balance0After, uint112 reference0) private view {
        if (balance0After < reference0) {
            uint256 difference = uint256(reference0).sub(balance0After);
            require(difference <= token0AbsoluteLimit, 'IP_A0_LIQUIDITY_LIMIT_EXCEEDED');
            require(difference.mul(PRECISION).div(reference0) <= token0RelativeLimit, 'IP_R0_LIQUIDITY_LIMIT_EXCEEDED');
        }
    }

    function _checkToken1Limits(uint256 balance1After, uint112 reference1) private view {
        if (balance1After < reference1) {
            uint256 difference = uint256(reference1).sub(balance1After);
            require(difference <= token1AbsoluteLimit, 'IP_A1_LIQUIDITY_LIMIT_EXCEEDED');
            require(difference.mul(PRECISION).div(reference1) <= token1RelativeLimit, 'IP_R1_LIQUIDITY_LIMIT_EXCEEDED');
        }
    }

    function sync() public override lock {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        _sync();
    }

    // force reserves to match balances
    function _sync() internal {
        syncReserves(token0, token1);
        uint256 tokens = balanceOf[address(this)];
        if (tokens > 0) {
            _transfer(address(this), factory, tokens);
        }
    }

    function syncWithOracle() external override {
        _syncWithOracle();
    }

    function fullSync() external override {
        require(canTrade(msg.sender), 'IP_UNAUTHORIZED_TRADER');
        _sync();
        _syncWithOracle();
    }

    function _syncWithOracle() internal {
        uint32 epoch = IIntegralOracle(oracle).updatePrice();
        (, , uint32 lastEpoch) = getReferences();
        if (epoch != lastEpoch) {
            setReferencesToReserves(epoch);
            lastPrice = getSpotPrice();
        }
    }

    function getSpotPrice() public view override returns (uint256 spotPrice) {
        (uint112 reserve0, , ) = getReserves();
        (uint112 reference0, , ) = getReferences();
        return IIntegralOracle(oracle).getSpotPrice(reserve0, reference0);
    }

    function getSwapAmount0In(uint256 amount1Out) public view override returns (uint256 swapAmount0In) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 balance1After = uint256(reserve1).sub(amount1Out);
        uint256 balance0After = IIntegralOracle(oracle).tradeY(balance1After, reference0, reference1);
        return balance0After.sub(uint256(reserve0)).mul(TRADE_MOE).div(PRECISION.sub(swapFee));
    }

    function getSwapAmount1In(uint256 amount0Out) public view override returns (uint256 swapAmount1In) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 balance0After = uint256(reserve0).sub(amount0Out);
        uint256 balance1After = IIntegralOracle(oracle).tradeX(balance0After, reference0, reference1);
        return balance1After.sub(uint256(reserve1)).mul(TRADE_MOE).div(PRECISION.sub(swapFee));
    }

    function getSwapAmount0Out(uint256 amount1In) public view override returns (uint256 swapAmount0Out) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 fee = amount1In.mul(swapFee).div(PRECISION);
        uint256 balance0After = IIntegralOracle(oracle).tradeY(
            uint256(reserve1).add(amount1In).sub(fee),
            reference0,
            reference1
        );
        return uint256(reserve0).sub(balance0After);
    }

    function getSwapAmount1Out(uint256 amount0In) public view override returns (uint256 swapAmount1Out) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        (uint112 reference0, uint112 reference1, ) = getReferences();
        uint256 fee = amount0In.mul(swapFee).div(PRECISION);
        uint256 balance1After = IIntegralOracle(oracle).tradeX(
            uint256(reserve0).add(amount0In).sub(fee),
            reference0,
            reference1
        );
        return uint256(reserve1).sub(balance1After);
    }

    function getDepositAmount0In(uint256 amount0) external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        uint8 decimals0 = IIntegralOracle(oracle).xDecimals();
        uint8 decimals1 = IIntegralOracle(oracle).yDecimals();

        uint256 P = getSpotPrice();
        uint256 a = amount0.normalize(decimals0);
        uint256 A = uint256(reserve0).normalize(decimals0);
        uint256 B = uint256(reserve1).normalize(decimals1);

        // ratio after swap = ratio after second mint
        // (A + x) / (B - x * P) = (A + a) / B
        // x = a * B / (P * (a + A) + B)
        uint256 numeratorTimes1e18 = a.mul(B);
        uint256 denominator = P.mul(a.add(A)).div(1e18).add(B);
        uint256 x = numeratorTimes1e18.div(denominator);
        // Don't swap when numbers are too large. This should actually never happen
        if (x.mul(P).div(1e18) >= B || x >= a) {
            return 0;
        }
        return x.denormalize(decimals0);
    }

    function getDepositAmount1In(uint256 amount1) external view override returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }
        uint8 decimals0 = IIntegralOracle(oracle).xDecimals();
        uint8 decimals1 = IIntegralOracle(oracle).yDecimals();

        uint256 P = getSpotPrice();
        uint256 b = amount1.normalize(decimals1);
        uint256 A = uint256(reserve0).normalize(decimals0);
        uint256 B = uint256(reserve1).normalize(decimals1);

        // ratio after swap = ratio after second mint
        // (A - x / P) / (B + x) = A / (B + b)
        // x = A * b * P / (A * P + b + B)
        uint256 numeratorTimes1e18 = A.mul(b).div(1e18).mul(P);
        uint256 denominator = A.mul(P).div(1e18).add(b).add(B);
        uint256 x = numeratorTimes1e18.div(denominator);
        // Don't swap when numbers are too large. This should actually never happen
        if (x.mul(1e18).div(P) >= A || x >= b) {
            return 0;
        }
        return x.denormalize(decimals1);
    }
}