// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './interfaces/IPYESwapPair.sol';
import './interfaces/IPYESwapRouter.sol';
import './PYESwapERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './libraries/ReentrancyGuard.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPYESwapFactory.sol';
import './interfaces/IPYESwapCallee.sol';
import './interfaces/IToken.sol';

contract PYESwapPair is IPYESwapPair, PYESwapERC20, ReentrancyGuard {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    IPYESwapRouter public routerAddress;

    address public immutable override factory;
    address public override token0;
    address public override token1;
    address public override baseToken;
    address public override feeTaker;
    bool public supportsTokenFee;
    bool public pairInit;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(msg.sender == address(routerAddress), "only router accessible");
        require(unlocked == 1, 'PYESwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast, address _baseToken) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
        _baseToken = baseToken;
    }

    function _safeTransfer(address token, address to, uint value, bool isSwapping) private nonReentrant {
        if(value == 0){
            return;
        }
        if (routerAddress.pairFeeAddress(address(this)) == token && isSwapping){
            uint256 adminFee = routerAddress.adminFee();
            if(adminFee != 0){
                uint256 getOutFee = value.mul(adminFee) / (10000);
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, routerAddress.adminFeeAddress(), getOutFee));
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'PYESwap: TRANSFER_FAILED');
                value = value.sub(getOutFee);
            }
            (bool success1, bytes memory data1) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
            require(success1 && (data1.length == 0 || abi.decode(data1, (bool))), 'PYESwap: TRANSFER_FAILED');
        }else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'PYESwap: TRANSFER_FAILED');
        }
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
    event Initialize(address token0, address token1, IPYESwapRouter router, address caller);
    event BaseTokenSet(address baseToken, address caller);
    event FeeTakerSet(address feeTaker, address caller);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, bool _supportsTokenFee) external override {
        require(msg.sender == factory, 'PYESwap: FORBIDDEN'); // sufficient check
        require(!pairInit, "PYESwap: INITIALIZED_ALREADY");
        require(_token0 != address(0) && _token1 != address(0), "PYESwap: INVALID_ADDRESS");
        token0 = _token0;
        token1 = _token1;
        supportsTokenFee = _supportsTokenFee;
        routerAddress = IPYESwapRouter(IPYESwapFactory(factory).routerAddress());
        pairInit = true;
        emit Initialize(token0, token1, routerAddress, msg.sender);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'PYESwap: OVERFLOW');
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

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IPYESwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
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
        require(liquidity > 0, 'PYESwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint amount0, uint amount1) {
        require(totalSupply != 0, "PYESwap: totalSupply must not be 0");
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'PYESwap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0, false);
        _safeTransfer(_token1, to, amount1, false);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, uint amount0Fee, uint amount1Fee, address to, bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0, 'PYESwap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'PYESwap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'PYESwap: INVALID_TO');
            if (amount0Out > 0) {
                _safeTransfer(_token0, to, amount0Out, true);
            }
            if (amount1Out > 0) {
                _safeTransfer(_token1, to, amount1Out, true);
            }

            if(amount0Fee > 0 && baseToken == token0) {
                bool success0 = IERC20(_token0).approve(_token1, amount0Fee);
                require(success0);
                IToken(_token1).handleFee(amount0Fee, _token0);
            }
            if(amount1Fee > 0 && baseToken == token1) {
                bool success1 = IERC20(_token1).approve(_token0, amount1Fee);
                require(success1);
                IToken(_token0).handleFee(amount1Fee, _token1);
            }

            if (data.length > 0) IPYESwapCallee(to).pyeSwapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'PYESwap: INSUFFICIENT_INPUT_AMOUNT');

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        require(balance0.mul(balance1) >= uint(_reserve0).mul(_reserve1), 'PYESwap: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        {
            uint _amount0Out = amount0Out > 0 ? amount0Out.add(amount0Fee) : 0;
            uint _amount1Out = amount1Out > 0 ? amount1Out.add(amount1Fee) : 0;
            address _to = to;
            emit Swap(msg.sender, amount0In, amount1In, _amount0Out, _amount1Out, _to);
        }
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0), false);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1), false);
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function setBaseToken(address _baseToken) external override {
        require(msg.sender == factory, "PYESwap: NOT_FACTORY");
        require(_baseToken == token0 || _baseToken == token1, "PYESwap: WRONG_ADDRESS");

        baseToken = _baseToken;
        emit BaseTokenSet(baseToken, msg.sender);
    }

    function setFeeTaker(address _feeTaker) external override {
        require(msg.sender == factory, "PYESwap: NOT_FACTORY");
        require(_feeTaker == token0 || _feeTaker == token1, "PYESwap: WRONG_ADDRESS");

        feeTaker = _feeTaker;
        emit FeeTakerSet(feeTaker, msg.sender);
    }
}