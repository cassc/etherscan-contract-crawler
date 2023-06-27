//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "../../extensions/TokensRescuer.sol";

import "../../interfaces/IParallaxStrategy.sol";
import "../../interfaces/IParallaxOrbital.sol";
import "../../interfaces/IBalancerVault.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IUniswapWrapper.sol";
import "../../interfaces/IRewardsGauge.sol";
import "../../interfaces/IBalancerWrapper.sol";

error OnlyParallax();
error OnlyWhitelistedToken();
error OnlyValidSlippage();
error OnlyValidAmount();
error OnlyCorrectArrayLength();
error OnlyValidOutputAmount();

/**
 * @title A smart-contract that implements Balancer startegy base implementation
 * with staking functionality.
 */
contract BalancerStrategyBaseUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokensRescuer,
    IParallaxStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct BaseInitParams {
        address _PARALLAX_ORBITAL;
        address _BALANCER_VAULT;
        address _STAKING;
        address _UNI_WRAPPER;
        address _BAL_WRAPPER;
        address _WANT;
        address _WETH;
        IBalancerWrapper.Asset[] _ASSETS;
        Reward[] _REWARDS;
        bytes32 _WANT_POOL_ID;
        uint256 _EXPIRE_TIME;
        uint256 _maxSlippage;
        uint256 _initialCompoundMinAmount;
    }

    struct Reward {
        address token;
        bytes queryIn;
        bytes queryOut;
        AggregatorV2V3Interface wethOracle;
    }

    address public constant STRATEGY_AUTHOR = address(0);

    IBalancerVault.ExitKind exitKind;
    IBalancerVault.JoinKind joinKind;

    address public PARALLAX_ORBITAL;
    address public BALANCER_VAULT;
    address public UNI_WRAPPER;
    address public BAL_WRAPPER;
    address public STAKING;

    address public WETH;
    address public WANT;
    bytes32 public WANT_POOL_ID;

    IBalancerWrapper.Asset[] public assets;
    Reward[] public rewards;

    uint256 public EXPIRE_TIME;
    uint256 public constant STALE_PRICE_DELAY = 24 hours;

    uint256 public accumulatedFees;
    uint256 public maxSlippage;
    uint256 public initialCompoundMinAmount;
    uint256 public currentReward;
     

    modifier onlyParallax() {
        _onlyParallax();
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function __BalancerStrategyBase_init_unchained(
        BaseInitParams memory baseInitParams
    ) internal initializer {
        PARALLAX_ORBITAL = baseInitParams._PARALLAX_ORBITAL;
        BALANCER_VAULT = baseInitParams._BALANCER_VAULT;
        STAKING = baseInitParams._STAKING;
        UNI_WRAPPER = baseInitParams._UNI_WRAPPER;
        BAL_WRAPPER = baseInitParams._BAL_WRAPPER;
        WETH = baseInitParams._WETH;
        EXPIRE_TIME = baseInitParams._EXPIRE_TIME;
        WANT = baseInitParams._WANT;
        WANT_POOL_ID = baseInitParams._WANT_POOL_ID;
        maxSlippage = baseInitParams._maxSlippage;
        initialCompoundMinAmount = baseInitParams._initialCompoundMinAmount;
    
        IERC20Upgradeable(WANT).safeApprove(BAL_WRAPPER, type(uint256).max);

        for (uint256 i = 0; i < baseInitParams._ASSETS.length; i++) {
            assets.push(baseInitParams._ASSETS[i]);
            executeApprovals(baseInitParams._ASSETS[i].token);
        }

        uint256 rewardsLength = baseInitParams._REWARDS.length;
        for (uint256 i = 0; i < rewardsLength; i++) {
            rewards.push(baseInitParams._REWARDS[i]);
            executeApprovals(baseInitParams._REWARDS[i].token);
        }
    }
    
    function setQuery(
        address asset,
        bytes memory queryIn,
        bytes memory queryOut
    ) external onlyOwner {
        for(uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i].token == asset) {
                rewards[i].queryIn = queryIn;
                rewards[i].queryOut = queryOut;
                return;
            }
        }
        for(uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == asset) {
                assets[i].queryIn = queryIn;
                assets[i].queryOut = queryOut;
                return;
            }
        }
    }

    function setCompoundMinAmount(
        uint256 newCompoundMinAmount
    ) external onlyParallax {
        initialCompoundMinAmount = newCompoundMinAmount;
    }

    /// @inheritdoc ITokensRescuer
    function rescueNativeToken(
        uint256 amount,
        address receiver
    ) external onlyParallax {
        _rescueNativeToken(amount, receiver);
    }

    /// @inheritdoc ITokensRescuer
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external onlyParallax {
        _rescueERC20Token(token, amount, receiver);
    }

    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external onlyParallax {}

    function setMaxSlippage(uint256 newMaxSlippage) external onlyParallax {
        if (newMaxSlippage > 1000) {
            revert OnlyValidSlippage();
        }

        maxSlippage = newMaxSlippage;
    }

    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external onlyParallax {}

    /**
     * @notice Deposit amount of BPT tokens into the Balancer pool.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the user's address and the amount of tokens to deposit.
     */
    function depositLPs(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amounts.length, 1);

        uint256 amount = params.amounts[0];
        if (amount > 0) {
            IERC20Upgradeable(WANT).safeTransferFrom(
                params.user,
                address(this),
                amount
            );
    
            return _stake(amount);
        }

        return 0;
    }

    /**
     * @notice Deposit an equal amount of assets into the Balancer pool.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the user's address and the amount of tokens to deposit.
     */
    function depositTokens(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amounts.length, assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amount = params.amounts[i];

            if (amount != 0) {

            IERC20Upgradeable(assets[i].token).safeTransferFrom(
                params.user,
                address(this),
                amount
            );
            }
        }

        return _stake(_balancerAddLiquidity(params.amounts));
    }

    /**
     * @notice Swap native Ether for assets, then deposit them into Balancer pool.
     * @dev This function is only callable by the Parallax contract and requires ETH to be sent along with the transaction.
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amountsOutMin.length, assets.length);
        return _processNative(msg.value, address(0), 0, params.amountsOutMin);
    }

    /**
     * @notice Swap the specified ERC20 token for assets, then deposit them into the Balancer pool.
     * @dev This function is only callable by the Parallax contract.
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        address token = address(uint160(bytes20(params.data[0])));
        _onlyWhitelistedToken(token);
        _onlyCorrectArrayLength(params.amountsOutMin.length, assets.length + 1);

        uint256 amountWeth;
        address exclude;
        uint256 excludeAmount;
        uint256 depositAmount = params.amounts[0];

        if (depositAmount > 0) {
            IERC20Upgradeable(token).safeTransferFrom(
                params.user,
                address(this),
                depositAmount
            );
            for (uint256 i = 0; i < assets.length; i++) {
                address assetToken = assets[i].token;

                if (assetToken == token) {
                    exclude = assetToken;
                    excludeAmount = depositAmount / assets.length;
                }
            }

            if (token != WETH) {
                amountWeth = _preProcessOut(
                    token,
                    params.data[1],
                    depositAmount - excludeAmount,
                    params.amountsOutMin[params.amountsOutMin.length - 1]
                );
            } else {
                amountWeth = depositAmount;
            }

            uint256[] memory minAmounts = _removeElementsFromEnd(params.amountsOutMin, 1);

            IWETH(WETH).withdraw(amountWeth);

            return _processNative(amountWeth, exclude, excludeAmount, minAmounts);
        }

        return 0;
    }

    /**
     * @notice Compound the harvested rewards back into the Aura pool.
     * @dev This function is only callable by the Parallax contract.
     */
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external onlyParallax returns (uint256 amountOut) {
        _harvest(toRevertIfFail);

        uint256 wethBalance = IERC20Upgradeable(WETH).balanceOf(address(this));

        if (wethBalance >= initialCompoundMinAmount) {
            IWETH(WETH).withdraw(wethBalance);

            amountOut = _processNative(
                wethBalance,
                address(0),
                0,
                amountsOutMin
            );
        }
    }

    /**
     * @notice Unstake and withdraw the specified amount of BPT tokens.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, and the earned amount.
     */
    function withdrawTokens(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length, assets.length);

        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            _unstake(actualWithdraw + withdrawalFee);

            _withdraw(params.receiver, actualWithdraw, params.amountsOutMin);

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice Unstake and withdraw the specified amount of BPT tokens.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, and the earned amount.
     */
    function withdrawLPs(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            _unstake(actualWithdraw + withdrawalFee);

            IERC20Upgradeable(WANT).safeTransfer(
                params.receiver,
                actualWithdraw
            );

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice Unstake the specified amount of BPT from rewards gauge, withdraw assets from the Balancer pool and swap them for the specified ERC20 token.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, the earned amount, and the address of the ERC20 token to swap for.
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length % 2, 1);
        _onlyCorrectArrayLength(
            params.amountsOutMin.length / 2,
            assets.length
        );

        IBalancerWrapper.Asset[] memory _assets = assets;

        uint256 totalOut;
        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            uint256[] memory minAmountsOut = _removeElementsFromEnd(
                params.amountsOutMin,
                _assets.length + 1
            );

            address token = address(uint160(bytes20(params.data[0])));

            _unstake(actualWithdraw + withdrawalFee);

            uint256[] memory amounts = _withdraw(
                address(this),
                actualWithdraw,
                minAmountsOut
            );

            uint256 receivedWeth;
            for (uint256 i = 0; i < _assets.length; i++) {
                if (_assets[i].token == token) {
                    totalOut += amounts[i];
                    continue;
                }

                receivedWeth += _preProcessOut(
                    _assets[i].token,
                    _assets[i].queryIn,
                    amounts[i],
                    params.amountsOutMin[minAmountsOut.length + i]
                );
            }

            if (token != WETH) {
                totalOut += _preProcessIn(
                    WETH,
                    token,
                    params.data[1],
                    receivedWeth,
                    params.amountsOutMin[params.amountsOutMin.length - 1]
                );
            } else {
                totalOut = receivedWeth;
            }

            IERC20Upgradeable(token).safeTransfer(params.receiver, totalOut);

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice Unstake the specified amount of BPT from rewards gauge, withdraw from the Balancer pool and swap them for the native token.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, and the earned amount.
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length / 2, assets.length);

        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            uint256[] memory minAmountsOut = _removeElementsFromEnd(
                params.amountsOutMin,
                assets.length
            );

            _unstake(actualWithdraw + withdrawalFee);

            uint256[] memory amounts = _withdraw(
                address(this),
                actualWithdraw,
                minAmountsOut
            );

            uint256 receivedWeth;
            for (uint256 i = 0; i < assets.length; i++) {
             
                receivedWeth += _preProcessOut(
                    assets[i].token,
                    assets[i].queryIn,
                    amounts[i],
                    params.amountsOutMin[minAmountsOut.length + i]
                );
            }

            IWETH(WETH).withdraw(receivedWeth);

            payable(params.receiver).transfer(receivedWeth);

            _takeFee(withdrawalFee);
        }
    }

    function getMaxFee() external pure returns (uint256) {
        return 10000;
    }

    function executeApprovals(address _whitelistedToken) public virtual {}

    function executeApprovalsBatch(address[] memory _whitelistedTokens)
        public
    {
        for (uint256 i = 0; i < _whitelistedTokens.length; i++) {
            executeApprovals(_whitelistedTokens[i]);
        }
    }

    function _unstake(uint256 amount) internal virtual {
        IRewardsGauge(STAKING).withdraw(amount);
    }

    /**
     * @dev Adds liquidity to the Balancer pool using the provided amounts of assets.
     * @param amounts The amounts of assets to add as liquidity.
     */
    function _balancerAddLiquidity(
        uint256[] memory amounts
    ) internal virtual returns (uint256) {
        return
            IBalancerWrapper(BAL_WRAPPER).join(
                amounts,
                WANT_POOL_ID,
                WANT,
                assets,
                joinKind
            );
    }

    function _processNative(
        uint256 amount,
        address exclude,
        uint256 excludeAmount,
        uint256[] memory minAmounts
    ) internal returns (uint256 staked) {
        if (amount > 0) {
            uint256[] memory amounts = _breakEth(
                amount,
                exclude,
                excludeAmount,
                minAmounts
            );

            staked = _stake(_balancerAddLiquidity(amounts));
        }
    }

    /**
     * @dev Harvests the rewards and converts them to WETH.
     */
    function _harvest(bool toRevertIfFail) internal {
        uint256[] memory amounts = _claim();

        for (uint256 i = 0; i < rewards.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }

            if(rewards[i].token == WETH){
                continue;
            }

            (uint256 rate, uint256 decimals) = _getPrice(rewards[i].wethOracle);
            uint256 rewardWeth = _preProcessAmounts(rewards[i], amounts[i]);

            if (rate > 0) {
                uint256 amountOutOracle = (rate * amounts[i]) /
                    (10 **
                        (decimals -
                            (decimals - IWETH(rewards[i].token).decimals())));
                uint256 slippage = (amountOutOracle * (10000 - maxSlippage)) /
                    10000;

                if (rewardWeth >= slippage) {
                    _preProcessOut(
                        rewards[i].token,
                        rewards[i].queryIn,
                        amounts[i],
                        slippage
                    );
                } else if (toRevertIfFail) {
                    revert OnlyValidOutputAmount();
                }
            }
        }
    }

    /**
     * @dev Stakes the specified amount of tokens into the staking contract.
     *
     * @param amount The amount of tokens to stake.
     * @dev Deposits the specified `amount` of tokens into the staking contract.
     */
    function _stake(uint256 amount) internal virtual returns (uint256) {
        return IRewardsGauge(STAKING).deposit(amount);
    }

    /**
     * @dev Claims the rewards from the staking contract.
     *
     * @return amounts An array of reward amounts.
     * @dev Claims the rewards from the staking contract using the `claim_rewards()` function from `IRewardsGauge`.
     * @dev Retrieves the balance of each reward token and stores them in the `amounts` array.
     */
    function _claim() internal virtual returns (uint256[] memory amounts) {
        IRewardsGauge(STAKING).claim_rewards(address(this));
        amounts = new uint256[](rewards.length);

        for (uint256 i = 0; i < rewards.length; i++) {
            amounts[i] = IERC20Upgradeable(rewards[i].token).balanceOf(
                address(this)
            );
        }
    }

    function _preProcessIn(
        address /*tokenIn*/,
        address /*tokenOut*/,
        bytes memory /*path*/,
        uint256 /*amount*/,
        uint256 /*minAmountOut*/
    ) internal virtual returns (uint256) {
        return 0;
    }

    function _preProcessOut(
        address /*token*/,
        bytes memory /*path*/,
        uint256 /*amount*/,
        uint256 /*minAmountOut*/
    ) internal virtual returns (uint256) {
        return 0;
    }

       /**
     * @dev Swaps an ERC20 token for any other token via Uniswap V3 wrapper.
     * @param tokenIn The address of the input ERC20 token.
     * @param path The encoded path for the swap.
     * @param amountIn The amount of input token to swap.
     * @param minAmountOut The minimum acceptable amount of the output token.
     * @return amountOut The actual amount of output tokens received.
     */
    function _uniSwapAny(
        address tokenIn,
        bytes memory path,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal virtual returns (uint256) {
        uint256 amountOut = IUniswapWrapper(UNI_WRAPPER).swapV3(
            tokenIn,
            path,
            amountIn,
            minAmountOut
        );

        return amountOut;
    }

    function _preProcessAmounts(
        Reward memory /*reward*/,
        uint256 /*amount*/
    ) internal virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Unstake the specified amount of BPT tokens from the rewards gauge and
     *      exits the Balancer pool, returning the assets to the recipient.
     * @param amount: The amount of BPT tokens to withdraw.
     * @param recipient: The address that will receive the withdrawn tokens.
     */
    function _withdraw(
        address recipient,
        uint256 amount,
        uint256[] memory minAmountsOut
    ) internal virtual returns (uint256[] memory delta) {
        IBalancerWrapper.Asset[] memory _assets = assets;
        
        return
            IBalancerWrapper(BAL_WRAPPER).exit(
                recipient,
                amount,
                minAmountsOut,
                WANT_POOL_ID,
                WANT,
                _assets,
                exitKind
            );
    }

    /**
     * @dev Performs a single swap using Balancer Vault.
     * @param tokenOut The address of the output ERC20 token.
     * @param tokenIn The address of the input ERC20 token.
     * @param amountIn The amount of input token to swap.
     * @param minAmountOut The minimum acceptable amount of the output token.
     * @param poolId The PoolId of the Balancer pool to use for the swap.
     * @return receivedTokenOut The actual amount of output tokens received.
     */
    function _balancerSwapSingle(
        address tokenOut,
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId
    ) internal returns (uint256) {
        return
            IBalancerWrapper(BAL_WRAPPER).swapSingle(
                tokenOut,
                tokenIn,
                amountIn,
                minAmountOut,
                poolId,
                _getDeadline()
            );
    }

    /**
     * @dev Breaks a given amount of Ether into underlying tokens.
     * @param amount The amount of Ether to break.
     */
    function _breakEth(
        uint256 amount,
        address exclude,
        uint256 excludeAmount,
        uint256[] memory minAmountsOut
    ) internal returns (uint256[] memory amounts) {
        IBalancerWrapper.Asset[] memory _assets = assets;

        uint256 assetsLength = _assets.length;

        if (amount < assetsLength) {
            revert OnlyValidAmount();
        }

        IWETH(WETH).deposit{ value: amount }();
        uint256 part = amount / assetsLength;
        amounts = new uint256[](assetsLength);

        for (uint256 i = 0; i < assetsLength; i++) {
            if (_assets[i].token == WETH) {
                amounts[i] = part;
            } else if (_assets[i].token == exclude) {
                amounts[i] = excludeAmount;
            } else {
               
                amounts[i] = _preProcessIn(
                    WETH,
                    _assets[i].token,
                    _assets[i].queryOut,
                    part,
                    minAmountsOut[i]
                );
            }
        }
    }

    function _takeFee(uint256 fee) internal {
        if (fee > 0) {
            accumulatedFees += fee;
            IERC20Upgradeable(WANT).safeTransfer(
                IParallaxOrbital(PARALLAX_ORBITAL).feesReceiver(),
                fee
            );
        }
    }

    function _calculateActualWithdrawAndWithdrawalFee(
        uint256 withdrawalAmount,
        uint256 earnedAmount
    ) internal view returns (uint256 actualWithdraw, uint256 withdrawalFee) {
        uint256 actualEarned = (earnedAmount *
            (10000 -
                IParallaxOrbital(PARALLAX_ORBITAL).getFee(address(this)))) /
            10000;

        withdrawalFee = earnedAmount - actualEarned;
        actualWithdraw = withdrawalAmount - withdrawalFee;
    }

    function _getDeadline() private view returns (uint256) {
        return block.timestamp + EXPIRE_TIME;
    }

    /**
     * @notice Returns a price of a token in a specified oracle.
     * @param oracle An address of an oracle which will return a price of asset.
     * @return A tuple with a price of token, token decimals and a flag that
     *         indicates if data is actual (fresh) or not.
     */
    function _getPrice(
        AggregatorV2V3Interface oracle
    ) internal view returns (uint256, uint8) {
        if (address(oracle) == address(0)) {
            return (0, 0);
        }
        (
            uint80 roundID,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = oracle.latestRoundData();
        bool dataIsActual = answeredInRound >= roundID &&
            answer > 0 &&
            block.timestamp <= updatedAt + 24 hours;

        if (!dataIsActual) {
            return (0, 0);
        }

        uint8 decimals = oracle.decimals();

        return (uint256(answer), decimals);
    }

    /**
     * @dev Retrieves the output amount for a given input amount using Uniswap v3 Wrapper for a specific reward.
     * @param reward The reward data containing the queryIn parameter.
     * @param amountIn The amount of input tokens.
     * @return amountOut The amount of output tokens.
     */
    function _getAmountOutUni(
        Reward memory reward,
        uint256 amountIn
    ) internal returns (uint256) {
        return
            IUniswapWrapper(UNI_WRAPPER).getAmountOut(reward.queryIn, amountIn);
    }

    /**
     * @dev Retrieves the output amount for a given input amount using Balancer Vault.
     * @param amountIn The amount of input tokens.
     * @param tokenIn The address of the input ERC20 token.
     * @param tokenOut The address of the output ERC20 token.
     * @param poolId The PoolId of the Balancer pool to use for the swap.
     * @return amountOut The amount of output tokens.
     */
    function _getAmountOutBal(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bytes32 poolId
    ) internal returns (uint256) {
        return
            IBalancerWrapper(BAL_WRAPPER).getAmountOut(
                amountIn,
                tokenIn,
                tokenOut,
                poolId
            );
    }

    function _removeElementsFromEnd(
        uint256[] memory arr,
        uint256 n
    ) internal pure returns (uint256[] memory) {
        assert(n <= arr.length);

        uint256[] memory newArr = new uint256[](arr.length - n);
        for (uint256 i = 0; i < newArr.length; i++) {
            newArr[i] = arr[i];
        }
        return newArr;
    }

    function _onlyParallax() private view {
        if (_msgSender() != PARALLAX_ORBITAL) {
            revert OnlyParallax();
        }
    }

    function _onlyWhitelistedToken(address token) private view {
        if (
            !IParallaxOrbital(PARALLAX_ORBITAL).tokensWhitelist(
                address(this),
                token
            )
        ) {
            revert OnlyWhitelistedToken();
        }
    }

    function _onlyCorrectArrayLength(
        uint256 actualLength,
        uint256 expectedlength
    ) private pure {
        if (actualLength != expectedlength) {
            revert OnlyCorrectArrayLength();
        }
    }
}