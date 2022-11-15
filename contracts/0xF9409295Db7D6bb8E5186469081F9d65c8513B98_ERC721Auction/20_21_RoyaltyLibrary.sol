// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library RoyaltyLibrary {
    bytes4 private constant INTERFACE_SIGNATURE_ERC2981 = 0x2a55205a;

    event RoyaltiesPaid(address contractAddr, uint256 tokenId, uint256 royalty);

    function hasRoyalty(address contractAddr) internal view returns (bool) {
        return
            IERC2981(contractAddr).supportsInterface(
                INTERFACE_SIGNATURE_ERC2981
            );
    }

    function _transferFund(
        address tokenContractAddr,
        uint256 price,
        address destination
    ) internal {
        if (tokenContractAddr == address(0)) {
            payable(destination).transfer(price);
        } else {
            IERC20(tokenContractAddr).transfer(destination, price);
        }
    }

    function deduceRoyalties(
        address contractAddr,
        uint256 tokenId,
        address tokenContractAddr,
        uint256 salePrice
    ) internal returns (uint256 realSaleAmount) {
        (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(
            contractAddr
        ).royaltyInfo(tokenId, salePrice);
        realSaleAmount = salePrice - royaltiesAmount;
        if (royaltiesAmount > 0) {
            _transferFund(
                tokenContractAddr,
                royaltiesAmount,
                royaltiesReceiver
            );
        }
        emit RoyaltiesPaid(contractAddr, tokenId, royaltiesAmount);
    }
}