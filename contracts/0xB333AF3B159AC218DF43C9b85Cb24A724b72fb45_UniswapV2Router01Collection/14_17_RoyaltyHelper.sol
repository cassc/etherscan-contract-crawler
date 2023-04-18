// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC2981 } from "../interfaces/IERC2981.sol";

library RoyaltyHelper {
    bytes4 constant IERC2981_INTERFACE_ID = 0x2a55205a;

    function getRoyaltyInfo(address collection, uint[] memory tokenIds, uint totalAmount, address marketplaceWallet, uint marketplaceFee, uint256 royaltyFeeCap) internal view returns (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) {
        bool implementsIERC2981;
        try IERC165(collection).supportsInterface(IERC2981_INTERFACE_ID) returns (bool result) { implementsIERC2981 = result; } catch { implementsIERC2981 = false; }
        totalRoyaltyAmount = 0;
        if (!implementsIERC2981) {
            if (marketplaceFee > 0) {
                royaltyReceivers = new address[](1);
                royaltyAmounts = new uint[](1);
                (royaltyReceivers[0], royaltyAmounts[0]) = (marketplaceWallet, totalAmount * marketplaceFee / 100e16);
                totalRoyaltyAmount += royaltyAmounts[0];
            } else {
                royaltyReceivers = new address[](0);
                royaltyAmounts = new uint[](0);
            }
        } else {
            if (marketplaceFee > 0) {
                royaltyReceivers = new address[](tokenIds.length + 1);
                royaltyAmounts = new uint[](tokenIds.length + 1);
            } else {
                royaltyReceivers = new address[](tokenIds.length);
                royaltyAmounts = new uint[](tokenIds.length);
            }
            {
                uint salePrice = totalAmount / tokenIds.length;
                for (uint i = 0; i < tokenIds.length; i++) {
                    (royaltyReceivers[i], royaltyAmounts[i]) = IERC2981(collection).royaltyInfo(tokenIds[i], salePrice);
                    totalRoyaltyAmount += royaltyAmounts[i];
                }
            }
            {
                uint maxRoyaltyAmount = totalAmount * royaltyFeeCap / 100e16;
                if (totalRoyaltyAmount > maxRoyaltyAmount) {
                    uint256 _scale = 100e16 * maxRoyaltyAmount / totalRoyaltyAmount;
                    totalRoyaltyAmount = 0;
                    for (uint i = 0; i < tokenIds.length; i++) {
                        royaltyAmounts[i] = royaltyAmounts[i] * _scale / 100e16;
                        totalRoyaltyAmount += royaltyAmounts[i];
                    }
                }
            }
            if (marketplaceFee > 0) {
                (royaltyReceivers[tokenIds.length], royaltyAmounts[tokenIds.length]) = (marketplaceWallet, totalAmount * marketplaceFee / 100e16);
                totalRoyaltyAmount += royaltyAmounts[tokenIds.length];
            }
        }
        return (royaltyReceivers, royaltyAmounts, totalRoyaltyAmount);
    }
}