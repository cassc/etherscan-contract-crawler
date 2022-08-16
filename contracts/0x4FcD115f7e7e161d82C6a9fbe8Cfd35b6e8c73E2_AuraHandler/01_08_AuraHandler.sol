// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "HandlerBase.sol";

contract AuraHandler is HandlerBase {
    using SafeERC20 for IERC20;

    address public constant AURA_TOKEN =
        0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

    bytes32 private constant AURA_ETH_POOL_ID =
        0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;

    constructor(address _token, address _strategy)
        HandlerBase(_token, _strategy)
    {}

    /// @notice Set approvals for the contracts used when swapping & staking
    function setApprovals() external {
        IERC20(AURA_TOKEN).safeApprove(BAL_VAULT, 0);
        IERC20(AURA_TOKEN).safeApprove(BAL_VAULT, type(uint256).max);
    }

    /// @notice Swap Aura for WETH on Balancer
    /// @param _amount - amount to swap
    function _swapAuraToWEth(uint256 _amount) internal {
        IBalancerVault.SingleSwap memory _auraSwapParams = IBalancerVault
            .SingleSwap({
                poolId: AURA_ETH_POOL_ID,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(AURA_TOKEN),
                assetOut: IAsset(WETH_TOKEN),
                amount: _amount,
                userData: new bytes(0)
            });

        balVault.swap(
            _auraSwapParams,
            _createSwapFunds(),
            0,
            block.timestamp + 1
        );
    }

    function sell() external override onlyStrategy {
        _swapAuraToWEth(IERC20(AURA_TOKEN).balanceOf(address(this)));
        IERC20(WETH_TOKEN).safeTransfer(
            strategy,
            IERC20(WETH_TOKEN).balanceOf(address(this))
        );
    }
}