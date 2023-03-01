// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "./interfaces/IMasterchefBiswap.sol";
import "./interfaces/IStrategyMasterchefFarm.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyBiswapFarm is Ownable, Pausable, IStrategyMasterchefFarm {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct BaseParams{
        address token0;
        address token1;
        address masterchef;
        address want;
        address rewardToken;
        IUniswapV2Router02 uniV2Router;
        uint8 poolId;
    }

    BaseParams baseParams;

    ///@notice Address of Leech's backend.
    address public controller;

    ///@notice Address of LeechRouter.
    address public router;

    ///@notice Address of the LP's token0.
    address public token0;

    ///@notice Treasury address.
    address public treasury;

    ///@notice Leech's comission.
    uint256 public protocolFee;

    ///@notice The protocol fee limit is 12%.
    uint256 public constant MAX_FEE = 1200;

    ///@notice Token swap path.
    address[] public pathRewardToToken0;

    address[] public token0ToToken1;

    address[] public token0ToBase;

    address[] public token1ToBase;

    modifier onlyOwnerOrController() {
        if (msg.sender != owner() || msg.sender != controller)
            revert("UnauthorizedCaller");
        _;
    }

    constructor(
        address _controller,
        address _router,
        address _treasury,
        BaseParams memory _baseParams,
        address[] memory _pathRewardToToken0,
        address[] memory _token0ToToken1,
        address[] memory _token0ToBase,
        address[] memory _token1ToBase,
        uint256 _fee
    ) {
        controller = _controller;
        router = _router;
        treasury = _treasury;
        baseParams = _baseParams;
        pathRewardToToken0 = _pathRewardToToken0;
        token0ToToken1 = _token0ToToken1;
        token0ToBase = _token0ToBase;
        token1ToBase = _token1ToBase;
        protocolFee = _fee;
        IERC20(baseParams.want).safeApprove(baseParams.masterchef, type(uint256).max);
        IERC20(baseParams.token1).safeApprove(address(baseParams.uniV2Router), type(uint256).max);
        IERC20(baseParams.token0).safeApprove(address(baseParams.uniV2Router), type(uint256).max);
        IERC20(baseParams.rewardToken).safeApprove(address(baseParams.uniV2Router), type(uint256).max);
    }

    /**
     * @notice Re-invests rewards.
     */

    function autocompound() external whenNotPaused {
        IMasterchefBiswap(baseParams.masterchef).deposit(baseParams.poolId, 0);
        uint256 rewardBal = IERC20(baseParams.rewardToken).balanceOf(address(this));
        if (rewardBal > 0) {
            uint256 fee = IERC20(baseParams.rewardToken)
                .balanceOf(address(this))
                .mul(protocolFee)
                .div(10000);
            IERC20(baseParams.rewardToken).safeTransfer(treasury, fee);
            deposit(pathRewardToToken0);
            emit Compounded(rewardBal, fee, block.timestamp);
        } else {
            revert ("No reward");
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
        _approveTokenIfNeeded(pathTokenInToToken0[0], address(baseParams.uniV2Router));

        if (pathTokenInToToken0.length > 1) {
            baseParams.uniV2Router.swapExactTokensForTokens(
                tokenBal,
                0,
                pathTokenInToToken0,
                address(this),
                block.timestamp
        );
        }
        
        _swapIn();
        wantBal = IERC20(baseParams.want).balanceOf(address(this));
        if (wantBal > 0) {
            IMasterchefBiswap(baseParams.masterchef).deposit(baseParams.poolId, wantBal);
        }
        emit Deposited(wantBal);
    }

    /**
     * @notice Withdrawing staking token (LP) from the strategy.
     * @dev Can only be called by LeechRouter.
     * @param _amountLP Amount of the LP token to be withdrawn.
     * @return tokenOutAmount Amount of the token returned to LeechRouter.
     */
    function withdraw(
        uint256 _amountLP,
        address[] memory token0toTokenOut,
        address[] memory token1toTokenOut
    ) public returns (uint256 tokenOutAmount) {
        if (msg.sender != router) revert("UnauthorizedCaller");
        if (_amountLP > 0) IMasterchefBiswap(baseParams.masterchef).withdraw(baseParams.poolId, _amountLP);

        address pairToken0 = IUniswapV2Pair(baseParams.want).token0();
        address pairToken1 = IUniswapV2Pair(baseParams.want).token1();
        _swapOut();
        if (token0toTokenOut.length > 1) {
            baseParams.uniV2Router.swapExactTokensForTokens(
                IERC20(pairToken0).balanceOf(address(this)),
                0,
                token0toTokenOut,
                address(this),
                block.timestamp
            );
        }

        if (token1toTokenOut.length > 1) {
            baseParams.uniV2Router.swapExactTokensForTokens(
                IERC20(pairToken1).balanceOf(address(this)),
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

    function withdrawAll() external {
        (uint256 amountAll,) = IMasterchefBiswap(baseParams.masterchef).userInfo(baseParams.poolId, address(this));

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

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyOwner {
        _pause();
        IMasterchefBiswap(baseParams.masterchef).emergencyWithdraw(baseParams.poolId);
    }

    /**
     * @notice Amount of LPs staked into Masterchef
     */
    function balance() public view returns (uint256 amountWant){
       (amountWant,) = IMasterchefBiswap(baseParams.masterchef).userInfo(baseParams.poolId, address(this));
    }

    /**
     * @notice Amount of pending rewards
     */
    function claimable() public view returns (uint256 pendingReward){
        pendingReward = IMasterchefBiswap(baseParams.masterchef).pendingBSW(baseParams.poolId, address(this));
    }

    /**
     * @dev Swaps the input token into the liquidity pair.
     */
    function _swapIn() private {
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(baseParams.want)
            .getReserves();
        uint256 fullInvestment = IERC20(token0).balanceOf(address(this));
        uint256 swapAmountIn = _getSwapAmount(
            fullInvestment,
            reserveA,
            reserveB
        );

        uint256[] memory swapedAmounts = baseParams.uniV2Router.swapExactTokensForTokens(
            swapAmountIn,
            0,
            token0ToToken1,
            address(this),
            block.timestamp
        );
        (, , uint256 amountLiquidity) = baseParams.uniV2Router.addLiquidity(
            token0ToToken1[0],
            token0ToToken1[1],
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

        uint256 nominator = baseParams.uniV2Router.getAmountOut(
            halfInvestment,
            reserveA,
            reserveB
        );

        uint256 denominator = baseParams.uniV2Router.quote(
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
        IERC20(baseParams.want).safeTransfer(baseParams.want, IERC20(baseParams.want).balanceOf(address(this)));
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(baseParams.want).burn(
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