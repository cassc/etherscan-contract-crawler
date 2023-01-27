// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/RouterStorage.sol";
import "../libraries/LibSrcCrossSwap.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SrcCrossSwapFacet {
    RouterStorage internal s;

    using SafeERC20 for IERC20;

    /**
     * @notice this method should be called only if cross-chain swap is more than 12 USDC and own liquidity is not enough
     *
     * @param crossSwapArgs source swap arguments (srcToken; srcAmount; destChainId; destToken; minDestAmount; destUser; connectorToken; refundAddress;)
     * @param srcSwapArgs swap provider where the swap from srcToken to connectedToken will be performed (provider,approveProxy)
     */
    function initCrossSwap(
        LibSrcCrossSwap.CrossSwapArgs calldata crossSwapArgs,
        LibSrcCrossSwap.SrcSwapArgs calldata srcSwapArgs
    ) external payable {
        require(s.whitelistedSwapProviders[srcSwapArgs.provider], "Swap provider is not whitelisted");
        require(s.whitelistedConnectorTokens[crossSwapArgs.connectorToken], "Connector token is not whitelisted");

        uint256 connectorTokenBalanceBeforeSwap = IERC20(crossSwapArgs.connectorToken).balanceOf(address(this));

        uint256 connectorTokenIncome;
        if (crossSwapArgs.connectorToken == crossSwapArgs.srcToken) {
            IERC20(crossSwapArgs.srcToken).safeTransferFrom(
                msg.sender,
                s.connectorTokenHolder[block.chainid],
                crossSwapArgs.srcAmount
            );
            connectorTokenIncome = crossSwapArgs.srcAmount;
        } else {
            LibSrcCrossSwap._executeSwap(
                srcSwapArgs.callData,
                crossSwapArgs.srcToken,
                crossSwapArgs.srcAmount,
                srcSwapArgs.provider,
                srcSwapArgs.approveProxy
            );

            uint256 connectorTokenBalanceAfterSwap = IERC20(crossSwapArgs.connectorToken).balanceOf(
                s.connectorTokenHolder[block.chainid]
            );
            connectorTokenIncome = connectorTokenBalanceAfterSwap - connectorTokenBalanceBeforeSwap;

            IERC20(crossSwapArgs.connectorToken).transfer(s.connectorTokenHolder[block.chainid], connectorTokenIncome);
        }

        require(connectorTokenIncome > 0, "Connector Token income should be positive");

        emit LibSrcCrossSwap.SrcCrossSwap(
            crossSwapArgs.srcToken,
            crossSwapArgs.srcAmount,
            crossSwapArgs.destChainId,
            crossSwapArgs.destToken,
            crossSwapArgs.minDestAmount,
            crossSwapArgs.destUser,
            crossSwapArgs.connectorToken,
            connectorTokenIncome,
            crossSwapArgs.refundAddress,
            "bitoftrade"
        );
    }
}