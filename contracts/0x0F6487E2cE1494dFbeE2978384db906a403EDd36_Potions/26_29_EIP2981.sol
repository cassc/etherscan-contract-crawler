// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Guard.sol";

/**
@title The royalties base contract
@author Ilya A. Shlyakhovoy
@notice This contract manage properties of the game actor, including birth and childhood.
The new actor comes from the Breed or Box contracts
 */

abstract contract EIP2981 is ERC2981, Guard {
    event FeeChanged(
        address indexed receiver,
        uint96 collectionOwnerFeeNumerator,
        uint96 firstOwnerFeeNumerator
    );

    struct AdditionalRoyaltyInfo {
        uint96 collectionOwnerFeeNumerator;
        uint96 firstOwnerFeeNumerator;
    }

    AdditionalRoyaltyInfo private _additionalDefaultRoyaltyInfo;

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function feeDenominator() external pure returns (uint96) {
        return _feeDenominator();
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `collectionOwnerFeeNumerator` + `firstOwnerFeeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 collectionOwnerFeeNumerator,
        uint96 firstOwnerFeeNumerator
    ) external haveRights {
        _setDefaultRoyalty(
            receiver,
            collectionOwnerFeeNumerator + firstOwnerFeeNumerator
        );

        _additionalDefaultRoyaltyInfo = _additionalDefaultRoyaltyInfo = AdditionalRoyaltyInfo(
            collectionOwnerFeeNumerator,
            firstOwnerFeeNumerator
        );
        emit FeeChanged(
            receiver,
            collectionOwnerFeeNumerator,
            firstOwnerFeeNumerator
        );
    }

    /**
     * @dev Returns amount of shares which should receive each party.
     */
    function additionalDefaultRoyaltyInfo()
        external
        view
        returns (AdditionalRoyaltyInfo memory)
    {
        return _additionalDefaultRoyaltyInfo;
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external haveRights {
        _deleteDefaultRoyalty();
        delete _additionalDefaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external haveRights {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) external haveRights {
        _resetTokenRoyalty(tokenId);
    }
}