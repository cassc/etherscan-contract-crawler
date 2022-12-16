// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IRouter} from "./IRouter.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILSSVMPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(IRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
    
    function createPairETH(
        address _nft,
        address _bondingCurve,
        address payable _assetRecipient,
        uint8 _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (address pair);
 function sisterFactory() external returns (address payable);
 function depositNFTs(
        IERC721 _nft,
        uint256[] calldata ids,
        address recipient
    )  external;
    function requestNFTTransferFrom(IERC721 _nft,address from, address recipient, uint256 id) external;
}