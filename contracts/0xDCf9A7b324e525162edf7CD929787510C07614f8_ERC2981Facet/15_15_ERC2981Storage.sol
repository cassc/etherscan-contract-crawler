// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC2981} from "./../interfaces/IERC2981.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC2981Storage {
    using ERC2981Storage for ERC2981Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        address royaltyReceiver;
        uint96 royaltyPercentage;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.royalty.ERC2981.storage")) - 1);

    uint256 internal constant ROYALTY_FEE_DENOMINATOR = 100000;

    error IncorrectRoyaltyPercentage(uint256 percentage);
    error IncorrectRoyaltyReceiver();

    /// @notice Marks the following ERC165 interface(s) as supported: ERC2981.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC2981).interfaceId, true);
    }

    /// @notice Sets the royalty percentage.
    /// @dev Reverts with IncorrectRoyaltyPercentage if `percentage` is above 100% (> FEE_DENOMINATOR).
    /// @param percentage The new percentage to set. For example 50000 sets 50% royalty.
    function setRoyaltyPercentage(Layout storage s, uint256 percentage) internal {
        if (percentage > ROYALTY_FEE_DENOMINATOR) {
            revert IncorrectRoyaltyPercentage(percentage);
        }
        s.royaltyPercentage = uint96(percentage);
    }

    /// @notice Sets the royalty receiver.
    /// @dev Reverts with IncorrectRoyaltyReceiver if `receiver` is the zero address.
    /// @param receiver The new receiver to set.
    function setRoyaltyReceiver(Layout storage s, address receiver) internal {
        if (receiver == address(0)) {
            revert IncorrectRoyaltyReceiver();
        }
        s.royaltyReceiver = receiver;
    }

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    // / @param tokenId The NFT asset queried for royalty information
    /// @param salePrice The sale price of the NFT asset specified by `tokenId`
    /// @return receiver Address of who should be sent the royalty payment
    /// @return royaltyAmount The royalty payment amount for `salePrice`
    function royaltyInfo(Layout storage s, uint256, uint256 salePrice) internal view returns (address receiver, uint256 royaltyAmount) {
        receiver = s.royaltyReceiver;
        uint256 royaltyPercentage = s.royaltyPercentage;
        if (salePrice == 0 || royaltyPercentage == 0) {
            royaltyAmount = 0;
        } else {
            if (salePrice < ROYALTY_FEE_DENOMINATOR) {
                royaltyAmount = (salePrice * royaltyPercentage) / ROYALTY_FEE_DENOMINATOR;
            } else {
                royaltyAmount = (salePrice / ROYALTY_FEE_DENOMINATOR) * royaltyPercentage;
            }
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}