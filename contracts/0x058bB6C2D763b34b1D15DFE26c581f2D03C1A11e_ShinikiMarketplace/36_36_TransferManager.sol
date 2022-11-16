// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./lib/LibAsset.sol";
import "./lib/LibFill.sol";
import "./lib/LibFeeSide.sol";
import "./interfaces/ITransferManager.sol";
import "./TransferExecutor.sol";
import "./lib/BpLibrary.sol";

abstract contract TransferManager is Initializable, ITransferManager {
    using BpLibrary for uint256;
    using SafeMathUpgradeable for uint256;

    LibPart.Part[] private feeOrigins;

    function __TransferManager_init_unchained() internal initializer {}

    function encode(LibOrderData.Data memory data)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(data);
    }

    function encodeNFT(LibPart.Part[] memory royalties)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(royalties);
    }

    // doTransfers
    function doTransfers(
        LibAsset.AssetType memory makeMatch,
        LibAsset.AssetType memory takeMatch,
        LibFill.FillResult memory fill,
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        LibOrderData.Data memory leftData,
        LibOrderData.Data memory rightData
    )
        internal
        override
    {
        LibFeeSide.FeeSide feeSide = LibFeeSide.getFeeSide(
            makeMatch.assetClass,
            takeMatch.assetClass
        );
        if (feeSide == LibFeeSide.FeeSide.MAKE) {
            doTransfersWithFees(
                fill.leftValue,
                leftOrder.maker,
                leftData,
                makeMatch,
                takeMatch
            );
            transfer(
                LibAsset.Asset(
                    takeMatch,
                    fill.rightValue,
                    leftOrder.makeAsset.token,
                    leftOrder.makeAsset.tokenId
                ),
                rightOrder.maker,
                leftData.recipient
            );
        } else if (feeSide == LibFeeSide.FeeSide.TAKE) {
            doTransfersWithFees(
                fill.rightValue,
                rightOrder.maker,
                leftData,
                takeMatch,
                makeMatch
            );
            transfer(
                LibAsset.Asset(
                    makeMatch,
                    fill.leftValue,
                    leftOrder.makeAsset.token,
                    leftOrder.makeAsset.tokenId
                ),
                leftOrder.maker,
                rightData.recipient
            );
        } else {
            revert("doTransfer is invalid");
        }
    }

    function doTransfersWithFees(
        uint256 amount,
        address from,
        LibOrderData.Data memory data,
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft
    ) internal {
        uint256 rest = amount;
        // royalties
        rest = transferRoyalties(matchCalculate, matchNft, rest, amount, from);

        // trading fee
        (rest, ) = transferFees(
            matchCalculate,
            rest,
            amount,
            data.originFees,
            from
        );

        // receiver
        transferPayouts(matchCalculate, rest, from, data.recipient);
    }

    function transferRoyalties(
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        uint256 rest,
        uint256 amount,
        address from
    ) internal returns (uint256) {
        LibPart.Part[] memory fees = getRoyaltiesByAssetType(matchNft);

        (uint256 result, uint256 totalRoyalties) = transferFees(
            matchCalculate,
            rest,
            amount,
            fees,
            from
        );
        require(totalRoyalties <= 1000, "Royalties are too high (>10%)");
        return result;
    }

    function getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
        internal
        pure
        returns (LibPart.Part[] memory royalties)
    {
        (royalties) = abi.decode(matchNft.data, (LibPart.Part[]));

        return royalties;
    }

    function transferFees(
        LibAsset.AssetType memory matchCalculate,
        uint256 rest,
        uint256 amount,
        LibPart.Part[] memory fees,
        address from
    ) internal returns (uint256, uint256) {
        uint256 totalFees = 0;
        uint256 restValue = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            (uint256 newRestValue, uint256 feeValue) = subFeeInBp(
                restValue,
                amount,
                fees[i].value
            );
            restValue = newRestValue;
            if (feeValue > 0) {
                transfer(
                    LibAsset.Asset(matchCalculate, feeValue, address(0), 0),
                    from,
                    fees[i].account
                );
            }
        }
        return (restValue, totalFees);
    }

    function transferPayouts(
        LibAsset.AssetType memory matchCalculate,
        uint256 amount,
        address from,
        address recipient
    ) internal {
        uint256 currentAmount = amount.bp(10000);
        if (currentAmount > 0) {
            transfer(
                LibAsset.Asset(matchCalculate, currentAmount, address(0), 0),
                from,
                recipient
            );
        }
    }

    function subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }
}