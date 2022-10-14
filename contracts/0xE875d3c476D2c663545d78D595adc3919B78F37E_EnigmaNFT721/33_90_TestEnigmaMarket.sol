// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../market/EnigmaMarket.sol";
import "../ERC721/EnigmaNFT721.sol";
import "../market/utils/PlatformFees.sol";

/// @title TestEnigmaMarket
///
/// @dev This contract extends from Trade Series for upgradeablity testing

contract TestEnigmaMarket is EnigmaMarket {
    uint256 public aNewValue;

    /// @dev makes internal storage visible
    function getMaxDuration() external view returns (uint256) {
        return maxDuration;
    }

    /// @dev makes internal storage visible
    function getMinDuration() external view returns (uint256) {
        return minDuration;
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