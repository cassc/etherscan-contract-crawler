// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IERC721 {}

interface ICurve {}

interface LSSVMPair {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function changeSpotPrice(uint128 newSpotPrice) external;
    function spotPrice() external view returns (uint128 spotPrice);
    function changeDelta(uint128 newDelta) external;
    function delta() external view returns (uint128 delta);
}

interface LSSVMPairETH is LSSVMPair {
    function withdrawAllETH() external;
}

interface ILSSVMPairFactory {
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        LSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (LSSVMPairETH pair);
}

interface ILSSVMRouter {
    struct PairSwapAny {
        LSSVMPair pair;
        uint256 numItems;
    }

    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable returns (uint256 remainingValue);
}