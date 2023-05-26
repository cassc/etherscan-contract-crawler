// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../tokens/HelixLP.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/ExtraMath.sol";
import "./HelixFactory.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract HelixPair is Initializable, HelixLP, ReentrancyGuardUpgradeable {
    using UQ112x112 for uint224;
    
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    
    uint32 public swapFee;              // uses 0.1% default
    uint32 public devFee;               // uses 0.5% default from swap fee

    event Mint(
        address indexed sender, 
        address indexed to,
        uint256 amount0, 
        uint256 amount1
    );

    event Burn(
        address indexed sender, 
        address indexed to,
        uint256 amount0, 
        uint256 amount1 
    );

    event Swap(
        address indexed sender,
        address indexed to,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );

    event Update(uint112 reserve0, uint112 reserve1);

    modifier onlyFactory() {
        require(msg.sender == factory, "Pair: not factory"); 
        _;
    }

    modifier onlyAboveZero(uint256 number) {
        require(number > 0, "Pair: not above zero");
        _;
    }

    function initialize(address _token0, address _token1, uint32 _swapFee) external initializer {
        __ReentrancyGuard_init();
        factory = msg.sender;

        token0 = _token0;
        token1 = _token1;

        swapFee = _swapFee; // uses 0.1% default
        devFee  = 0; // Do not send fees to factory.feeTo
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
    function setSwapFee(uint32 _swapFee) external onlyFactory onlyAboveZero(_swapFee) {
        require(_swapFee <= 1000, "Pair: invalid fee");
        swapFee = _swapFee;
    }
    
    function setDevFee(uint32 _devFee) external onlyFactory onlyAboveZero(_devFee) {
        require(_devFee <= 500, "Pair: invalid fee");
        devFee = _devFee;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "Pair: overflow");
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
        emit Update(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = ExtraMath.sqrt(uint(_reserve0) * _reserve1);
                uint256 rootKLast = ExtraMath.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = rootK * devFee + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = ExtraMath.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = MathUpgradeable.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, "Pair: insufficient minted");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, to, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings

        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        
        uint256 liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution

        require(amount0 > 0 && amount1 > 0, "Pair: insufficient burned");

        // Set the expected balance by subtracting amountX before _burn and safeTransfer calls
        // to perform all state changes before external calls and protect against reentrancy
        balance0 = IERC20(_token0).balanceOf(address(this)) - amount0;
        balance1 = IERC20(_token1).balanceOf(address(this)) - amount1;

        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date

        _burn(address(this), liquidity);
        TransferHelper.safeTransfer(_token0, to, amount0);
        TransferHelper.safeTransfer(_token1, to, amount1);

        emit Burn(msg.sender, to, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "Pair: insufficient amount out");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "Pair: insufficient liquidity");

        uint256 balance0;
        uint256 balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Pair: invalid to");
            if (amount0Out > 0) TransferHelper.safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) TransferHelper.safeTransfer(_token1, to, amount1Out);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "Pair: insufficient amount in");
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 _swapFee = swapFee;
            uint256 balance0Adjusted = balance0 * (1000) - (amount0In * _swapFee);
            uint256 balance1Adjusted = balance1 * (1000) - (amount1In * _swapFee);
            require(
                balance0Adjusted * balance1Adjusted >= uint(_reserve0) * (_reserve1) * (1000**2), 
                "Pair: insufficient reserves"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        HelixFactory(factory).updateOracle(token0, token1);

        emit Swap(msg.sender, to, amount0In, amount1In, amount0Out, amount1Out);
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        TransferHelper.safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        TransferHelper.safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}