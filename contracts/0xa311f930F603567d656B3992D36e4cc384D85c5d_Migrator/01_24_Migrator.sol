// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.19;

import { WETH } from "solmate/src/tokens/WETH.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

import { IUniswapV2Pair } from "src/interfaces/univ2/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "src/interfaces/univ2/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "src/interfaces/univ2/IUniswapV2Router02.sol";
import { IAsset } from "src/interfaces/balancer/IAsset.sol";
import { IVault } from "src/interfaces/balancer/IVault.sol";
import { WeightedPoolUserData } from "src/interfaces/balancer/WeightedPoolUserData.sol";

import { IMigrator } from "src/interfaces/IMigrator.sol";

/**
 * @title UniV2 LP to Balancer LP migrator
 * @notice Tool to facilitate migrating UniV2 LPs to Balancer or Aura
 * @dev LP: IUniswapV2Pair LP Token
 * @dev BPT: 20WETH-80TOKEN Balancer Pool Token
 * @dev auraBPT: 20WETH-80TOKEN Aura Deposit Vault
 */
contract Migrator is IMigrator {
    using SafeTransferLib for ERC20;
    
    // WETH token
    WETH public immutable weth;
    // Balancer vault
    IVault public immutable balancerVault;
    // Router for the UniV2 LP token
    IUniswapV2Router02 public immutable router;
    // Factory for the UniV2 LP token
    IUniswapV2Factory public immutable factory;

    constructor(address wethAddress, address balancerVaultAddress, address routerAddress) {
        weth =          WETH(payable(wethAddress));
        balancerVault = IVault(balancerVaultAddress);
        router =        IUniswapV2Router02(routerAddress);
        factory =       IUniswapV2Factory(router.factory());
    }
    
    /**
     * @inheritdoc IMigrator
     */
    function migrate(MigrationParams calldata params) external {
        // If the user is staking, then the Aura pool asset must be the same as the Balancer pool token
        if (params.stake) {
            require(address(params.balancerPoolToken) == params.auraPool.asset(), "Invalid Aura pool");
        }

        // Grab the two tokens in the balancer vault. If the vault has more than two tokens, the migration will fail.
        bytes32 poolId = params.balancerPoolToken.getPoolId();
        (IERC20[] memory balancerPoolTokens, /* uint256[] memory balances */, /* uint256 lastChangeBlock */) = balancerVault.getPoolTokens(poolId);
        require(balancerPoolTokens.length == 2, "Invalid balancer pool");

        // Find the companion token
        IERC20 companionToken;
        if (balancerPoolTokens[0] == IERC20(address(weth))) {
            companionToken = balancerPoolTokens[1];
        } else if (balancerPoolTokens[1] == IERC20(address(weth))) {
            companionToken = balancerPoolTokens[0];
        } else {
            // If neither token is WETH, then the migration will fail
            revert("Balancer pool must contain WETH");
        }

        // Verify there is a matching UniV2 pool (ordering is handled upstream by the factory)
        address poolToken = factory.getPair(address(companionToken), address(weth));

        require(poolToken != address(0), "Pool address verification failed");
        
        // Transfer the pool tokens to this contract before we conduct any mutations
        ERC20(address(poolToken)).safeTransferFrom(msg.sender, address(this), params.poolTokensIn);

        // Check if the pool token has been approved for the router
        if (IUniswapV2Pair(poolToken).allowance(address(this), address(router)) < params.poolTokensIn) {
            ERC20(address(poolToken)).safeApprove(address(router), type(uint256).max);
        }

        // The ordering of `tokenA` and `tokenB` is handled upstream by the router
        router.removeLiquidity({
            tokenA:     address(companionToken),
            tokenB:     address(weth),
            liquidity:  params.poolTokensIn,
            amountAMin: params.amountCompanionMinimumOut,
            amountBMin: params.amountWETHMinimumOut,
            to:         address(this),
            deadline:   block.timestamp
        });

        require(weth.balanceOf(address(this)) > params.wethRequired, "Contract doesn't have enough weth");

        // Check if the WETH token has been approved for the balancer vault
        if (ERC20(address(weth)).allowance(address(this), address(balancerVault)) < weth.balanceOf(address(this))) {
            ERC20(address(weth)).safeApprove(address(balancerVault), type(uint256).max);
        }

        balancerVault.swap({
            singleSwap:  IVault.SingleSwap({
                poolId: poolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn:  IAsset(address(weth)),
                assetOut: IAsset(address(companionToken)),
                // Swap the amount of WETH not needed for the Balancer pool deposit
                amount: weth.balanceOf(address(this)) - params.wethRequired,
                userData: bytes("")
            }),
            funds: IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            limit: params.minAmountTokenOut,
            deadline: block.timestamp
        });

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(balancerPoolTokens[0]));
        assets[1] = IAsset(address(balancerPoolTokens[1]));

        uint256[] memory maximumAmountsIn = new uint256[](2);
        
        // Make sure the amounts in are in the correct order
        if (balancerPoolTokens[0] == IERC20(address(weth))) {
            maximumAmountsIn[0] = weth.balanceOf(address(this));
            maximumAmountsIn[1] = companionToken.balanceOf(address(this));
        } else {
            maximumAmountsIn[0] = companionToken.balanceOf(address(this));
            maximumAmountsIn[1] = weth.balanceOf(address(this));
        }

        // Approve the balancer vault to spend the companion token
        ERC20(address(companionToken)).safeApprove(address(balancerVault), 0);
        ERC20(address(companionToken)).safeApprove(address(balancerVault), companionToken.balanceOf(address(this)));        

        balancerVault.joinPool({
            poolId: poolId,
            sender: address(this),
            recipient: address(this),
            request: IVault.JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maximumAmountsIn,
                userData: abi.encode(
                    WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    maximumAmountsIn,
                    params.amountBalancerLiquidityOut
                ),
                fromInternalBalance: false
            })
        });

        // Get the amount of BPT received since joinPool does not return the amount
        uint256 balancerPoolTokensReceived = params.balancerPoolToken.balanceOf(address(this));

        // If the user is staking, we deposit BPT into the Aura pool on the user's behalf
        // Otherwise, we transfer the BPT to the user
        if (params.stake) {
            ERC20(address(params.balancerPoolToken)).safeApprove(address(params.auraPool), balancerPoolTokensReceived);
            uint256 shares = params.auraPool.deposit(balancerPoolTokensReceived, msg.sender);
            require(shares >= params.amountAuraSharesMinimum, "Invalid auraBpt amount out");
        } else {
            ERC20(address(params.balancerPoolToken)).safeTransfer(msg.sender, balancerPoolTokensReceived);
        }

        // Indicate who migrated, UniV2 pool source, balancer pool destination, amounts in and out, and whether the user is staking
        emit Migrated(msg.sender, poolToken, address(params.balancerPoolToken), params.poolTokensIn, balancerPoolTokensReceived, params.stake);
    }
}