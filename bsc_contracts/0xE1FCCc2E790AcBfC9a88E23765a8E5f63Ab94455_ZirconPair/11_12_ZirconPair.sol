// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;

import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IZirconPair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import './libraries/SafeMath.sol';
import "./ZirconERC20.sol";
import "./interfaces/IZirconFactory.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol';

import "./libraries/ZirconLibrary.sol";
import "./energy/interfaces/IZirconEnergyRevenue.sol";

contract ZirconPair is IZirconPair, ZirconERC20 { //Name change does not affect ABI
    using SafeMath for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    address public energyRevenueAddress;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // us es single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()  public view returns  (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
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


    constructor() ZirconERC20("Zircon", "ZPT") public {
        factory = msg.sender;
    }

    function tryLock() external lock {}

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _energy) external {
        require(msg.sender == factory, 'ZirconPair: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        energyRevenueAddress = _energy;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1,
        uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
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

    //Wrapper around mintFee primarily aimed to be called by Pylon
    //Access control is unnecessary, if anyone calls it they just waste gas compounding fees for us
    //The wrapper is necessary to make sure the reserves it passes to mintFee are actual
    function publicMintFee() external lock {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        _mintFee(_reserve0, _reserve1);

        kLast = uint(reserve0).mul(reserve1); //Reserves don't change from mintFee
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private {
    uint _kLast = kLast; // gas savings
        if (_kLast != 0) {
            uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
            uint rootKLast = Math.sqrt(_kLast);
            if (rootK > rootKLast) {
                uint dynamicRatio = IZirconFactory(factory).dynamicRatio();
                uint numerator = (rootK.sub(rootKLast)).mul(1e18);
                uint denominator = rootK.mul(dynamicRatio).add(rootKLast);
                uint liquidityPercentage = numerator / denominator;

                if (liquidityPercentage > 0) {
                    _mint(energyRevenueAddress, liquidityPercentage.mul(totalSupply)/1e18);
                    uint totalPercentage = ((rootK.sub(rootKLast)).mul(1e18))/rootKLast;
                    IZirconEnergyRevenue(energyRevenueAddress).calculate(totalPercentage.sub(liquidityPercentage));
                }
            }
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IUniswapV2ERC20(token0).balanceOf(address(this));
        uint balance1 = IUniswapV2ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // TODO: will be better if we pass the output amount
    function mintOneSide(address to, bool isReserve0) external lock returns (uint liquidity, uint amount0, uint amount1) {
        require(totalSupply > 0, 'UniswapV2: Use mint to start pair');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        uint balance0 = IUniswapV2ERC20(token0).balanceOf(address(this));
        uint balance1 = IUniswapV2ERC20(token1).balanceOf(address(this));
        amount0 = balance0.sub(_reserve0);
        amount1 = balance1.sub(_reserve1);

        uint _liquidityFee = IZirconFactory(factory).liquidityFee();
        uint k;

        // We use growth in sqrt(k) to calculate amount of pool tokens to mint. This implicitly takes care of slippage.
        // Fee is slightly more than half total amount to account for residue you'd have if you swapped then minted normally

        if (isReserve0){
            require(amount0 > 1, "ZP: Insufficient Amount");
            k = Math.sqrt(uint(reserve0 + (amount0.mul(10000-(_liquidityFee/2 + 1))/10000)).mul(balance1));
        }else{
            require(amount1 > 1, "ZP: Insufficient Amount");
            k = Math.sqrt(balance0.mul(uint(reserve1 + (amount1.mul(10000-(_liquidityFee/2 + 1))/10000))));
        }
        uint kBefore = Math.sqrt(uint(reserve0).mul(reserve1));

        uint numerator = (k.sub(kBefore)).mul(totalSupply);
        uint denominator = kBefore;
        liquidity = numerator / denominator;
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        _mintFee(_reserve0, _reserve1);

        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UV2: IIA');
        require(reserveIn > 0 && reserveOut > 0, 'UV2: IL');
        uint amountInWithFee = amountIn.mul(10000-fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // this low-level function should be called from a contract which performs important safety checks
    // TODO: Test this function
    // TODO: maybe allow burning both sides to one
    function burnOneSide(address to, bool isReserve0) external lock returns (uint amount) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint amount0;
        uint amount1;
        uint balance0 = IUniswapV2ERC20(_token0).balanceOf(address(this));
        uint balance1 = IUniswapV2ERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        uint _liquidityFee = IZirconFactory(factory).liquidityFee();

        _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution

        if (isReserve0) {
            amount0 += getAmountOut(amount1, _reserve1 - amount1, _reserve0 - amount0, _liquidityFee);
            amount = amount0;
            require(amount < balance0, "UniswapV2: EXTENSION_NOT_ENOUGH_LIQUIDITY");
        }else{
            amount1 += getAmountOut(amount0, _reserve0 - amount0, _reserve1 - amount1, _liquidityFee);
            amount = amount1;
            require(amount < balance1, "UniswapV2: EXTENSION_NOT_ENOUGH_LIQUIDITY");
        }

        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        if (isReserve0) {
            _safeTransfer(_token0, to, amount);
        }else{
            _safeTransfer(_token1, to, amount);
        }
        balance0 = IUniswapV2ERC20(_token0).balanceOf(address(this));
        balance1 = IUniswapV2ERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IUniswapV2ERC20(_token0).balanceOf(address(this));
        uint balance1 = IUniswapV2ERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IUniswapV2ERC20(_token0).balanceOf(address(this));
        balance1 = IUniswapV2ERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)  external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IUniswapV2ERC20(_token0).balanceOf(address(this));
            balance1 = IUniswapV2ERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint _liquidityFee = IZirconFactory(factory).liquidityFee();
            uint balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(_liquidityFee));
            uint balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(_liquidityFee));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
//    function skim(address to)  external lock {
//        address _token0 = token0; // gas savings
//        address _token1 = token1; // gas savings
//        _safeTransfer(_token0, to, IUniswapV2ERC20(_token0).balanceOf(address(this)).sub(reserve0));
//        _safeTransfer(_token1, to, IUniswapV2ERC20(_token1).balanceOf(address(this)).sub(reserve1));
//    }

    // force reserves to match balances
    function sync() external lock {
        _update(IUniswapV2ERC20(token0).balanceOf(address(this)), IUniswapV2ERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function changeEnergyRevAddress(address _revAddress) external {
        require(msg.sender == factory, 'UniswapV2: NOT_ALLOWED');
        energyRevenueAddress = _revAddress;
    }

//    // Just for testing purposes
//    // Should be deleted on deployment
//    function mintTest(address to, uint amount) external {
//        _mint(to, amount);
//    }

//    // Same here
//    function reservesTest() external {
//        uint balance0 = IUniswapV2ERC20(token0).balanceOf(address(this));
//        uint balance1 = IUniswapV2ERC20(token1).balanceOf(address(this));
//
//        reserve0 = uint112(balance0);
//        reserve1 = uint112(balance1);
//
//        kLast = uint(reserve0).mul(reserve1);
//    }
}