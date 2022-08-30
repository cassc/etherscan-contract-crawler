// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {SafeTransferLib, ERC20} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {PercentageMath} from "@morpho-labs/morpho-utils/math/PercentageMath.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SupplyVaultBase} from "./SupplyVaultBase.sol";

/// @title SupplyHarvestVault.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice ERC4626-upgradeable Tokenized Vault implementation for Morpho-Compound, which can harvest accrued COMP rewards, swap them and re-supply them through Morpho-Compound.
contract SupplyHarvestVault is SupplyVaultBase, OwnableUpgradeable {
    using SafeTransferLib for ERC20;
    using PercentageMath for uint256;

    /// EVENTS ///

    /// @notice Emitted when an harvest is done.
    /// @param harvester The address of the harvester receiving the fee.
    /// @param rewardsAmount The amount of rewards in underlying asset which is supplied to Morpho.
    /// @param rewardsFee The amount of underlying asset sent to the harvester.
    event Harvested(address indexed harvester, uint256 rewardsAmount, uint256 rewardsFee);

    /// @notice Emitted when the fee for swapping comp for WETH is set.
    /// @param newCompSwapFee The new comp swap fee (in UniswapV3 fee unit).
    event CompSwapFeeSet(uint24 newCompSwapFee);

    /// @notice Emitted when the fee for swapping WETH for the underlying asset is set.
    /// @param newAssetSwapFee The new asset swap fee (in UniswapV3 fee unit).
    event AssetSwapFeeSet(uint24 newAssetSwapFee);

    /// @notice Emitted when the fee for harvesting is set.
    /// @param newHarvestingFee The new harvesting fee.
    event HarvestingFeeSet(uint16 newHarvestingFee);

    /// @notice Emitted when the maximum slippage for harvesting is set.
    /// @param newMaxHarvestingSlippage The new maximum slippage allowed when swapping rewards for the underlying token (in bps).
    event MaxHarvestingSlippageSet(uint16 newMaxHarvestingSlippage);

    /// ERRORS ///

    /// @notice Thrown when the input is above the maximum basis points value (100%).
    /// @param _value The value exceeding the threshold.
    error ExceedsMaxBasisPoints(uint16 _value);

    /// @notice Thrown when the input is above the maximum UniswapV3 pool fee value (100%).
    /// @param _value The value exceeding the threshold.
    error ExceedsMaxUniswapV3Fee(uint24 _value);

    /// STRUCTS ///

    struct HarvestConfig {
        uint24 compSwapFee; // The fee taken by the UniswapV3Pool for swapping COMP rewards for WETH (in UniswapV3 fee unit).
        uint24 assetSwapFee; // The fee taken by the UniswapV3Pool for swapping WETH for the underlying asset (in UniswapV3 fee unit).
        uint16 harvestingFee; // The fee taken by the claimer when harvesting the vault (in bps).
    }

    /// STORAGE ///

    uint16 public constant MAX_BASIS_POINTS = 100_00; // 100% in basis points.
    uint24 public constant MAX_UNISWAP_FEE = 100_0000; // 100% in UniswapV3 fee units.
    ISwapRouter public constant SWAP_ROUTER =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // The address of UniswapV3SwapRouter.

    bool public isEth; // Whether the underlying asset is WETH.
    address public wEth; // The address of WETH token.
    HarvestConfig public harvestConfig; // The configuration of the swap on Uniswap V3.

    /// UPGRADE ///

    /// @notice Initializes the vault.
    /// @param _morpho The address of the main Morpho contract.
    /// @param _poolToken The address of the pool token corresponding to the market to supply through this vault.
    /// @param _name The name of the ERC20 token associated to this tokenized vault.
    /// @param _symbol The symbol of the ERC20 token associated to this tokenized vault.
    /// @param _initialDeposit The amount of the initial deposit used to prevent pricePerShare manipulation.
    /// @param _harvestConfig The swap config to set.
    function initialize(
        address _morpho,
        address _poolToken,
        string calldata _name,
        string calldata _symbol,
        uint256 _initialDeposit,
        HarvestConfig calldata _harvestConfig
    ) external initializer {
        if (_harvestConfig.compSwapFee > MAX_UNISWAP_FEE)
            revert ExceedsMaxUniswapV3Fee(_harvestConfig.compSwapFee);
        if (_harvestConfig.assetSwapFee > MAX_UNISWAP_FEE)
            revert ExceedsMaxUniswapV3Fee(_harvestConfig.assetSwapFee);
        if (_harvestConfig.harvestingFee > MAX_BASIS_POINTS)
            revert ExceedsMaxBasisPoints(_harvestConfig.harvestingFee);

        __Ownable_init();
        (isEth, wEth) = __SupplyVaultBase_init(
            _morpho,
            _poolToken,
            _name,
            _symbol,
            _initialDeposit
        );

        harvestConfig = _harvestConfig;

        comp.safeApprove(address(SWAP_ROUTER), type(uint256).max);
    }

    /// GOVERNANCE ///

    /// @notice Sets the fee taken by the UniswapV3Pool for swapping COMP rewards for WETH.
    /// @param _newCompSwapFee The new comp swap fee (in UniswapV3 fee unit).
    function setCompSwapFee(uint24 _newCompSwapFee) external onlyOwner {
        if (_newCompSwapFee > MAX_UNISWAP_FEE) revert ExceedsMaxUniswapV3Fee(_newCompSwapFee);

        harvestConfig.compSwapFee = _newCompSwapFee;
        emit CompSwapFeeSet(_newCompSwapFee);
    }

    /// @notice Sets the fee taken by the UniswapV3Pool for swapping WETH for the underlying asset.
    /// @param _newAssetSwapFee The new asset swap fee (in UniswapV3 fee unit).
    function setAssetSwapFee(uint24 _newAssetSwapFee) external onlyOwner {
        if (_newAssetSwapFee > MAX_UNISWAP_FEE) revert ExceedsMaxUniswapV3Fee(_newAssetSwapFee);

        harvestConfig.assetSwapFee = _newAssetSwapFee;
        emit AssetSwapFeeSet(_newAssetSwapFee);
    }

    /// @notice Sets the fee taken by the claimer from the total amount of COMP rewards when harvesting the vault.
    /// @param _newHarvestingFee The new harvesting fee to set (in bps).
    function setHarvestingFee(uint16 _newHarvestingFee) external onlyOwner {
        if (_newHarvestingFee > MAX_BASIS_POINTS) revert ExceedsMaxBasisPoints(_newHarvestingFee);

        harvestConfig.harvestingFee = _newHarvestingFee;
        emit HarvestingFeeSet(_newHarvestingFee);
    }

    /// EXTERNAL ///

    /// @notice Harvests the vault: claims rewards from the underlying pool, swaps them for the underlying asset and supply them through Morpho.
    /// @return rewardsAmount The amount of rewards claimed, swapped then supplied through Morpho (in underlying).
    /// @return rewardsFee The amount of fees taken by the claimer (in underlying).
    function harvest() external returns (uint256 rewardsAmount, uint256 rewardsFee) {
        address assetMem = asset();
        address poolTokenMem = poolToken;
        address compMem = address(comp);
        HarvestConfig memory harvestConfigMem = harvestConfig;

        address[] memory poolTokens = new address[](1);
        poolTokens[0] = poolTokenMem;

        // Note: Uniswap pairs are considered to have enough market depth.
        // The amount swapped is considered low enough to avoid relying on any oracle.
        if (assetMem != compMem) {
            rewardsAmount = SWAP_ROUTER.exactInput(
                ISwapRouter.ExactInputParams({
                    path: isEth
                        ? abi.encodePacked(compMem, harvestConfigMem.compSwapFee, wEth)
                        : abi.encodePacked(
                            compMem,
                            harvestConfigMem.compSwapFee,
                            wEth,
                            harvestConfigMem.assetSwapFee,
                            assetMem
                        ),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: morpho.claimRewards(poolTokens, false),
                    amountOutMinimum: 0
                })
            );
        } else rewardsAmount = morpho.claimRewards(poolTokens, false);

        if (harvestConfigMem.harvestingFee > 0) {
            unchecked {
                rewardsFee = rewardsAmount.percentMul(harvestConfigMem.harvestingFee);
                rewardsAmount -= rewardsFee;
            }
        }

        morpho.supply(poolTokenMem, address(this), rewardsAmount);
        if (rewardsFee > 0) ERC20(assetMem).safeTransfer(msg.sender, rewardsFee);

        emit Harvested(msg.sender, rewardsAmount, rewardsFee);
    }

    /// GETTERS ///

    function compSwapFee() external view returns (uint24) {
        return harvestConfig.compSwapFee;
    }

    function assetSwapFee() external view returns (uint24) {
        return harvestConfig.assetSwapFee;
    }

    function harvestingFee() external view returns (uint16) {
        return harvestConfig.harvestingFee;
    }
}