// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20PermitUpgradeable, IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import { IWETH9 } from "../interfaces/IWETH9.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3MintCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import { IUniswapV3SwapCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import { MetavisorRegistry, DENOMINATOR } from "../MetavisorRegistry.sol";
import { Errors } from "../helpers/Errors.sol";

enum VaultType {
    Aggressive,
    Balanced
}

struct VaultSpec {
    int24 tickSpread; // spread from the current tick
    int24 tickOpen; // spread from the edges when to allow rescaling.
    uint32 twapInterval; // time interval for the TWAP
    uint256 priceThreshold; // price threshold for TWAP
}

abstract contract MetavisorBaseVault is
    Initializable,
    ERC20PermitUpgradeable,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    MetavisorRegistry public metavisorRegistry;
    IWETH9 internal weth;

    IERC20MetadataUpgradeable public token0;
    IERC20MetadataUpgradeable public token1;
    IUniswapV3Pool public pool;
    VaultType public vaultType;
    int24 public tickSpacing;

    modifier onlyPool() {
        if (msg.sender != address(pool)) {
            revert Errors.NotPool(msg.sender);
        }
        _;
    }

    // solhint-disable func-name-mixedcase
    function __MetavisorBaseVault_init(
        address _registry,
        address _pool,
        VaultType _vaultType
    ) internal onlyInitializing {
        metavisorRegistry = MetavisorRegistry(_registry);
        weth = metavisorRegistry.weth();

        pool = IUniswapV3Pool(_pool);
        token0 = IERC20MetadataUpgradeable(pool.token0());
        token1 = IERC20MetadataUpgradeable(pool.token1());
        tickSpacing = pool.tickSpacing();
        vaultType = _vaultType;

        uint24 fee = pool.fee();

        if (
            metavisorRegistry.uniswapFactory().getPool(address(token0), address(token1), fee) !=
            address(pool)
        ) {
            revert Errors.InvalidPool();
        }

        string memory vaultName = string.concat(
            "Metavisor ",
            token0.symbol(),
            "/",
            token1.symbol(),
            "-",
            StringsUpgradeable.toString(fee),
            " Vault ",
            _vaultType == VaultType.Balanced ? "B" : "A"
        );
        string memory vaultShort = string.concat(
            "MVR-",
            token0.symbol(),
            "/",
            token1.symbol(),
            "-",
            StringsUpgradeable.toString(fee),
            "-",
            _vaultType == VaultType.Balanced ? "B" : "A"
        );

        __ERC20_init(vaultName, vaultShort);
        __ERC20Permit_init(vaultName);
    }

    function transferProtocolFees(uint256 fees0, uint256 fees1) internal {
        (, address feeReceiver, uint256 feeNumerator) = metavisorRegistry.getProtocolDetails();

        if (feeNumerator > 0) {
            if (fees0 > 0) {
                token0.safeTransfer(feeReceiver, (fees0 * feeNumerator) / DENOMINATOR);
            }
            if (fees1 > 0) {
                token1.safeTransfer(feeReceiver, (fees1 * feeNumerator) / DENOMINATOR);
            }
        }
    }

    receive() external payable {
        if (msg.sender != address(weth)) {
            revert Errors.NotWETH(msg.sender);
        }
    }
}