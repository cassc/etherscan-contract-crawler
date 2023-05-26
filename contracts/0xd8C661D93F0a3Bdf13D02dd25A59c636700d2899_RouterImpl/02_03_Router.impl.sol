// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "./Router.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library IXswapLibrary {
    using SafeMath for uint256;

    function sortTokens(address factory, address tokenA, address tokenB) internal view returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        address pool = pairFor(factory, tokenA, tokenB);
        require(pool != address(0));
        (token0, token1) = (tokenA == IExchange(pool).token0()) ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IFactory(factory).tokenToPool(tokenA, tokenB);
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        address pool = pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IExchange(pool).getReserves();
        (reserveA, reserveB) = tokenA == IExchange(pool).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');

        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            amounts[i + 1] = estimatePos(factory, path[i], amounts[i], path[i + 1]);
        }
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = estimateNeg(factory, path[i - 1], path[i], amounts[i]);
        }
    }

    function estimatePos(address factory, address inToken, uint inAmount, address outToken) private view returns (uint) {
        address exc = pairFor(factory, inToken, outToken);
        require(exc != address(0));

        uint outAmount = IExchange(exc).estimatePos(inToken, inAmount);
        require(outAmount != 0);

        return outAmount;
    }

    function estimateNeg(address factory, address inToken, address outToken, uint outAmount) private view returns (uint) {
        address exc = pairFor(factory, inToken, outToken);
        require(exc != address(0));

        uint inAmount = IExchange(exc).estimateNeg(outToken, outAmount);
        require(inAmount != uint(-1));

        return inAmount;
    }
}

interface IFactory {
    function owner() external view returns (address);
    function tokenToPool(address token0, address token1) external view returns (address);
    function poolExist(address) external view returns (bool);
    function emergencyPaused() external view returns (bool);
}

interface IExchange {
    function estimatePos(address token, uint amount) external view returns (uint);
    function estimateNeg(address token, uint amount) external view returns (uint);
    function getCurrentPool() external view returns (uint, uint);
    function exchangePos(address token, uint amount) external returns (uint);
    function exchangeNeg(address token, uint amount) external returns (uint);

    function addTokenLiquidityWithLimit(uint amount0, uint amount1, uint minAmount0, uint minAmount1, address user) external returns (uint real0, uint real1, uint amountLP);
    function removeLiquidityWithLimit(uint amount, uint minAmount0, uint minAmount1, address user) external returns (uint, uint);
    function removeLiquidityWithLimitETH(uint amount, uint minAmount0, uint minAmount1, address user) external returns (uint, uint);
    function claimReward(address user) external;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}


contract RouterImpl is Router {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor() public Router(address(0), address(0), address(0)) { }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    modifier notPaused {
        require(!IFactory(factory).emergencyPaused(), "IXswapIXswapRouter: Emergency Paused");
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'IXswapIXswapRouter: EXPIRED');
        _;
    }

    function version() public pure returns (string memory) {
        return "IXswapRouter20220901";
    }

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);
    event SetTrustedForwarder(address forwarder);

    function changeNextOwner(address _nextOwner) public {
        require(msg.sender == owner);
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);
        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function setTrustedForwarder(address forwarder) public {
        require(msg.sender == owner);

        _setTrustedForwarder(forwarder);

        emit SetTrustedForwarder(forwarder);
    }

    function approvePair(address pair, address token0, address token1) public {
        require(msg.sender == factory);
        IERC20(token0).approve(pair, uint(-1));
        IERC20(token1).approve(pair, uint(-1));
    }


    function () payable external {
        assert(_msgSender() == WETH); // only accept ETH via fallback from the WETH contract
    }

    //////////////////////////// Internal functions for swap ////////////////////////////
    event ExchangePos(address wallet, address token0, uint amount0, address token1, uint amount1);
    event ExchangeNeg(address wallet, address token0, uint amount0, address token1, uint amount1);

    function stepPos(address inToken, uint inAmount, address outToken, uint outAmount) private {
        address exc = IXswapLibrary.pairFor(factory, inToken, outToken);

        uint result = IExchange(exc).exchangePos(inToken, inAmount);

        require(result == outAmount, "IXswapRouter: result != outAmount");
    }

    function stepNeg(address inToken, uint inAmount, address outToken, uint outAmount) private {
        address exc = IXswapLibrary.pairFor(factory, inToken, outToken);

        uint result = IExchange(exc).exchangeNeg(outToken, outAmount);
        require(result == inAmount, "IXswapRouter: result != inAmount");
    }

    function _swapPos(uint[] memory amounts, address[] memory path) private nonReentrant {
        uint n = path.length;

        for (uint i = 0; i < n - 1; i++) {
            stepPos(path[i], amounts[i], path[i + 1], amounts[i + 1]);
        }

        emit ExchangePos(_msgSender(), path[0], amounts[0], path[n - 1], amounts[n - 1]);
    }

    function _swapNeg(uint[] memory amounts, address[] memory path) private nonReentrant {
        uint n = path.length;

        for (uint i = 0; i < n - 1; i++) {
            stepNeg(path[i], amounts[i], path[i + 1], amounts[i + 1]);
        }

        emit ExchangeNeg(_msgSender(), path[0], amounts[0], path[n - 1], amounts[n - 1]);
    }

    function sendTokenToExchange(address token, uint amount) public {
        require(IFactory(factory).poolExist(_msgSender()));

        uint userBefore = IERC20(token).balanceOf(_msgSender());
        uint thisBefore = IERC20(token).balanceOf(address(this));

        require(IERC20(token).transfer(_msgSender(), amount), "transfer failed");

        uint userAfter = IERC20(token).balanceOf(_msgSender());
        uint thisAfter = IERC20(token).balanceOf(address(this));

        require(userAfter == userBefore.add(amount), "IXswapRouter: userBalance diff");
        require(thisAfter.add(amount) == thisBefore, "IXswapRouter: thisBalance diff");
    }

    //////////////////////////// Swap ////////////////////////////

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) notPaused returns (uint[] memory amounts) {
        uint length = path.length;
        amounts = IXswapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[length - 1] >= amountOutMin, 'IXswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amounts[0]);
        _swapPos(amounts, path);
        IERC20(path[length - 1]).safeTransfer(to, amounts[length - 1]);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] memory path,
        address to,
        uint deadline
    ) public ensure(deadline) notPaused returns (uint[] memory amounts) {
        uint length = path.length;
        amounts = IXswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'IXswapRouter: EXCESSIVE_INPUT_AMOUNT');
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amounts[0]);
        _swapNeg(amounts, path);
        IERC20(path[length - 1]).safeTransfer(to, amounts[length - 1]);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        ensure(deadline)
        notPaused
        returns (uint[] memory amounts)
    {
        uint length = path.length;
        require(path[0] == WETH, 'IXswapRouter: INVALID_PATH');
        amounts = IXswapLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[length - 1] >= amountOutMin, 'IXswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit.value(amounts[0])();
        _swapPos(amounts, path);
        IERC20(path[length - 1]).safeTransfer(to, amounts[length - 1]);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] memory path, address to, uint deadline)
        public
        ensure(deadline)
        notPaused
        returns (uint[] memory amounts)
    {
        uint length = path.length;
        require(path[length - 1] == WETH, 'IXswapRouter: INVALID_PATH');
        amounts = IXswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'IXswapRouter: EXCESSIVE_INPUT_AMOUNT');
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amounts[0]);
        _swapNeg(amounts, path);
        IWETH(WETH).withdraw(amounts[length - 1]);
        (bool success, ) = to.call.value(amounts[length - 1])("");
        require(success, 'IXswapRouter: ETH transfer failed');
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] memory path, address to, uint deadline)
        public
        ensure(deadline)
        notPaused
        returns (uint[] memory amounts)
    {
        uint length = path.length;
        require(path[length - 1] == WETH, 'IXswapRouter: INVALID_PATH');
        amounts = IXswapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[length - 1] >= amountOutMin, 'IXswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amounts[0]);
        _swapPos(amounts, path);
        IWETH(WETH).withdraw(amounts[length - 1]);
        (bool success, ) = to.call.value(amounts[length - 1])("");
        require(success, 'IXswapRouter: ETH transfer failed');
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        ensure(deadline)
        notPaused
        returns (uint[] memory amounts)
    {
        uint length = path.length;
        uint amountETH = msg.value;
        require(path[0] == WETH, 'IXswapRouter: INVALID_PATH');
        amounts = IXswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountETH, 'IXswapRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit.value(amounts[0])();
        _swapNeg(amounts, path);
        IERC20(path[length - 1]).safeTransfer(to, amounts[length - 1]);
        if (amountETH > amounts[0]) {
            (bool success, ) = _msgSender().call.value(amountETH.sub(amounts[0]))("");
            require(success, 'IXswapRouter: ETH transfer failed');
        }
    }

    //////////////////////////// Permit Swap ////////////////////////////
    function swapExactTokensForTokensWithPermit(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external ensure(deadline) notPaused returns (uint[] memory amounts) {
        uint value = approveMax ? uint(-1) : amountIn;
        IERC20(path[0]).permit(_msgSender(), address(this), value, deadline, v, r, s);

        return swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    function swapTokensForExactTokensWithPermit(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external ensure(deadline) notPaused returns (uint[] memory amounts) {
        uint value = approveMax ? uint(-1) : amountInMax;
        IERC20(path[0]).permit(_msgSender(), address(this), value, deadline, v, r, s);

        return swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    function swapTokensForExactETHWithPermit(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external ensure(deadline) notPaused returns (uint[] memory amounts) {
        uint value = approveMax ? uint(-1) : amountInMax;
        IERC20(path[0]).permit(_msgSender(), address(this), value, deadline, v, r, s);

        return swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    function swapExactTokensForETHWithPermit(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external ensure(deadline) notPaused returns (uint[] memory amounts) {
        uint value = approveMax ? uint(-1) : amountIn;
        IERC20(path[0]).permit(_msgSender(), address(this), value, deadline, v, r, s);

        return swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }

    //////////////////////////// LIQUIDITY ////////////////////////////

    event AddLiquidity(address user, address pool, address token0, uint amount0, address token1, uint amount1, uint liquidity);
    event RemoveLiquidity(address user, address pool, address token0, uint amount0, address token1, uint amount1, uint liquidity);

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address token0,
        address token1,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) notPaused nonReentrant returns (uint amount0, uint amount1, uint liquidity) {
        SafeERC20.safeTransferFrom(IERC20(token0), _msgSender(), address(this), amountADesired);
        SafeERC20.safeTransferFrom(IERC20(token1), _msgSender(), address(this), amountBDesired);

        (amount0, amount1, liquidity) = IExchange(IXswapLibrary.pairFor(factory, token0, token1)).addTokenLiquidityWithLimit(amountADesired, amountBDesired, amountAMin, amountBMin, to);
        if (amount0 < amountADesired) IERC20(token0).safeTransfer(_msgSender(), amountADesired.sub(amount0));
        if (amount1 < amountBDesired) IERC20(token1).safeTransfer(_msgSender(), amountBDesired.sub(amount1));

        emit AddLiquidity(to, IXswapLibrary.pairFor(factory, token0, token1), token0, amount0, token1, amount1, liquidity);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) notPaused nonReentrant returns (uint amountToken, uint amountETH, uint liquidity) {
        address pair = IFactory(factory).tokenToPool(WETH, token);
        IWETH(WETH).deposit.value(msg.value)();
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amountTokenDesired);
        (amountETH, amountToken, liquidity) = IExchange(pair).addTokenLiquidityWithLimit(msg.value, amountTokenDesired, amountETHMin, amountTokenMin, to);
        if (amountETH < msg.value) {
            IWETH(WETH).withdraw(msg.value.sub(amountETH));

            (bool success, ) = _msgSender().call.value(msg.value.sub(amountETH))("");
            require(success, 'IXswapRouter: ETH transfer failed');
        }
        if (amountToken < amountTokenDesired) IERC20(token).safeTransfer(_msgSender(), amountTokenDesired.sub(amountToken));

        emit AddLiquidity(to, pair, WETH, amountETH, token, amountToken, liquidity);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address token0,
        address token1,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) notPaused nonReentrant returns (uint amount0, uint amount1) {
        address pair = IFactory(factory).tokenToPool(token0, token1);
        IERC20(pair).safeTransferFrom(_msgSender(), address(this), liquidity);
        (amount0, amount1) = IExchange(pair).removeLiquidityWithLimit(liquidity, amountAMin, amountBMin, to);

        emit RemoveLiquidity(to, pair, token0, amount0, token1, amount1, liquidity);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) notPaused nonReentrant returns (uint amountToken, uint amountETH) {
        address pair = IFactory(factory).tokenToPool(WETH, token);
        IERC20(pair).safeTransferFrom(_msgSender(), address(this), liquidity);
        (amountETH, amountToken) = IExchange(pair).removeLiquidityWithLimit(liquidity, amountETHMin, amountTokenMin, address(this));
        IERC20(token).safeTransfer(to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        {
            (bool success, ) = to.call.value(amountETH)("");
            require(success, 'IXswapRouter: ETH transfer failed');
        }
        emit RemoveLiquidity(to, pair, WETH, amountETH, token, amountToken, liquidity);
    }

    function removeLiquidityWithPermit(
        address token0,
        address token1,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amount0, uint amount1) {
        address pair = IFactory(factory).tokenToPool(token0, token1);
        uint value = approveMax ? uint(-1) : liquidity;
        IExchange(pair).permit(_msgSender(), address(this), value, deadline, v, r, s);
        (amount0, amount1) = removeLiquidity(token0, token1, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        address pair = IFactory(factory).tokenToPool(WETH, token);
        uint value = approveMax ? uint(-1) : liquidity;
        IExchange(pair).permit(_msgSender(), address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    function claimReward(address pair, uint deadline) external ensure(deadline) notPaused nonReentrant {
        require(IFactory(factory).poolExist(pair));
        IExchange(pair).claimReward(_msgSender());
    }

    function claimReward(address token0, address token1, uint deadline) external ensure(deadline) notPaused nonReentrant {
        address pair = IFactory(factory).tokenToPool(token0, token1);
        IExchange(pair).claimReward(_msgSender());
    }

    function claimRewardList(address[] calldata pairs, uint deadline) external ensure(deadline) notPaused nonReentrant {
        uint length = pairs.length;
        for (uint i = 0; i < length; i++) {
            require(IFactory(factory).poolExist(pairs[i]));
            IExchange(pairs[i]).claimReward(_msgSender());
        }
    }

    function quote(uint amount0, uint reserveA, uint reserveB) public pure returns (uint amount1) {
        return IXswapLibrary.quote(amount0, reserveA, reserveB);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        return IXswapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        return IXswapLibrary.getAmountsIn(factory, amountOut, path);
    }
}