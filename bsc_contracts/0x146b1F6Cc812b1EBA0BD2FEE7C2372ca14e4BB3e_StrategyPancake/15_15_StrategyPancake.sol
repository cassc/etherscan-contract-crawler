// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "./interfaces/IMasterchef.sol";
import "./interfaces/IStrategyPancake.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyPancake is Ownable, Pausable, IStrategyPancake {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    ///@notice Address LeechRouter's base token.
    address public baseToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    address public USDT = 0x55d398326f99059fF775485246999027B3197955;

    ///@notice The strategy's staking token. - LP
    address public want = 0xEc6557348085Aa57C72514D67070dC863C0a5A8c;

    ///@notice Address of Pancakeswap's Masterchef.
    address public masterchef = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;

    ///@notice Farm reward token.
    address public cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    ///@notice Address of the Uniswap Router
    IUniswapV2Router02 public uniV2Router;

    ///@notice Treasury address.
    address public treasury;

    ///@notice Leech's comission.
    uint256 public protocolFee;

    ///@notice The protocol fee limit is 12%.
    uint256 public constant MAX_FEE = 1200;

    ///@notice Id of the farm pool.
    uint8 public poolId;

    ///@notice Token swap path.
    address[] public pathCakeToUSDT = [cake, USDT];

    address[] public token0ToBase = [USDT, baseToken];

    address[] public token1ToBase = [baseToken];

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() || msg.sender != controller)
            revert("UnauthorizedCaller");
        _;
    }

    constructor(
        address _controller,
        address _router,
        address _uniV2Router,
        uint256 _fee,
        uint8 _poolId
    ) {
        controller = _controller;
        router = _router;
        uniV2Router = IUniswapV2Router02(_uniV2Router);
        protocolFee = _fee;
        poolId = _poolId;
        IERC20(want).safeApprove(masterchef, type(uint256).max);
        IERC20(baseToken).safeApprove(address(uniV2Router), type(uint256).max);
        IERC20(USDT).safeApprove(address(uniV2Router), type(uint256).max);
        IERC20(cake).safeApprove(address(uniV2Router), type(uint256).max);
    }

    /**
     * @notice Re-invests rewards.
     */

    function autocompound() external whenNotPaused {
        IMasterchef(masterchef).deposit(poolId, 0);
        uint256 cakeBal = IERC20(cake).balanceOf(address(this));
        if (cakeBal > 0) {
            uint256 fee = IERC20(cake)
                .balanceOf(address(this))
                .mul(protocolFee)
                .div(10000);
            IERC20(cake).safeTransfer(treasury, fee);
            deposit(pathCakeToUSDT);
            emit Compounded(cakeBal, fee, block.timestamp);
        }
    }

    /**
     * @notice Depositing into the farm pool.
     * @param pathTokenInToToken0 Path to swap the deposited token into the first token og the LP.
     */
    function deposit(
        address[] memory pathTokenInToToken0
    ) public whenNotPaused returns (uint256 wantBal) {
        if (msg.sender != router && msg.sender != controller)
            revert("UnauthorizedCaller");
        uint256 tokenBal = IERC20(pathTokenInToToken0[0]).balanceOf(
            address(this)
        );
        _approveTokenIfNeeded(pathTokenInToToken0[0], address(uniV2Router));
        uniV2Router.swapExactTokensForTokens(
            tokenBal,
            0,
            pathTokenInToToken0,
            address(this),
            block.timestamp
        );
        _swapIn();
        wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            IMasterchef(masterchef).deposit(poolId, wantBal);
        }
        emit Deposited(wantBal);
    }

    /**
     * @notice Withdrawing staking token (LP) from the strategy.
     * @dev Can only be called by LeechRouter.
     * @param _amountLP Amount of the LP token to be withdrawn.
     * @param tokenOutAmount Amount of the token returned to LeechRouter.
     */
    function withdraw(
        uint256 _amountLP,
        address[] memory token0toTokenOut,
        address[] memory token1toTokenOut
    ) public whenNotPaused returns (uint256 tokenOutAmount) {
        if (msg.sender != router) revert("UnauthorizedCaller");
        IMasterchef(masterchef).withdraw(poolId, _amountLP);
        address token0 = IUniswapV2Pair(want).token0();
        address token1 = IUniswapV2Pair(want).token1();
        _swapOut();
        if (token0toTokenOut.length > 1) {
            uniV2Router.swapExactTokensForTokens(
                IERC20(token0).balanceOf(address(this)),
                0,
                token0toTokenOut,
                address(this),
                block.timestamp
            );
        }

        if (token1toTokenOut.length > 1) {
            uniV2Router.swapExactTokensForTokens(
                IERC20(token1).balanceOf(address(this)),
                0,
                token1toTokenOut,
                address(this),
                block.timestamp
            );
        }
        address tokenOut = token0toTokenOut[token0toTokenOut.length - 1];

        tokenOutAmount = IERC20(tokenOut).balanceOf(address(this));
        IERC20(tokenOut).safeTransfer(router, tokenOutAmount);
        emit Withdrawn(_amountLP, tokenOutAmount);
    }

    function withdrawAll() external whenNotPaused {
        uint256 amountAll = IERC20(want).balanceOf(address(this));
        withdraw(amountAll, token0ToBase, token1ToBase);
    }

    /**
     * @notice Pause the contract's activity
     * @dev Only the owner or the controller can pause the contract's activity.
     */
    function pause() external onlyOwnerOrController {
        _pause();
    }

    /**
     * @notice Unpause the contract's activity
     * @dev Only the owner can unpause the contract's activity.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets fee taken by the Leech protocol.
     * @dev Only owner can set the protocol fee.
     * @param _fee Fee value.
     */
    function setFee(uint256 _fee) external onlyOwner {
        if (_fee > MAX_FEE) revert("Wrong Amount");
        protocolFee = _fee;
    }

    /**
     * @notice Sets the tresury address
     * @dev Only owner can set the treasury address
     * @param _treasury The address to be set.
     */
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert("ZeroAddressAsInput");
        treasury = _treasury;
    }

    /**
     * @notice Sets the controller address
     * @dev Only owner can set the controller address
     * @param _controller The address to be set.
     */
    function setController(address _controller) external onlyOwner {
        if (_controller == address(0)) revert("ZeroAddressAsInput");
        controller = _controller;
    }

    /**
     * @notice Allows the owner to withdraw stuck tokens from the contract's balance.
     * @dev Only owner can withdraw tokens.
     * @param _token Address of the token to be withdrawn.
     * @param _amount Amount to be withdrawn.
     */
    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Swaps the input token into the liquidity pair.
     */
    function _swapIn() private {
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(want)
            .getReserves();
        uint256 fullInvestment = IERC20(USDT).balanceOf(address(this));
        uint256 swapAmountIn = _getSwapAmount(
            fullInvestment,
            reserveA,
            reserveB
        );

        uint256[] memory swapedAmounts = uniV2Router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            token0ToBase,
            address(this),
            block.timestamp
        );
        (, , uint256 amountLiquidity) = uniV2Router.addLiquidity(
            token0ToBase[0],
            token0ToBase[1],
            fullInvestment - swapAmountIn,
            swapedAmounts[swapedAmounts.length - 1],
            1,
            1,
            address(this),
            block.timestamp
        );
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

        uint256 nominator = uniV2Router.getAmountOut(
            halfInvestment,
            reserveA,
            reserveB
        );

        uint256 denominator = uniV2Router.quote(
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

    /**
     * @dev Remove liquidity from UniswapV2 Liquidity Pool.
     */
    function _swapOut() private {
        IERC20(want).safeTransfer(want, IERC20(want).balanceOf(address(this)));
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(want).burn(
            address(this)
        );
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
}