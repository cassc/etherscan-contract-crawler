pragma solidity =0.5.16;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import './KyotoSwapERC20.sol';
import '@uniswap/v2-core/contracts/libraries/Math.sol';
import '@uniswap/v2-core/contracts/libraries/UQ112x112.sol';
import '@uniswap/v2-core/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

contract KyotoSwapPair is IUniswapV2Pair, KyotoSwapERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public controllerFeeAddress;
    address public token0;
    address public token1;

    uint public constant MAX_FEE_AMOUNT = 100; // = 1%
    uint public constant MIN_FEE_AMOUNT = 0; // = 0.01%

    uint public constant MAX_LP_FEE_AMOUNT = 25; // = 1%
    uint public constant MIN_LP_FEE_AMOUNT = 0; // = 0.01%
    uint256 public feeAmount = 25; // default = 0.25% . LP HOLDERS
    uint public controllerFeeShare = 0; // By default 0% Controller Fee

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    struct FeesAndAmounts {
        uint256 fee0;
        uint256 fee1;
        uint256 amount0OutAfterFee;
        uint256 amount1OutAfterFee;
    }

    struct AmountsIn {
        uint256 amount0In;
        uint256 amount1In;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'KyotoSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'KyotoSwap: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'KyotoSwap: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    function setFeeAmount(uint256 _feeAmount) external {
        require(
            msg.sender == IUniswapV2Factory(factory).feeToSetter(),
            "KyotoSwapPair: only factory's feeToSetter"
        );
        require(_feeAmount <= MAX_LP_FEE_AMOUNT, "KyotoSwapPair: feeAmount mustn't exceed the maximum");
        require(_feeAmount >= MIN_LP_FEE_AMOUNT, "KyotoSwapPair: feeAmount mustn't exceed the minimum");
        feeAmount = _feeAmount;
    }

    function setControllerFeeAmount(uint _controllerFeeShare) external {
        require(
            msg.sender == IUniswapV2Factory(factory).feeToSetter(),
            "KyotoSwapPair: only factory's feeToSetter"
        );
        require(
            _controllerFeeShare <= MAX_FEE_AMOUNT,
            "KyotoSwapPair: controllerFeeShare mustn't exceed the maximum"
        );
        require(
            _controllerFeeShare >= MIN_FEE_AMOUNT,
            "KyotoSwapPair: controllerFeeShare mustn't exceed the minimum"
        );
        controllerFeeShare = _controllerFeeShare;
    }

    function setControllerFeeAddress(address _controllerFeeAddress) external {
        require(_controllerFeeAddress != address(0),
            "Cannot be zero address"
        );
        require(
            msg.sender == IUniswapV2Factory(factory).feeToSetter(),
            "KyotoSwapPair: only factory's feeToSetter"
        );
        controllerFeeAddress = _controllerFeeAddress;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'KyotoSwap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 8/25 of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(8);
                    uint denominator = rootK.mul(17).add(rootKLast.mul(8));
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'KyotoSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'KyotoSwap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'KyotoSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'KyotoSwap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        FeesAndAmounts memory feesAndAmounts = _getFeesAndAmounts(amount0Out, amount1Out);

        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'KyotoSwap: INVALID_TO');
        if (amount0Out > 0) {

          if (feesAndAmounts.fee0 > 0)
              _safeTransfer(_token0, controllerFeeAddress, feesAndAmounts.fee0);         
          _safeTransfer(_token0, to, feesAndAmounts.amount0OutAfterFee);   // optimistically transfer tokens
        } 
        if (amount1Out > 0) {
                if (feesAndAmounts.fee1 > 0)
                    _safeTransfer(_token1, controllerFeeAddress, feesAndAmounts.fee1);
                _safeTransfer(_token1, to, feesAndAmounts.amount1OutAfterFee);   // optimistically transfer tokens
            }
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, feesAndAmounts.amount0OutAfterFee, feesAndAmounts.amount1OutAfterFee, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        AmountsIn memory amountsIn = AmountsIn(
            balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0,
            balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0
        );
        
        require(amountsIn.amount0In > 0 || amountsIn.amount1In > 0, 'KyotoSwap: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = (balance0.mul(10000).sub(amountsIn.amount0In.mul(feeAmount)));
            uint balance1Adjusted = (balance1.mul(10000).sub(amountsIn.amount1In.mul(feeAmount)));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10000**2), 'KyotoSwapPair: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amountsIn.amount0In, amountsIn.amount1In, amount0Out, amount1Out, to);
    }

    function _getFeesAndAmounts(uint256 amount0Out, uint256 amount1Out) private view returns (FeesAndAmounts memory) {
        uint256 fee0 = amount0Out.mul(controllerFeeShare) / 10000;
        uint256 fee1 = amount1Out.mul(controllerFeeShare) / 10000;
        if (controllerFeeShare > 0) {
            if (amount0Out > 0 && fee0 < 1) fee0 = 1;
            if (amount1Out > 0 && fee1 < 1) fee1 = 1;
        }
        return FeesAndAmounts(fee0, fee1, amount0Out - fee0, amount1Out - fee1);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}