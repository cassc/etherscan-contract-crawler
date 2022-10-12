// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface IPoolCrossChain {
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

    function swapCrossChain(
        address fromToken_,
        uint256 fromAmount_,
        uint256 minimumToAmount_,
        uint256 dstAssetId_,
        uint256 destinationChain_,
        uint256 deadline_,
        uint256 executionFee_
    )
        external
        payable
        returns (
            uint256 actualToAmount,
            uint256 haircut,
            uint256 nonce
        );

    function receiveSwapCrossChain(
        address sender_,
        uint256 srcChainId_,
        address srcAsset_,
        address dstAsset_,
        uint256 amount_,
        uint256 haircut_,
        uint256 nonce_
    ) external;

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 destinationAsset,
        uint256 destinationChain
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

    function getNoncePerChain(uint256 chainId_) external view returns (uint256);
}