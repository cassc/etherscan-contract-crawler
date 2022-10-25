// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// External
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { ImmutableModule } from "../../shared/ImmutableModule.sol";
import { ICowSettlement } from "../../peripheral/Cowswap/ICowSettlement.sol";
import { DexSwapData, IDexAsyncSwap } from "../../interfaces/IDexSwap.sol";

/**
 * @title   CowSwapDex allows to swap tokens between via CowSwap.
 * @author  mStable
 * @notice
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-17
 */
contract CowSwapDex is ImmutableModule, IDexAsyncSwap {
    using SafeERC20 for IERC20;

    /// @notice Contract GPv2VaultRelayer to give allowance to perform swaps
    address public immutable RELAYER;

    /// @notice GPv2Settlement contract
    ICowSettlement public immutable SETTLEMENT;

    /// @notice Event emitted when a order is cancelled.
    event SwapCancelled(bytes indexed orderUid);

    /**
     * @param _nexus  Address of the Nexus contract that resolves protocol modules and roles.
     * @param _relayer  Address of the GPv2VaultRelayer contract to set allowance to perform swaps
     * @param _settlement  Address of the GPv2Settlement contract that pre-signs orders.
     */
    constructor(
        address _nexus,
        address _relayer,
        address _settlement
    ) ImmutableModule(_nexus) {
        RELAYER = _relayer;
        SETTLEMENT = ICowSettlement(_settlement);
    }

    /**
     * @dev Modifier to allow function calls only from the Liquidator or the Keeper EOA.
     */
    modifier onlyKeeperOrLiquidator() {
        _keeperOrLiquidator();
        _;
    }

    function _keeperOrLiquidator() internal view {
        require(
            msg.sender == _keeper() || msg.sender == _liquidatorV2(),
            "Only keeper or liquidator"
        );
    }

    /***************************************
                    Core
    ****************************************/

    /**
     * @notice Initialises a cow swap order.
     * @dev This function is used in order to be compliant with IDexSwap interface.
     * @param swapData The data of the swap {fromAsset, toAsset, fromAssetAmount, fromAssetFeeAmount, data}.
     */
    function _initiateSwap(DexSwapData memory swapData) internal {
        // unpack the CowSwap specific params from the generic swap.data field
        (bytes memory orderUid, bool transfer) = abi.decode(swapData.data, (bytes, bool));

        if (transfer) {
            // transfer in the fromAsset
            require(
                IERC20(swapData.fromAsset).balanceOf(msg.sender) >= swapData.fromAssetAmount,
                "not enough from assets"
            );
            // Transfer rewards from the liquidator
            IERC20(swapData.fromAsset).safeTransferFrom(
                msg.sender,
                address(this),
                swapData.fromAssetAmount
            );
        }

        // sign the order on-chain so the order will happen
        SETTLEMENT.setPreSignature(orderUid, true);
    }

    /**
     * @notice Initialises a cow swap order.
     * @dev Orders must be created off-chain.
     * In case that an order fails, a new order uid is created there is no need to transfer "fromAsset".
     * @param swapData The data of the swap {fromAsset, toAsset, fromAssetAmount, fromAssetFeeAmount, data}.
     */
    function initiateSwap(DexSwapData calldata swapData) external override onlyKeeperOrLiquidator {
        _initiateSwap(swapData);
    }

    /**
     * @notice Initiate cow swap orders in bulk.
     * @dev Orders must be created off-chain.
     * @param swapsData Array of swap data {fromAsset, toAsset, fromAssetAmount, fromAssetFeeAmount, data}.
     */
    function initiateSwaps(DexSwapData[] calldata swapsData) external onlyKeeperOrLiquidator {
        uint256 len = swapsData.length;
        for (uint256 i = 0; i < len; ) {
            _initiateSwap(swapsData[i]);
            // Increment index with low gas consumption, no need to check for overflow.
            unchecked {
                i += 1;
            }
        }
    }

    /**
     * @notice It reverts as cowswap allows to provide a "receiver" while creating an order. Therefore
     * @dev  The method is kept to have compatibility with IDexAsyncSwap.
     */
    function settleSwap(DexSwapData memory) external pure {
        revert("!not supported");
    }

    /**
     * @notice Allows to cancel a cowswap order perhaps if it took too long or was with invalid parameters
     * @dev  This function performs no checks, there's a high change it will revert if you send it with fluff parameters
     * Emits the `SwapCancelled` event with the `orderUid`.
     * @param orderUid The order uid of the swap.
     */
    function cancelSwap(bytes calldata orderUid) external override onlyKeeperOrLiquidator {
        SETTLEMENT.setPreSignature(orderUid, false);
    }

    /**
     * @notice Cancels cow swap orders in bulk.
     * @dev  It invokes the `cancelSwap` function for each order in the array.
     * For each order uid it emits the `SwapCancelled` event with the `orderUid`.
     * @param orderUids Array of swaps order uids
     */
    function cancelSwaps(bytes[] calldata orderUids) external onlyKeeperOrLiquidator {
        uint256 len = orderUids.length;
        for (uint256 i = 0; i < len; ) {
            SETTLEMENT.setPreSignature(orderUids[i], false);
            // Increment index with low gas consumption, no need to check for overflow.
            unchecked {
                i += 1;
            }
        }
    }

    /**
     * @notice Approves a token to be sold using cow swap.
     * @dev this approves the cow swap router to transfer the specified token from this contract.
     * @param token Address of the token that is to be sold.
     */
    function approveToken(address token) external onlyGovernor {
        IERC20(token).safeApprove(RELAYER, type(uint256).max);
    }

    /**
     * @notice Revokes cow swap from selling a token.
     * @dev this removes the allowance for the cow swap router to transfer the specified token from this contract.
     * @param token Address of the token that is to no longer be sold.
     */
    function revokeToken(address token) external onlyGovernor {
        IERC20(token).safeApprove(RELAYER, 0);
    }

    /**
     * @notice Rescues tokens from the contract in case of a cancellation or failure and sends it to governor.
     * @dev only governor can invoke.
     * Even if a swap fails, the order can be created again and keep trying, rescueToken must be the last resource,
     * ie, cowswap is not availabler for N hours.
     */
    function rescueToken(address _erc20, uint256 amount) external onlyGovernor {
        IERC20(_erc20).safeTransfer(_governor(), amount);
    }
}