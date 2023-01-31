// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../market/EnigmaMarket.sol";
import "../ERC721/EnigmaNFT721.sol";

/// @title TestEnigmaMarket
///
/// @dev This contract extends from Trade Series for upgradeablity testing

contract TestEnigmaMarket is EnigmaMarket {
    uint256 public aNewValue;

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EnigmaMarket(name, version) {}

    /// @dev makes internal storage visible
    function getMaxDuration() external view returns (uint256) {
        return maxDuration;
    }

    /// @dev makes internal storage visible
    function getMinDuration() external view returns (uint256) {
        return minDuration;
    }

    /// @dev Check that fees add up without increasing costs in productive scenario
    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille,
        address seller
    ) internal view virtual override returns (FeeDistributionData memory) {
        FeeDistributionData memory feeDistributionData =
            super.getFees(paymentAmt, buyingAssetAddress, tokenId, sellerFeePermille, buyerFeePermille, seller);
        // Amount of "fees" sums up to the paid amount
        assert(
            feeDistributionData.fees.assetFee +
                feeDistributionData.fees.royaltyFee +
                feeDistributionData.fees.platformFee ==
                paymentAmt
        );
        // Outgoing transfers is the same as incoming one

        assert(
            feeDistributionData.toRightsHolder + feeDistributionData.toSeller + feeDistributionData.fees.platformFee ==
                paymentAmt
        );
        return feeDistributionData;
    }
}

contract TestAuctionSeller {
    bool public doFail;

    function doApprove(
        address enigmaNFT721,
        address transferProxy,
        uint256 tokenId
    ) public {
        EnigmaNFT721(enigmaNFT721).approve(transferProxy, tokenId);
    }

    function doCreateReserveAuction(
        address market,
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        PlatformFees calldata platformFees
    ) public {
        doFail = true;
        TestEnigmaMarket(market).createReserveAuction(nftContract, tokenId, duration, reservePrice, platformFees);
    }

    function doWithdrawTo(address market, address payable user) public {
        doFail = false;
        TestEnigmaMarket(market).withdrawTo(user);
    }

    function setDoFail(bool _doFail) public {
        doFail = _doFail;
    }

    /// receive fails on purpose to test this scenario
    receive() external payable {
        if (doFail) revert("test only");
    }
}