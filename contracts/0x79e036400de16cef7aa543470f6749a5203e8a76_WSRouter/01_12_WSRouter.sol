// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import './interfaces/IWSFactory.sol';
import './libraries/TransferHelper.sol';

import './libraries/WSLibrary.sol';
import './interfaces/IWSRouter.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWSERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IWSImplementation.sol';
import './interfaces/IActivity.sol';

contract WSRouter is IWSRouter, IWSImplementation {
    using SafeMath for uint;

    bool private initialized;
    address public override factory;
    address public override WETH;
    address private _owner;
    bool public isActivityEnabled;
    address public WBT;
    address public USDT;
    address public activity;
    address public balancer;

    uint public amountMin;
    uint public amountMinAverage;
    uint public amountMiddle;
    uint public amountMaxAverage;
    uint public amountMax;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'WSRouter: EXPIRED');
        _;
    }

    function initialize(
        address _factory,
        address _WETH
    ) public returns(bool) {
        require(initialized == false, "WSRouter: Alredy initialized.");
        factory = _factory;
        WETH = _WETH;
        _transferOwnership(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
        initialized = true;
        return true;
    }

    receive() external payable {
    }

    function setStateActivity(bool stateActivity) external onlyOwner  {
        isActivityEnabled = stateActivity;
    }

    function changeActivity(
        address _activity,
        address _WBT,
        address _USDT,
        address _balancer,
        uint _amountMin,
        uint _amountMinAverage,
        uint _amountMiddle,
        uint _amountMaxAverage,
        uint _amountMax        
    ) external onlyOwner  {
        activity = _activity;
        amountMin = _amountMin;
        amountMinAverage = _amountMinAverage;
        amountMiddle = _amountMiddle;
        amountMaxAverage = _amountMaxAverage;
        amountMax = _amountMax;
        WBT = _WBT;
        USDT = _USDT;
        activity = _activity;
        balancer = _balancer;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IWSFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IWSFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = WSLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = WSLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'WSRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = WSLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'WSRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity  (tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = WSLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IWSPair(pair).mint(to);
    }
    function addLiquidityNative(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountNative, uint liquidity) {
        (amountToken, amountNative) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountNativeMin
        );
        address pair = WSLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountNative}();
        assert(IWETH(WETH).transfer(pair, amountNative));
        liquidity = IWSPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountNative) TransferHelper.safeTransferETH(msg.sender, msg.value - amountNative);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = WSLibrary.pairFor(factory, tokenA, tokenB);
        IWSERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IWSPair(pair).burn(to);
        (address token0,) = WSLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'WSRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'WSRouter: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityNative(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amounNativeMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountNative) {
        (amountToken, amountNative) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amounNativeMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountNative);
        TransferHelper.safeTransferETH(to, amountNative);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = WSLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IWSERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityNativeWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amounNativeMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountNative) {
        address pair = WSLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IWSERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountNative) = removeLiquidityNative(token, liquidity, amountTokenMin, amounNativeMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityNativeSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amounNativeMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountNative) {

        (, amountNative) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amounNativeMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountNative);
        TransferHelper.safeTransferETH(to, amountNative);
    }

    function removeLiquidityNativeWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amounNativeMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountNative) {
        address pair = WSLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IWSERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountNative = removeLiquidityNativeSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amounNativeMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {

        if (
            (isActivityEnabled &&
            path.length == 2 &&
            balancer != msg.sender &&
            path[0] == USDT &&
            path[1] == WBT) &&
            (amounts[0] == amountMin ||
            amounts[0] == amountMinAverage ||
            amounts[0] == amountMiddle ||
            amounts[0] == amountMaxAverage ||
            amounts[0] == amountMax)
        ) {
            IActivity(activity).addActivityMember(msg.sender, amounts[0]);
        }

        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = WSLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? WSLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IWSPair(WSLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = WSLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = WSLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'WSRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactNativeForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'WSRouter: INVALID_PATH');
        amounts = WSLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactNative(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'WSRouter: INVALID_PATH');
        amounts = WSLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'WSRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForNative(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'WSRouter: INVALID_PATH');
        amounts = WSLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapNativeForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'WSRouter: INVALID_PATH');
        amounts = WSLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'WSRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(WSLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = WSLibrary.sortTokens(input, output);
            IWSPair pair = IWSPair(WSLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);

                if (
                    (isActivityEnabled &&
                    msg.sender != balancer &&
                    path.length == 2 &&
                    path[0] == USDT &&
                    path[1] == WBT) &&
                    (amountInput == amountMin ||
                    amountInput == amountMinAverage ||
                    amountInput == amountMiddle ||
                    amountInput == amountMaxAverage ||
                    amountInput == amountMax)
                ) {
                    IActivity(activity).addActivityMember(msg.sender, amountInput);
                }

                amountOutput = WSLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? WSLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);

    

        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactNativeForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    {
        require(path[0] == WETH, 'WSRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(WSLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForNativeSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'WSRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WSLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'WSRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return WSLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    public
    pure
    virtual
    override
    returns (uint amountOut)
    {
        return WSLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    public
    pure
    virtual
    override
    returns (uint amountIn)
    {
        return WSLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return WSLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return WSLibrary.getAmountsIn(factory, amountOut, path);
    }

    function getImplementationType() external pure override returns(uint256) {
        /// 3 is a router type
        return 3;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    // Let contract be functional for proxy contract initialization
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}