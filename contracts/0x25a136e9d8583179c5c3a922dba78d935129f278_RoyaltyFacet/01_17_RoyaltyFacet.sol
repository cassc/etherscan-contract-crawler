// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IRoyalty} from "../interfaces/IRoyalty.sol";
import {Base} from "../base/Base.sol";
import {LibTokenOwnership} from "../libraries/LibTokenOwnership.sol";
import {console2} from "forge-std/console2.sol";


/// @title RoyaltyFacet
/// @author Kfish n Chips
/// @notice Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
/// @dev Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
/// specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
///
/// Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
/// fee is specified in basis points by default.
///
/// @custom:security-contact [email protected]
contract RoyaltyFacet is Base, IRoyalty {

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// @dev Explain to a developer any extra details
    /// @param _receiver cannot be the zero address.
    /// @param _feeNumerator cannot be greater than the fee denominator.
    function setDefaultRoyalty(
            address _receiver, 
            uint256 _feeNumerator
        ) external {
        if(_feeNumerator > s.royaltyStorage.denominator) revert InvalidFeeNumerator();
        if(_receiver == address(0)) revert InvalidReceiver();

        s.royaltyStorage.receiver = _receiver;
        s.royaltyStorage.numerator = _feeNumerator;
    }

    // @notice Sets the royalty information that token ids.
    /// @dev to Resets royalty information set _feeNumerator to 0
    /// @param _tokenId the specific token id to Sets the royalty information for
    /// @param _feeNumerator cannot be greater than the fee denominator other case revert with InvalidFeeNumerator
    function setTokenRoyalty(
        uint256 _tokenId,
        uint256 _feeNumerator
    ) external {
        if(_feeNumerator > s.royaltyStorage.denominator) revert InvalidFeeNumerator();
        s.royaltyStorage.tokenNumerators[_tokenId] = _feeNumerator;
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        address owner = LibTokenOwnership.ownerOf(_tokenId);
        if(owner == address(0)) revert QueryNonExistentToken();
        uint256 numerator = s.royaltyStorage.tokenNumerators[_tokenId];
        console2.log(numerator);
        console2.log(s.royaltyStorage.denominator);
        console2.log(_salePrice);
        if(numerator == 0) {
            numerator = s.royaltyStorage.numerator;
            console2.log(numerator);
        }
        royaltyAmount = (_salePrice * numerator) / s.royaltyStorage.denominator;
        receiver = s.royaltyStorage.receiver;
    }
    
   
}