// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import ".././interfaces/ICSMCrossChainRouterL0.sol";

interface IPoolCrossChainL0 {
    struct SwapRequest {
        address fromToken;
        uint256 fromAmount;
        uint256 minimumToAmount;
        uint256 destinationAsset;
        uint16 destinationChain;
        uint256 deadline;
        bytes signature;
    }

    function chainId() external view returns (uint16);

    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swapCrossChain(SwapRequest calldata requestParams_)
        external
        payable
        returns (uint256 actualToAmount, uint256 haircut);

    function receiveSwapCrossChain(ICSMCrossChainRouterL0.CCReceiveParams memory params) external;

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 destinationAsset,
        uint16 destinationChain
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function getTokenAddresses() external view returns (address[] memory);
}