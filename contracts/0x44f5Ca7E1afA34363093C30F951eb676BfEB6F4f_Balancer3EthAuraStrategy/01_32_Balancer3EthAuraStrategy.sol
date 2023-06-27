//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./BalancerStrategyBase.sol";

import "../../interfaces/IStEth.sol";
import "../../interfaces/IWstEth.sol";
import "../../interfaces/IAura.sol";
import "../../interfaces/IFrxEthMinter.sol";

/**
 * @title A smart-contract that implements Balancer wstETH-sfrxETH-rETH pool strategy
 * and Aura staking.
 */
contract Balancer3EthAuraStrategy is BalancerStrategyBaseUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public STAKING_TOKEN;

    address private BAL;
    address private AURA;

    address private WSTETH;
    address private STETH;
    address private SFRXETH;
    address private FRXETH;
    address private FRXETH_MINTER;

    bytes32 private WETH_WSTETH_ID;
    bytes32 private BAL_WETH_ID;
    bytes32 private AURA_WETH_ID;

    struct InitParams {
        address _BAL;
        address _AURA;
        address _WSTETH;
        address _STETH;
        address _SFRXETH;
        address _FRXETH;
        address _FRXETH_MINTER;
        bytes32 _WETH_WSTETH_ID;
        bytes32 _BAL_WETH_ID;
        bytes32 _AURA_WETH_ID;
    }

    function __Balancer3EthAuraStrategy_init_unchained(
        InitParams memory initParams
    ) internal initializer {
        BAL = initParams._BAL;
        AURA = initParams._AURA;
        WSTETH = initParams._WSTETH;
        STETH = initParams._STETH;
        SFRXETH = initParams._SFRXETH;
        FRXETH = initParams._FRXETH;
        FRXETH_MINTER = initParams._FRXETH_MINTER;
        WETH_WSTETH_ID = initParams._WETH_WSTETH_ID;
        BAL_WETH_ID = initParams._BAL_WETH_ID;
        AURA_WETH_ID = initParams._AURA_WETH_ID;
    }

    function __Balancer3EthAuraStrategy_init(
        BaseInitParams memory baseInitParams,
        InitParams memory initParams
    ) public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __BalancerStrategyBase_init_unchained(baseInitParams);
        __Balancer3EthAuraStrategy_init_unchained(initParams);

        exitKind = IBalancerVault.ExitKind.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT;

        joinKind = IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
    }

    /**
     * @dev Withdraws and unstakes a certain amount of tokens from the staking contract.
     * @param amount The amount of tokens to unstake.
     */
    function _unstake(uint256 amount) internal override {
        IAura(STAKING).withdrawAndUnwrap(amount, true);
    }

    /**
     * @dev Stakes a certain amount of tokens into the staking contract.
     * @param amount The amount of tokens to stake.
     */
    function _stake(uint256 amount) internal override returns (uint256) {
        return IAura(STAKING).deposit(amount, address(this));
    }

    /**
     * @dev Claims rewards from the staking contract.
     * @return amounts An array with the amounts of each reward token.
     */
    function _claim()
        internal
        virtual
        override
        returns (uint256[] memory amounts)
    {
        IAura(STAKING).getReward(address(this), true);

        amounts = new uint256[](rewards.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            amounts[i] = IERC20Upgradeable(rewards[i].token).balanceOf(
                address(this)
            );
        }
    }

    /**
     * @dev Performs pre-processing for deposit operations.
     * @param tokenIn The token to be deposited.
     * @param amount The amount of tokens to deposit.
     * @return The amount to be processed.
     */
    function _preProcessIn(
        address tokenIn,
        address tokenOut,
        bytes memory path,
        uint256 amount,
        uint256 minAmountOut
    ) internal override returns (uint256) {
        if (tokenOut == WSTETH) {
            IWETH(WETH).withdraw(amount);
            IStEth(STETH).submit{ value: address(this).balance }(address(0));

            return
                IWstEth(WSTETH).wrap(
                    IERC20Upgradeable(STETH).balanceOf(address(this))
                );
        } else if (tokenOut == SFRXETH) {
            IWETH(WETH).withdraw(amount);

            return
                IFrxEthMinter(FRXETH_MINTER).submitAndDeposit{
                    value: address(this).balance
                }(address(this));
        } else {

            return _uniSwapAny(tokenIn, path, amount, minAmountOut);
        }
    }

    /**
     * @dev Performs pre-processing for withdrawal operations.
     * @param token The token to be withdrawn.
     * @param amount The amount of tokens to withdraw.
     * @param minAmountOut The minimum acceptable amount to be withdrawn.
     * @return The amount to be processed.
     */
    function _preProcessOut(
        address token,
        bytes memory path,
        uint256 amount,
        uint256 minAmountOut
    ) internal override returns (uint256) {
        if (token == WSTETH) {
            uint256 amountOut = _balancerSwapSingle(
                WETH,
                WSTETH,
                amount,
                minAmountOut,
                WETH_WSTETH_ID
            );

            return amountOut;
        } else if (token == SFRXETH) {
            uint256 amountOutWsteth = _balancerSwapSingle(
                WSTETH,
                SFRXETH,
                amount,
                minAmountOut,
                WANT_POOL_ID
            );

            uint256 amountOut = _balancerSwapSingle(
                WETH,
                WSTETH,
                amountOutWsteth,
                0,
                WETH_WSTETH_ID
            );

            return amountOut;
        } else {
            return _uniSwapAny(token, path, amount, minAmountOut);
        }
    }

    /**
     * @dev Pre-processes amounts for reward calculation.
     * @param reward The reward to be processed.
     * @param amount The amount of reward tokens.
     * @return The processed amount.
     */
    function _preProcessAmounts(
        Reward memory reward,
        uint256 amount
    ) internal override returns (uint256) {
        if (reward.token == BAL) {
            return _getAmountOutBal(amount, reward.token, WETH, BAL_WETH_ID);
        } else if (reward.token == AURA) {
            return _getAmountOutBal(amount, reward.token, WETH, AURA_WETH_ID);
        } else {
            return _getAmountOutUni(reward, amount);
        }
    }

    function executeApprovals(address _whitelistedToken) public override {
        if (_whitelistedToken == STETH) {
            IERC20Upgradeable(STETH).safeApprove(WSTETH, 0);
            IERC20Upgradeable(STETH).safeApprove(WSTETH, type(uint256).max);
        }

        if (_whitelistedToken == SFRXETH) {
            IERC20Upgradeable(SFRXETH).safeApprove(FRXETH_MINTER, 0);
            IERC20Upgradeable(SFRXETH).safeApprove(
                FRXETH_MINTER,
                type(uint256).max
            );
        }

        IERC20Upgradeable(_whitelistedToken).safeApprove(STAKING, 0);
        IERC20Upgradeable(_whitelistedToken).safeApprove(
            STAKING,
            type(uint256).max
        );

        IERC20Upgradeable(_whitelistedToken).safeApprove(BAL_WRAPPER, 0);
        IERC20Upgradeable(_whitelistedToken).safeApprove(
            BAL_WRAPPER,
            type(uint256).max
        );

        IERC20Upgradeable(_whitelistedToken).safeApprove(UNI_WRAPPER, 0);
        IERC20Upgradeable(_whitelistedToken).safeApprove(
            UNI_WRAPPER,
            type(uint256).max
        );
    }
}