// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./interfaces/IWETH.sol";
import "./interfaces/ILeechSwapper.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LeechSwapper is Ownable, ILeechSwapper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**
    @notice The UniV2 router address.
    */
    IUniswapV2Router02 public router;

    /**
    @notice The base token address that is being managed by the contract.
    */
    IWETH public immutable native;

    /**
     * @notice The minimum amount for operations with tokens
     */
    IERC20 public immutable baseToken;

    /**
     * @notice The minimum amount for operations with tokens
     */
    uint256 public constant MIN_AMOUNT = 1000;

    /**
     * @dev Constructor sets the Uniswap V2 Router and native token address, as well as the base token address.
     * @param _router Address of the Uniswap V2 Router
     * @param _native Address of the native token (usually WETH)
     * @param _baseToken Address of the base token
     */
    constructor(address _router, address _native, address _baseToken) {
        // Safety checks to ensure WETH token address
        IWETH(_native).deposit{value: 0}();
        IWETH(_native).withdraw(0);

        router = IUniswapV2Router02(_router);
        native = IWETH(_native);
        baseToken = IERC20(_baseToken);
    }

    /**
     * @notice Swap an amount of tokens for an equivalent amount of another token, according to the provided `path` of token contracts.
     * @param amountIn The amount of tokens being swapped.
     * @param path The array of addresses representing the token contracts involved in the swap.
     * @return swapedAmounts The array of amounts in the respective token after the swap.
     */
    function swap(
        uint256 amountIn,
        address[] calldata path
    ) external payable override returns (uint256[] memory swapedAmounts) {
        if (msg.value < MIN_AMOUNT && amountIn < MIN_AMOUNT)
            revert("Insufficient Amount");

        if (msg.value >= MIN_AMOUNT) {
            native.deposit{value: msg.value}();
            amountIn = msg.value;
        } else {
            if (IERC20(path[0]).allowance(msg.sender, address(this)) < amountIn)
                revert("Insufficient allowance");

            IERC20(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
        }

        _approveTokenIfNeeded(path[0], address(router));
        swapedAmounts = router.swapExactTokensForTokens(
            amountIn,
            MIN_AMOUNT,
            path,
            address(this),
            block.timestamp
        );

        IERC20(path[path.length - 1]).safeTransfer(
            msg.sender,
            swapedAmounts[swapedAmounts.length - 1]
        );
    }

    /**
     * @notice Transfer an amount of the base token to the contract, then swap it for LP token according to the provided `baseToToken0` path.
     * @param amount The amount of base token to transfer.
     * @param lpAddr The address of the liquidity pool to deposit the swapped tokens into.
     * @param baseToToken0 The array of addresses representing the token contracts involved in the swap from the base token to the target token.
     */
    function leechIn(
        uint256 amount,
        address lpAddr,
        address[] calldata baseToToken0
    ) external override {
        if (amount < MIN_AMOUNT) revert("Insufficient Amount");
        if (baseToken.allowance(msg.sender, address(this)) < amount)
            revert("Insufficient allowance");
        if (address(baseToken) != baseToToken0[0]) revert("Wrong Path");

        baseToken.safeTransferFrom(msg.sender, address(this), amount);

        _approveTokenIfNeeded(address(baseToken), address(router));

        if (baseToToken0.length > 1) {
            router.swapExactTokensForTokens(
                amount,
                MIN_AMOUNT,
                baseToToken0,
                address(this),
                block.timestamp
            );
        }

        _swapIn(lpAddr, baseToToken0[baseToToken0.length - 1]);
    }

    /**
     *@notice Swaps out token from the liquidity pool to underlying base token
     *@param amount The amount of the token to be leeched out from liquidity pool.
     *@param lpAddr Address of the liquidity pool.
     *@param token0toBasePath Path of token0 in the liquidity pool to underlying base token.
     *@param token1toBasePath Path of token1 in the liquidity pool to underlying base token.
     */
    function leechOut(
        uint256 amount,
        address lpAddr,
        address[] calldata token0toBasePath,
        address[] calldata token1toBasePath
    ) external override {
        if (amount < MIN_AMOUNT) revert("Insufficient Amount");
        if (IERC20(lpAddr).allowance(msg.sender, address(this)) < amount)
            revert("Insufficient Allowance");

        IERC20(lpAddr).safeTransferFrom(msg.sender, address(this), amount);

        address token0 = IUniswapV2Pair(lpAddr).token0();
        address token1 = IUniswapV2Pair(lpAddr).token1();
        if (token0 != token0toBasePath[0] && token1 != token1toBasePath[0])
            revert("Wrong Path");

        _swapOut(lpAddr);
        _approveTokenIfNeeded(token0toBasePath[0], address(router));
        _approveTokenIfNeeded(token1toBasePath[0], address(router));

        if (token0toBasePath.length > 1) {
            router.swapExactTokensForTokens(
                IERC20(token0).balanceOf(address(this)),
                MIN_AMOUNT,
                token0toBasePath,
                address(this),
                block.timestamp
            );
        }

        if (token1toBasePath.length > 1) {
            router.swapExactTokensForTokens(
                IERC20(token1).balanceOf(address(this)),
                MIN_AMOUNT,
                token1toBasePath,
                address(this),
                block.timestamp
            );
        }

        baseToken.safeTransfer(msg.sender, baseToken.balanceOf(address(this)));
    }

    /**
     *@notice Transfers all the tokens of the specified ERC-20 token from the contract's balance to the caller's balance.
     *Only the contract owner can perform this action.
     *@param _token The address of the ERC-20 token to transfer from the contract's balance.
     *@dev This function is used to safely transfer all of the specified ERC-20 token from the contract's balance to the caller's balance.
     */
    function escapeERC20(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /**
     * @notice Self-destruct function in case of contract updating or bugs with the router
     * @param _to address for withdrawing eth
     */
    function destroy(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
        selfdestruct(_to);
    }

    /**
     * @notice setRouter sets the UniswapV2Router contract that the contract interacts with
     * @param _router The address of the UniswapV2Router contract
     */
    function setRouter(address _router) external onlyOwner {
        if (_router == address(0)) revert("Wrong argument");

        router = IUniswapV2Router02(_router);
    }

    /**
     * @dev Swaps the input token into the liquidity pair.
     * @param lpAddr Address of the liquidity pair contract.
     * @param token0 Address of the token0 in the liquidity pair.
     */
    function _swapIn(address lpAddr, address token0) private {
        IUniswapV2Pair pair = IUniswapV2Pair(lpAddr);
        if (token0 != pair.token0()) revert("WrongPath");

        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();

        if (reserveA < MIN_AMOUNT && reserveB < MIN_AMOUNT)
            revert("Low Reserves");

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = pair.token1();

        uint256 fullInvestment = IERC20(token0).balanceOf(address(this));
        uint256 swapAmountIn = _getSwapAmount(
            fullInvestment,
            reserveA,
            reserveB
        );

        _approveTokenIfNeeded(path[0], address(router));
        uint256[] memory swapedAmounts = router.swapExactTokensForTokens(
            swapAmountIn,
            MIN_AMOUNT,
            path,
            address(this),
            block.timestamp
        );

        _approveTokenIfNeeded(path[1], address(router));
        (, , uint256 amountLiquidity) = router.addLiquidity(
            path[0],
            path[1],
            fullInvestment - swapedAmounts[0],
            swapedAmounts[1],
            1,
            1,
            address(this),
            block.timestamp
        );

        IERC20(lpAddr).safeTransfer(msg.sender, amountLiquidity);
    }

    /**
     * @dev Remove liquidity from UniswapV2 Liquidity Pool.
     * @param lpAddr Address of the Liquidity Pool to remove from.
     */
    function _swapOut(address lpAddr) private {
        IERC20(lpAddr).safeTransfer(
            lpAddr,
            IERC20(lpAddr).balanceOf(address(this))
        );
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(lpAddr).burn(
            address(this)
        );

        if (amount0 < MIN_AMOUNT) revert("Insufficient Amount A");
        if (amount1 < MIN_AMOUNT) revert("Insufficient AmountB");
    }

    /**
     *@dev Approves spender to spend tokens on behalf of the contract.
     *If the contract doesn't have enough allowance, this function approves spender.
     *@param token The address of the token to be approved
     *@param spender The address of the spender to be approved
     */
    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    /**
     * @dev Computes the swap amount for the given input.
     * @param investmentA The investment amount for token A.
     * @param reserveA The reserve of token A in the liquidity pool.
     * @param reserveB The reserve of token B in the liquidity pool.
     * @return swapAmount The computed swap amount.
     */
    function _getSwapAmount(
        uint256 investmentA,
        uint256 reserveA,
        uint256 reserveB
    ) private view returns (uint256 swapAmount) {
        uint256 halfInvestment = investmentA / 2;

        uint256 nominator = router.getAmountOut(
            halfInvestment,
            reserveA,
            reserveB
        );

        uint256 denominator = router.quote(
            halfInvestment,
            reserveA.add(halfInvestment),
            reserveB.sub(nominator)
        );
        swapAmount = investmentA.sub(
            Babylonian.sqrt(
                (halfInvestment * halfInvestment * nominator) / denominator
            )
        );
    }
}