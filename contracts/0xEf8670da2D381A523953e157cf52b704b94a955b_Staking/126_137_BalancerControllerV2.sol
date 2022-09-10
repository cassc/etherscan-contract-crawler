// // SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IVault.sol";
import "./BaseController.sol";

import "../interfaces/balancer/WeightedPoolUserData.sol";

contract BalancerControllerV2 is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

	IVault public immutable vault;

    constructor(IVault _vault, address manager, address _accessControl, address _addressRegistry) public BaseController(manager, _accessControl, _addressRegistry) {
		require(address(_vault) != address(0), "!vault");

		vault = _vault;
	}

    /// @notice Used to deploy liquidity to a Balancer V2 weighted pool
    /// @dev Calls into external contract
    /// @param poolId Balancer's ID of the pool to have liquidity added to
    /// @param tokens Array of ERC20 tokens to be added to pool
    /// @param amounts Corresponding array of amounts of tokens to be added to a pool
    /// @param poolAmountOut Amount of LP tokens to be received from the pool
    function deploy(
        bytes32 poolId,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256 poolAmountOut
    ) external onlyManager onlyAddLiquidity {
        uint256 nTokens = tokens.length;
        require(nTokens == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
        require(nTokens > 0, "!TOKENS");
        require(poolAmountOut > 0, "!POOL_AMOUNT_OUT");

        // get bpt address of the pool (for later balance checks)
        (address poolAddress,) = vault.getPool(poolId);

        // verify that we're passing correct pool tokens
        // (two part verification: total number checked here, and individual match check below)
        (IERC20[] memory poolAssets, , ) = vault.getPoolTokens(poolId);
        require(poolAssets.length == nTokens, "!(tokensIn==poolTokens");

        uint256[] memory assetBalancesBefore = new uint256[](nTokens);

		// run through tokens and make sure we have approvals (and correct token order)
        for (uint256 i = 0; i < nTokens; ++i) {
            // as per new requirements, 0 amounts are not allowed even though balancer supports it
            require(amounts[i] > 0, "!AMOUNTS[i]");

            // make sure asset is supported (and matches the pool's assets)
            require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
            require(tokens[i] == poolAssets[i], "tokens[i]!=poolAssets[i]");

            // record previous balance for this asset
            assetBalancesBefore[i] = tokens[i].balanceOf(address(this));

            // grant spending approval to balancer's Vault
            _approve(tokens[i], amounts[i]);
        }

        // record balances before deposit
        uint256 bptBalanceBefore = IERC20(poolAddress).balanceOf(address(this));

        // encode pool entrance custom userData
        bytes memory userData = abi.encode(
            WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amounts, //maxAmountsIn,
            poolAmountOut
        );

        IVault.JoinPoolRequest memory joinRequest = IVault.JoinPoolRequest({
            assets: _convertERC20sToAssets(tokens),
            maxAmountsIn: amounts, // maxAmountsIn,
            userData: userData,
            fromInternalBalance: false // vault will pull the tokens from contoller instead of internal balances
        });

        vault.joinPool(
            poolId,
            address(this), // sender
            address(this), // recipient of BPT token
            joinRequest
        );

        // make sure we received bpt
        uint256 bptBalanceAfter = IERC20(poolAddress).balanceOf(address(this));
        require(bptBalanceAfter >= bptBalanceBefore.add(poolAmountOut), "BPT_MUST_INCREASE_BY_MIN_POOLAMOUNTOUT");
        // make sure assets were taken out
        for (uint256 i = 0; i < nTokens; ++i) {
            require(tokens[i].balanceOf(address(this)) == assetBalancesBefore[i].sub(amounts[i]), "ASSET_MUST_DECREASE");
        }
    }

    /// @notice Withdraw liquidity from Balancer V2 pool (specifying exact asset token amounts to get)
    /// @dev Calls into external contract
    /// @param poolId Balancer's ID of the pool to have liquidity withdrawn from
    /// @param maxBurnAmount Max amount of LP tokens to burn in the withdrawal
    /// @param exactAmountsOut Array of exact amounts of tokens to be withdrawn from pool
    function withdraw(
        bytes32 poolId,
        uint256 maxBurnAmount,
        IERC20[] calldata tokens,
        uint256[] calldata exactAmountsOut
    ) external onlyManager onlyRemoveLiquidity {
        // encode withdraw request
        bytes memory userData = abi.encode(
            WeightedPoolUserData.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT,
            exactAmountsOut,
            maxBurnAmount
        );

        _withdraw(poolId, maxBurnAmount, tokens, exactAmountsOut, userData);
    }

    /// @notice Withdraw liquidity from Balancer V2 pool (specifying exact LP tokens to burn)
    /// @dev Calls into external contract
    /// @param poolId Balancer's ID of the pool to have liquidity withdrawn from
    /// @param poolAmountIn Amount of LP tokens to burn in the withdrawal
    /// @param minAmountsOut Array of minimum amounts of tokens to be withdrawn from pool
    function withdrawImbalance(
        bytes32 poolId,
        uint256 poolAmountIn,
        IERC20[] calldata tokens,
        uint256[] calldata minAmountsOut
    ) external onlyManager onlyRemoveLiquidity {
        // encode withdraw request
        bytes memory userData = abi.encode(
            WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
            poolAmountIn
        );

        _withdraw(poolId, poolAmountIn, tokens, minAmountsOut, userData);
    }

    function _withdraw(
        bytes32 poolId,
        uint256 bptAmount,
        IERC20[] calldata tokens,
        uint256[] calldata amountsOut,
        bytes memory userData
    ) internal {
        uint256 nTokens = tokens.length;
        require(nTokens == amountsOut.length, "IN_TOKEN_AMOUNTS_COUNT_MISMATCH");
        require(nTokens > 0, "!TOKENS");

        (IERC20[] memory poolTokens, , ) = vault.getPoolTokens(poolId);
        uint256 numTokens = poolTokens.length;
        require(numTokens == amountsOut.length, "TOKEN_AMOUNTS_LENGTH_MISMATCH");

        // run through tokens and make sure it matches the pool's assets
        for (uint256 i = 0; i < nTokens; ++i) {
            require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
            require(tokens[i] == poolTokens[i], "tokens[i]!=poolTokens[i]");
        }

        // grant erc20 approval for vault to spend our tokens
        (address poolAddress,) = vault.getPool(poolId);
        _approve(IERC20(poolAddress), bptAmount);

        // record balance before withdraw
        uint256 bptBalanceBefore = IERC20(poolAddress).balanceOf(address(this));
        uint256[] memory assetBalancesBefore = new uint256[](poolTokens.length);
        for (uint256 i = 0; i < numTokens; ++i) {
            assetBalancesBefore[i] = poolTokens[i].balanceOf(address(this));
        }

        // As we're exiting the pool we need to make an ExitPoolRequest instead
        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest({
            assets: _convertERC20sToAssets(poolTokens),
            minAmountsOut: amountsOut,
            userData: userData,
            toInternalBalance: false // send tokens back to us vs keeping inside vault for later use
        });

        vault.exitPool(
            poolId,
            address(this), // sender,
            payable(address(this)), // recipient,
            request
        );

        // make sure we burned bpt, and assets were received
        require(IERC20(poolAddress).balanceOf(address(this)) < bptBalanceBefore, "BPT_MUST_DECREASE");
        for (uint256 i = 0; i < numTokens; ++i) {
            require(poolTokens[i].balanceOf(address(this)) >= assetBalancesBefore[i].add(amountsOut[i]), "ASSET_MUST_INCREASE");
        }
    }

    /// @dev Make sure vault has our approval for given token (reset prev approval)
    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(vault));
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(address(vault), currentAllowance);
        }
        token.safeIncreaseAllowance(address(vault), amount);
    }

    /**
    * @dev This helper function is a fast and cheap way to convert between IERC20[] and IAsset[] types
    */
    function _convertERC20sToAssets(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            assets := tokens
        }
    }
}