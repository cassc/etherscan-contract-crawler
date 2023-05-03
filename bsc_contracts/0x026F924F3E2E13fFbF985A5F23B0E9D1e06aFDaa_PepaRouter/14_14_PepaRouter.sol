// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPancakeFactory} from "../interfaces/IPancakeFactory.sol";
import {IPancakePair} from "../interfaces/IPancakePair.sol";
import {IWETH} from "../interfaces/IWETH.sol";

import {PancakeLibrary} from "../libraries/PancakeLibrary.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";

/**
 * Router to allow adding and removing of liquidity and swapping to PEPA pairs without paying transfer fees.
 * Assumes that this contract has infinite approval for WETH and PEPA from NO_FEE_WALLET.
 */
contract PepaRouter is Ownable, Pausable {
    address public constant NO_FEE_WALLET =
        0x4dcc41E99b56570BC96D4a449E75f5b664245Ba7;
    address public constant PEPA = 0xC3137c696796D69F783CD0Be4aB4bB96814234Aa;
    address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public immutable factory;

    bool public restrictLiquidity = true;
    bool public restrictSwap = true;
    mapping(address => bool) public hasPermissionLiquidity;
    mapping(address => bool) public hasPermissionSwap;

    constructor(address _factory) {
        factory = _factory;
    }

    /** Checks to make sure no token balance of NO_FEE_WALLET changes. */
    modifier noBalanceChange(address token) {
        uint256 balance = IERC20(token).balanceOf(NO_FEE_WALLET);
        _;
        require(
            IERC20(token).balanceOf(NO_FEE_WALLET) == balance,
            "PepeRouter: token balance decreased"
        );
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "PepeRouter: EXPIRED");
        _;
    }

    modifier onlyPermissionLiquidity() {
        require(
            !restrictLiquidity || hasPermissionLiquidity[msg.sender],
            "No access liquidity"
        );
        _;
    }

    modifier onlyPermissionSwap() {
        require(
            !restrictSwap || hasPermissionSwap[msg.sender],
            "No access swap"
        );
        _;
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
    )
        external
        payable
        noBalanceChange(tokenA)
        noBalanceChange(tokenB)
        ensure(deadline)
        onlyPermissionLiquidity
        whenNotPaused
        returns (uint amountA, uint amountB, uint liquidity)
    {
        require(tokenA == PEPA || tokenB == PEPA, "PepeRouter: Pepa only");
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        // route PEPA through NO_FEE_WALLET to avoid tax
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        noBalanceChange(token)
        ensure(deadline)
        onlyPermissionLiquidity
        whenNotPaused
        returns (uint amountToken, uint amountETH, uint liquidity)
    {
        require(token == PEPA, "PepeRouter: Pepa only");
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        // route PEPA through NO_FEE_WALLET to avoid tax
        _safeTransferFromViaFeeless(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPancakePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        public
        virtual
        noBalanceChange(tokenA)
        noBalanceChange(tokenB)
        ensure(deadline)
        onlyPermissionLiquidity
        whenNotPaused
        returns (uint amountA, uint amountB)
    {
        require(tokenA == PEPA, "PepeRouter: Pepa only");
        // route PEPA through NO_FEE_WALLET to avoid tax
        (amountA, amountB) = _removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            NO_FEE_WALLET,
            deadline
        );
        TransferHelper.safeTransferFrom(tokenA, NO_FEE_WALLET, to, amountA);
        TransferHelper.safeTransferFrom(tokenB, NO_FEE_WALLET, to, amountB);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        public
        virtual
        noBalanceChange(token)
        noBalanceChange(WETH)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint amountToken, uint amountETH)
    {
        require(token == PEPA, "PepeRouter: Pepa only");
        // route PEPA through NO_FEE_WALLET to avoid tax
        (amountToken, amountETH) = _removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            NO_FEE_WALLET,
            deadline
        );
        TransferHelper.safeTransferFrom(token, NO_FEE_WALLET, to, amountToken);
        TransferHelper.safeTransferFrom(
            WETH,
            NO_FEE_WALLET,
            address(this),
            amountETH
        );
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        require(
            IPancakeFactory(factory).getPair(tokenA, tokenB) != address(0),
            "Pair does not exist"
        );

        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PancakeLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "PancakeRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PancakeLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "PancakeRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint
    ) internal virtual returns (uint amountA, uint amountB) {
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPancakePair(pair).burn(to);
        (address token0, ) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "PancakeRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "PancakeRouter: INSUFFICIENT_B_AMOUNT");
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** SWAP ****
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        noBalanceChange(PEPA)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint[] memory amounts)
    {
        amounts = PancakeLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        _safeTransferFrom(
            path[0],
            msg.sender,
            PancakeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        noBalanceChange(PEPA)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint[] memory amounts)
    {
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "PancakeRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        _safeTransferFrom(
            path[0],
            msg.sender,
            PancakeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        virtual
        noBalanceChange(PEPA)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "PancakeRouter: INVALID_PATH");
        amounts = PancakeLibrary.getAmountsOut(factory, msg.value, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                PancakeLibrary.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        noBalanceChange(PEPA)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "PancakeRouter: INVALID_PATH");
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "PancakeRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        _safeTransferFrom(
            path[0],
            msg.sender,
            PancakeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        noBalanceChange(PEPA)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "PancakeRouter: INVALID_PATH");
        amounts = PancakeLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            path[0],
            msg.sender,
            PancakeLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        virtual
        noBalanceChange(PEPA)
        ensure(deadline)
        onlyPermissionSwap
        whenNotPaused
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "PancakeRouter: INVALID_PATH");
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= msg.value,
            "PancakeRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                PancakeLibrary.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address to = i < path.length - 2
                ? PancakeLibrary.pairFor(factory, output, path[i + 2])
                : _to;

            if (output == PEPA) {
                // route PEPA through NO_FEE_WALLET
                uint balanceBefore = IERC20(output).balanceOf(NO_FEE_WALLET);
                IPancakePair(PancakeLibrary.pairFor(factory, input, output))
                    .swap(amount0Out, amount1Out, NO_FEE_WALLET, new bytes(0));
                uint swapped = IERC20(output).balanceOf(NO_FEE_WALLET) -
                    balanceBefore;
                TransferHelper.safeTransferFrom(
                    output,
                    NO_FEE_WALLET,
                    to,
                    swapped
                );
            } else {
                IPancakePair(PancakeLibrary.pairFor(factory, input, output))
                    .swap(amount0Out, amount1Out, to, new bytes(0));
            }
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual returns (uint amountB) {
        return PancakeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual returns (uint amountOut) {
        return PancakeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual returns (uint amountIn) {
        return PancakeLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view virtual returns (uint[] memory amounts) {
        return PancakeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view virtual returns (uint[] memory amounts) {
        return PancakeLibrary.getAmountsIn(factory, amountOut, path);
    }

    // ***** OWNER FUNCTIONS *****
    function setPermissionLiquidity(
        address sender,
        bool hasPermission
    ) external onlyOwner {
        hasPermissionLiquidity[sender] = hasPermission;
    }

    function setPermissionSwap(
        address sender,
        bool hasPermission
    ) external onlyOwner {
        hasPermissionSwap[sender] = hasPermission;
    }

    function setRestrictLiquidity(bool restricted) external onlyOwner {
        restrictLiquidity = restricted;
    }

    function setRestrictSwap(bool restricted) external onlyOwner {
        restrictSwap = restricted;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _safeTransferFromViaFeeless(
        address token,
        address from,
        address to,
        uint amount
    ) internal {
        TransferHelper.safeTransferFrom(token, from, NO_FEE_WALLET, amount);
        TransferHelper.safeTransferFrom(token, NO_FEE_WALLET, to, amount);
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint amount
    ) internal {
        if (token == PEPA) {
            // route PEPA through NO_FEE_WALLET to avoid tax
            _safeTransferFromViaFeeless(token, from, to, amount);
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }
}