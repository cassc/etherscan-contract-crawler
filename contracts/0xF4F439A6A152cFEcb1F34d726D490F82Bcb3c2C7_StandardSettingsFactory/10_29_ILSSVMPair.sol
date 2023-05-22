// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILSSVMPair {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function getAssetRecipient() external returns (address);

    function getFeeRecipient() external returns (address);

    function changeAssetRecipient(address payable newRecipient) external;

    function poolType() external view returns (PoolType);

    function token() external view returns (ERC20 _token);

    function changeFee(uint96 newFee) external;

    function changeSpotPrice(uint128 newSpotPrice) external;

    function changeDelta(uint128 newDelta) external;

    function getBuyNFTQuote(uint256 assetId, uint256 numItems)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee,
            uint256 royaltyAmount
        );

    function getSellNFTQuote(uint256 assetId, uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee,
            uint256 royaltyAmount
        );

    function bondingCurve() external view returns (ICurve);

    function fee() external view returns (uint96);

    function nft() external view returns (address);

    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    function multicall(bytes[] calldata calls, bool revertOnFail) external;
}