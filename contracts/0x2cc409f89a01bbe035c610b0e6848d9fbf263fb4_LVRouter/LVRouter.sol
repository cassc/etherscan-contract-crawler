/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

/** powered by 科技驴 */
/** 聚合路由合约 */
/** https://t.me/lvlvgroup */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

uint160 constant MIN_SQRT_RATIO = 4295128739;
uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); } }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b > a) return (false, 0); return (true, a - b); } }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); } }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a / b); } }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a % b); } }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b <= a, errorMessage); return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a / b; } }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a % b; } }
    function toUint160(uint256 y) internal pure returns (uint160 z) { require((z = uint160(y)) == y); }
    function toInt128(int256 y) internal pure returns (int128 z) { require((z = int128(y)) == y); }
    function toInt256(uint256 y) internal pure returns (int256 z) { require(y < 2**255); z = int256(y); }
}

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');
        bytes memory tempBytes;
        assembly {
            switch iszero(_length)
                case 0 {
                    tempBytes := mload(0x40)
                    let lengthmod := and(_length, 31)
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)
                    for {
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }
                    mstore(tempBytes, _length)
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                default {
                    tempBytes := mload(0x40)
                    mstore(tempBytes, 0)
                    mstore(0x40, add(tempBytes, 0x20))
                }
        }
        return tempBytes;
    }
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;
        assembly { tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000) }
        return tempAddress;
    }
    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;
        assembly { tempUint := mload(add(add(_bytes, 0x3), _start)) }
        return tempUint;
    }
}

library Path {
    using BytesLib for bytes;
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;
    function hasMultiplePools(bytes memory path) internal pure returns (bool) { return path.length >= MULTIPLE_POOLS_MIN_LENGTH; }
    function numPools(bytes memory path) internal pure returns (uint256) { return ((path.length - ADDR_SIZE) / NEXT_OFFSET); }
    function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) { return path.slice(0, POP_OFFSET); }
    function skipToken(bytes memory path) internal pure returns (bytes memory) { return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET); }
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeApprove: approve failed'); }
    function safeTransfer(address token, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeTransfer: transfer failed'); }
    function safeTransferFrom(address token, address from, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::transferFrom: transferFrom failed'); }
    function safeTransferETH(address to, uint256 value) internal { (bool success, ) = to.call{value: value}(new bytes(0)); require(success, 'TransferHelper::safeTransferETH: ETH transfer failed'); }
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

interface IFactoryV2 {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IFactoryV3 {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IPairV2 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IPoolV3 {
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external returns (int256 amount0, int256 amount1);
}

abstract contract TokenBus {
    using SafeMath for uint256;
    address public immutable _WETH;
    
    address public immutable _DEV;
    uint256 public _ETH_FEE_AMOUNT; // 在个别涉及到ETH输出的方法中有0.1%的手续费，且不造成额外的gas消耗
    uint256 public _ETH_FEE = 1; // 0.1%

    constructor(address WETH_, address DEV_) { _WETH = WETH_; _DEV = DEV_; }

    function setEthFee(uint256 fee) public {
        require(msg.sender == _DEV);
        require(fee <= 5);
        _ETH_FEE = fee;
    }

    function claimEthFee() public {
        require(msg.sender == _DEV);
        uint256 balance = address(this).balance;
        if (balance > 0) {
            TransferHelper.safeTransferETH(_DEV, balance);
            _ETH_FEE_AMOUNT = 0;
        }
    }

    function eth2weth() public payable {
        uint256 balance = address(this).balance;
        if (balance > _ETH_FEE_AMOUNT) {
            IWETH(_WETH).deposit{ value: balance.sub(_ETH_FEE_AMOUNT) }();
        } 
    }

    function sweepETH(address to) public payable {
        uint256 balance = address(this).balance;
        if (balance > _ETH_FEE_AMOUNT) {
            balance = balance.sub(_ETH_FEE_AMOUNT);
            uint256 _feeAmount = balance.mul(_ETH_FEE).div(1000);
            _ETH_FEE_AMOUNT = _ETH_FEE_AMOUNT.add(_feeAmount);
            balance = balance.sub(_feeAmount);
            TransferHelper.safeTransferETH(to, balance);
        }
    }

    function sweepWETH(address to) public payable {
        uint256 balance = IWETH(_WETH).balanceOf(address(this));
        if (balance > 0) {
            IWETH(_WETH).withdraw(balance);
            uint256 _feeAmount = balance.mul(_ETH_FEE).div(1000);
            _ETH_FEE_AMOUNT = _ETH_FEE_AMOUNT.add(_feeAmount);
            balance = balance.sub(_feeAmount);
            TransferHelper.safeTransferETH(to, balance);
        }
    }

    function sweepTokens(address[] memory tokens, address to) public payable {
        for (uint i; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) TransferHelper.safeTransfer(token, to, balance);
        }
    }
}

abstract contract RouterV2 is TokenBus {
    using SafeMath for uint;
    struct DEX { address factory; uint256 swapfee; }

    function sniper_exactInputV2(DEX memory dex, address[] memory path1, uint256 amountIn, uint256 amountOut, address to, uint256 buyfeemax, uint256 sellfeemax) public payable { 
        (uint256[] memory amounts, uint256 amount) = exactInputV2(dex, path1, amountIn, amountOut, to);
        require(amount >= amounts[amounts.length - 1].mul(100 - buyfeemax).div(100), "BUY FEE TOO HIGH");

        address[] memory path2 = new address[](2);
        path2[0] = path1[path1.length - 1];
        path2[1] = path1[path1.length - 2];
        (amounts, amount) = exactInputV2(dex, path2, amount.div(1000), 0, _DEV);
        require(amount >= amounts[amounts.length - 1].mul(100 - sellfeemax).div(100), "SELL FEE TOO HIGH");
    }

    function sniper_exactOutputV2(DEX memory dex, address[] memory path1, uint256 amountIn, uint256 amountOut, address to, uint256 buyfeemax, uint256 sellfeemax) public payable {
        (uint256[] memory amounts, uint256 amount) = exactOutputV2(dex, path1, amountIn, amountOut, to);
        require(amount >= amounts[amounts.length - 1].mul(100 - buyfeemax).div(100), "BUY FEE TOO HIGH");

        address[] memory path2 = new address[](2);
        path2[0] = path1[path1.length - 1];
        path2[1] = path1[path1.length - 2];
        (amounts, amount) = exactInputV2(dex, path2, amount.div(1000), 0, _DEV);
        require(amount >= amounts[amounts.length - 1].mul(100 - sellfeemax).div(100), "SELL FEE TOO HIGH");
    }

    function exactInputV2(DEX memory dex, address[] memory path, uint256 amountIn, uint256 amountOut, address to) public payable returns (uint256[] memory amounts, uint256 amount) {
        address[] memory pairs = getPairs(dex.factory, path);
        amounts = getAmountsOut(dex, amountIn, path, pairs);
        require(amounts[amounts.length - 1] >= amountOut, "INSUFFICIENT OUTPUT AMOUNT");
        if (path[0] == _WETH) TransferHelper.safeTransfer(path[0], pairs[0], amountIn);
        else TransferHelper.safeTransferFrom(path[0], msg.sender, pairs[0], amountIn);
        if (path[path.length - 1] == _WETH) to = address(this);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(pairs[i], path[i], path[i + 1]);
            uint256 _amountOut = getAmountOut(dex, IERC20(path[i]).balanceOf(address(pairs[i])).sub(reserveIn), reserveIn, reserveOut);
            swap(path[i], path[i + 1], _amountOut, pairs[i], pairs.length - 1 == i ? to : pairs[i + 1]);
        }

        amount = IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
        require(amount >= amountOut, "INSUFFICIENT OUTPUT AMOUNT");
    }

    function exactOutputV2(DEX memory dex, address[] memory path, uint256 amountIn, uint256 amountOut, address to) public payable returns (uint256[] memory amounts, uint256 amount) {
        address[] memory pairs = getPairs(dex.factory, path);
        amounts = getAmountsIn(dex, amountOut, path, pairs);
        require(amounts[0] <= amountIn, "EXCESSIVE INPUT AMOUNT");
        if (path[0] == _WETH) TransferHelper.safeTransfer(path[0], pairs[0], amounts[0]);
        else TransferHelper.safeTransferFrom(path[0], msg.sender, pairs[0], amounts[0]);
        if (path[path.length - 1] == _WETH) to = address(this);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        for (uint256 i; i < path.length - 1; i++) {
            swap(path[i], path[i + 1], amounts[i + 1], pairs[i], pairs.length - 1 == i ? to : pairs[i + 1]);
        } 

        amount = IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
    }

    function getAmountsOut(DEX memory dex, uint256 amountIn, address[] memory path, address[] memory pairs) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(pairs[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(dex, amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(DEX memory dex, uint256 amountOut, address[] memory path, address[] memory pairs) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(pairs[i - 1], path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(dex, amounts[i], reserveIn, reserveOut);
        }
    }

    function getPairs(address factory, address[] memory path) public view returns (address[] memory pairs) {
        pairs = new address[](path.length - 1);
        for (uint256 i; i < path.length - 1; i++) pairs[i] = getPair(factory, path[i], path[i + 1]);
    }

    function getPair(address factory, address tokenA, address tokenB) internal view returns (address pair) { pair = IFactoryV2(factory).getPair(tokenA, tokenB); require(pair != address(0), "NO PAIR"); }

    function swap(address tokenA, address tokenB, uint256 amountOut, address lp, address to) public {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 amount0Out, uint256 amount1Out) = tokenA == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IPairV2(lp).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) { (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); }

    function getReserves(address pair, address tokenA, address tokenB) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPairV2(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    function getAmountOut(DEX memory dex, uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT INPUT AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(dex.swapfee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(DEX memory dex, uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "INSUFFICIENT OUTPUT AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(dex.swapfee);
        amountIn = (numerator / denominator).add(1);
    }
}

abstract contract RouterV3 is TokenBus {
    using SafeMath for uint;
    using Path for bytes;

    struct CallData { address factory; bytes path; address payer; }

    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    address private lastCalledPool = address(0);

    receive() external payable {}
    
    function exactInputV3(address factory, bytes memory path, uint256 _amountIn, uint256 _amountOut, address to) public payable returns (uint256 amountOut) {
        address payer = msg.sender;
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();
            _amountIn = exactInputInternal(_amountIn, hasMultiplePools ? address(this) : to, CallData({ factory: factory, path: path.getFirstPool(), payer: payer }));
            if (hasMultiplePools) {
                payer = address(this);
                path = path.skipToken();
            } else {
                amountOut = _amountIn;
                break;
            }
        }
        require(amountOut >= _amountOut, 'INSUFFICIENT OUTPUT AMOUNT');
    }

    function exactOutputV3(address factory, bytes memory path, uint256 _amountIn, uint256 _amountOut, address to) public payable returns (uint256 amountIn) {
        exactOutputInternal(_amountOut, to, CallData({factory: factory, path: path, payer: msg.sender}));
        amountIn = amountInCached;
        require(amountIn <= _amountIn, 'EXCESSIVE INPUT AMOUNT');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    // 通用支付
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == _WETH && address(this).balance.sub(_ETH_FEE_AMOUNT) >= value) {
            IWETH(_WETH).deposit{value: value}();
            TransferHelper.safeTransfer(_WETH, recipient, value);
        } else if (payer == address(this)) {
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }

    function exactInputInternal(uint256 amountIn, address to, CallData memory data) private returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
        bool zeroForOne = tokenIn < tokenOut;
        lastCalledPool = getPool(data.factory, tokenIn, tokenOut, fee);
        (int256 amount0, int256 amount1) = IPoolV3(lastCalledPool).swap(
            to == address(0) ? address(this) : to,
            zeroForOne,
            amountIn.toInt256(),
            (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1),
            abi.encode(data)
        );
        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function exactOutputInternal(uint256 amountOut, address to, CallData memory data) private returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();
        bool zeroForOne = tokenIn < tokenOut;
        lastCalledPool = getPool(data.factory, tokenIn, tokenOut, fee);
        (int256 amount0Delta, int256 amount1Delta) = IPoolV3(lastCalledPool).swap(
            to == address(0) ? address(this) : to,
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0Delta), uint256(-amount1Delta)) : (uint256(amount1Delta), uint256(-amount0Delta));
        require(amountOutReceived == amountOut);
    }

    function getPool(address factory, address tokenA, address tokenB, uint24 fee) public view returns (address pool) {
        if (fee == 0) return getPoolUnknownFee(factory, tokenA, tokenB);
        pool = IFactoryV3(factory).getPool(tokenA, tokenB, fee);
        require(pool != address(0), 'NO POOL');
    }

    function getPoolUnknownFee(address factory, address tokenA, address tokenB) private view returns (address pool) {
        uint256 max = 0;
        uint256 b = 0;
        uint24[] memory fees = new uint24[](5);
        fees[0] = 100; fees[1] = 500; fees[2] = 2500; fees[3] = 3000; fees[4] = 10000;
        for (uint i; i < fees.length; i++) {
            address _pool = IFactoryV3(factory).getPool(tokenA, tokenB, fees[i]);
            if (_pool != address(0)) {
                b = IERC20(tokenA).balanceOf(_pool);
                if (b >= max) { max = b; pool = _pool; }
            }
        }
        require(pool != address(0), 'NO POOL');
    }

    fallback() external payable {
        require(msg.sender == lastCalledPool);
        lastCalledPool = address(0);
        (int256 amount0Delta, int256 amount1Delta, bytes memory databytes) = abi.decode(msg.data[4:], (int256, int256, bytes));
        CallData memory data = abi.decode(databytes, (CallData));
        (address tokenIn, address tokenOut,) = data.path.decodeFirstPool();

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0 ? (tokenIn < tokenOut, uint256(amount0Delta)) : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) pay(tokenIn, data.payer, msg.sender, amountToPay);
        else {
            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                exactOutputInternal(amountToPay, msg.sender, data);
            } else {
                amountInCached = amountToPay;
                tokenIn = tokenOut;
                pay(tokenIn, data.payer, msg.sender, amountToPay);
            }
        }
    }
}

// 科技驴通用路由合约
contract LVRouter is RouterV2, RouterV3 {
    constructor(address WETH_) TokenBus(WETH_, msg.sender) { }

    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                if (result.length < 68) revert();
                assembly { result := add(result, 0x04) }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }
}