// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC2981} from "./../interfaces/IERC2981.sol";
import {ERC2981Storage} from "./../libraries/ERC2981Storage.sol";
import {ContractOwnershipStorage} from "./../../../access/libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC2981 NFT Royalty Standard (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract ERC2981Base is Context, IERC2981 {
    using ERC2981Storage for ERC2981Storage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    uint256 public constant ROYALTY_FEE_DENOMINATOR = ERC2981Storage.ROYALTY_FEE_DENOMINATOR;

    /// @notice Sets the royalty percentage.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts with IncorrectRoyaltyPercentage if `percentage` is above 100% (> FEE_DENOMINATOR).
    /// @param percentage The new percentage to set. For example 50000 sets 50% royalty.
    function setRoyaltyPercentage(uint256 percentage) external {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        ERC2981Storage.layout().setRoyaltyPercentage(percentage);
    }

    /// @notice Sets the royalty receiver.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts with IncorrectRoyaltyReceiver if `receiver` is the zero address.
    /// @param receiver The new receiver to set.
    function setRoyaltyReceiver(address receiver) external {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        ERC2981Storage.layout().setRoyaltyReceiver(receiver);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return ERC2981Storage.layout().royaltyInfo(tokenId, salePrice);
    }
}