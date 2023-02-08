// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import "./interfaces/IShibnobiRouter02.sol";
import "./interfaces/IShibnobiFactory.sol";
import "./libraries/ShibnobiLibrary.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";

contract ShibnobiRouter is IShibnobiRouter02 {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override WETH;
    mapping (address => uint256) _claims;

    address public feeSetter;
    uint16 public fees = 9975;
    uint16 public feeDenominator = 10000;

    modifier onlyFeeSetter() {
        require(msg.sender == feeSetter, "ShibnobiRouter: FORBIDDEN");
        _;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "ShibnobiRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        feeSetter = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function setFeeSetter(address _feeSetter) external onlyFeeSetter {
        feeSetter = _feeSetter;
    }

    function setFees(uint16 _fees) external onlyFeeSetter {
        require(fees <= feeDenominator, "ShibnobiRouter: INVALID_FEES");
        fees = _fees;
    }

    function handleReferral(uint256 amount, address referral) internal returns(uint256 amountWithFees) {
        amountWithFees = amount.mul(fees) / feeDenominator;
        uint256 feeAmount = amount.sub(amountWithFees);
        if (referral == address(0) || referral == tx.origin) {
            _claims[feeSetter] = _claims[feeSetter].add(feeAmount);
        } else {
            _claims[referral] = _claims[referral].add(feeAmount);
        }
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IShibnobiFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IShibnobiFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = ShibnobiLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = ShibnobiLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "ShibnobiRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = ShibnobiLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "ShibnobiRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ShibnobiLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IShibnobiPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ShibnobiLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IShibnobiPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = ShibnobiLibrary.pairFor(factory, tokenA, tokenB);
        IShibnobiPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IShibnobiPair(pair).burn(to);
        (address token0, ) = ShibnobiLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "ShibnobiRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "ShibnobiRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = ShibnobiLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IShibnobiPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = ShibnobiLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IShibnobiPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH) {
        address pair = ShibnobiLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IShibnobiPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to,
        bool feesOn
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = ShibnobiLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? ShibnobiLibrary.pairFor(factory, output, path[i + 2]) : _to;
            if (feesOn) IShibnobiPair(ShibnobiLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
            else IShibnobiPair(ShibnobiLibrary.pairFor(factory, input, output)).swapNoInternalFees(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
        ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = ShibnobiLibrary.getAmountsOut(factory, amountIn, path, fees);
        require(amounts[amounts.length - 1] >= amountOutMin, "ShibnobiRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            ShibnobiLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to, true);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = ShibnobiLibrary.getAmountsIn(factory, amountOut, path, fees);
        require(amounts[0] <= amountInMax, "ShibnobiRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            ShibnobiLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to, true);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address referral
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "ShibnobiRouter: INVALID_PATH");
        uint256 amountInWithFee = handleReferral(msg.value, referral);

        amounts = ShibnobiLibrary.getAmountsOut(factory, amountInWithFee, path, 10000);
        require(amounts[amounts.length - 1] >= amountOutMin, "ShibnobiRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(ShibnobiLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, false);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        address referral
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "ShibnobiRouter: INVALID_PATH");
        amounts = ShibnobiLibrary.getAmountsIn(factory, amountOut, path, 10000);
        require(amounts[0] <= amountInMax, "ShibnobiRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            ShibnobiLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this), false);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        uint256 amountsOutWithFees = handleReferral(amounts[amounts.length - 1], referral);
        TransferHelper.safeTransferETH(to, amountsOutWithFees);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address referral
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "ShibnobiRouter: INVALID_PATH");
        amounts = ShibnobiLibrary.getAmountsOut(factory, amountIn, path, 10000);
        require(amounts[amounts.length - 1] >= amountOutMin, "ShibnobiRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            ShibnobiLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this), false);
        
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        uint256 amountsOutWithFees = handleReferral(amounts[amounts.length - 1], referral);
        TransferHelper.safeTransferETH(to, amountsOutWithFees);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        address referral
    ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "ShibnobiRouter: INVALID_PATH");
        amounts = ShibnobiLibrary.getAmountsIn(factory, amountOut, path, 10000);
        uint256 amountInWithFee = handleReferral(amounts[0], referral);
        require(amountInWithFee <= msg.value, "ShibnobiRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amountInWithFee}();

        assert(IWETH(WETH).transfer(ShibnobiLibrary.pairFor(factory, path[0], path[1]), amountInWithFee));
        _swap(amounts, path, to, false);
        // refund dust eth, if any
        if (msg.value > amountInWithFee) TransferHelper.safeTransferETH(msg.sender, msg.value - amountInWithFee);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to, uint16 fees_) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = ShibnobiLibrary.sortTokens(input, output);
            IShibnobiPair pair = IShibnobiPair(ShibnobiLibrary.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = ShibnobiLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, fees_);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? ShibnobiLibrary.pairFor(factory, output, path[i + 2]) : _to;
            if (fees_ == feeDenominator) pair.swapNoInternalFees(amount0Out, amount1Out, to, new bytes(0));
            else pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            ShibnobiLibrary.pairFor(factory, path[0], path[1]),
            amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, fees);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            "ShibnobiRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address referral
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WETH, "ShibnobiRouter: INVALID_PATH");
        uint256 amountIn = msg.value;
        uint256 amountInWithFee = handleReferral(amountIn, referral);
        IWETH(WETH).deposit{value: amountInWithFee}();
        assert(IWETH(WETH).transfer(ShibnobiLibrary.pairFor(factory, path[0], path[1]), amountInWithFee));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, 10000);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            "ShibnobiRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address referral
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, "ShibnobiRouter: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            ShibnobiLibrary.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), 10000);
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "ShibnobiRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).withdraw(amountOut);
        uint256 amountOutWithFee = handleReferral(amountOut, referral);
        TransferHelper.safeTransferETH(to, amountOutWithFee);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return ShibnobiLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint16 fees_
    ) public pure virtual override returns (uint256 amountOut) {
        return ShibnobiLibrary.getAmountOut(amountIn, reserveIn, reserveOut, fees_);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint16 fees_
    ) public pure virtual override returns (uint256 amountIn) {
        return ShibnobiLibrary.getAmountIn(amountOut, reserveIn, reserveOut, fees_);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path, uint16 fees_)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ShibnobiLibrary.getAmountsOut(factory, amountIn, path, fees_);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path, uint16 fees_)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ShibnobiLibrary.getAmountsIn(factory, amountOut, path, fees_);
    }

    function getClaims(address user) external override view returns (uint256) {
        return _claims[user];
    }

    function claim() override external {
        uint256 amount = _claims[msg.sender];
        require(amount > 0, "Nothing to claim");
        _claims[msg.sender] = 0;
        TransferHelper.safeTransferETH(msg.sender, amount);
    }
}