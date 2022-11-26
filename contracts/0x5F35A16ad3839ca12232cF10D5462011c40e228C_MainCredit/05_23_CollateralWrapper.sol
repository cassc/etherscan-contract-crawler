// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../utils/TermData.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "erc721a/contracts/IERC721A.sol";

/**
 * @title CollateralWrapper
 * @author
 * @notice
 */
contract CollateralWrapper is TermData {
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function _safeNFTTransferFrom(
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType,
        address _from,
        address _to
    ) internal {
        if (_collateralType == CollateralType.ERC721) {
            IERC721 collateralWrapper = IERC721(_collateralAddress);
            collateralWrapper.safeTransferFrom(_from, _to, _collateralId);
        } else if (_collateralType == CollateralType.ERC721A) {
            IERC721A collateralWrapper = IERC721A(_collateralAddress);
            collateralWrapper.safeTransferFrom(_from, _to, _collateralId);
        } else if (_collateralType == CollateralType.ERC1155) {
            IERC1155 collateralWrapper = IERC1155(_collateralAddress);
            uint256 amount = collateralWrapper.balanceOf(_from, _collateralId);
            return
                collateralWrapper.safeTransferFrom(
                    _from,
                    _to,
                    _collateralId,
                    amount,
                    ""
                );
        }
    }

    function _getNFTApproved(
        address _owner,
        address _collateralAddress,
        CollateralType _collateralType
    ) internal view returns (bool) {
        if (_collateralType == CollateralType.ERC721) {
            IERC721 collateralWrapper = IERC721(_collateralAddress);
            return
                collateralWrapper.isApprovedForAll(_owner, address(this));
        } else if (_collateralType == CollateralType.ERC721A) {
            IERC721A collateralWrapper = IERC721A(_collateralAddress);
            return
                collateralWrapper.isApprovedForAll(_owner, address(this));
        } else if (_collateralType == CollateralType.ERC1155) {
            IERC1155 collateralWrapper = IERC1155(_collateralAddress);
            return
                collateralWrapper.isApprovedForAll(_owner, address(this));
        }
        return false;
    }

    function _haveNFTOwnership(
        address _owner,
        address _collateralAddress,
        uint256 _collateralId,
        CollateralType _collateralType
    ) internal view returns (bool) {
        if (_collateralType == CollateralType.ERC721) {
            IERC721 collateralWrapper = IERC721(_collateralAddress);
            return _owner == collateralWrapper.ownerOf(_collateralId);
        } else if (_collateralType == CollateralType.ERC721A) {
            IERC721A collateralWrapper = IERC721A(_collateralAddress);
            return _owner == collateralWrapper.ownerOf(_collateralId);
        } else if (_collateralType == CollateralType.ERC1155) {
            IERC1155 collateralWrapper = IERC1155(_collateralAddress);
            return collateralWrapper.balanceOf(_owner, _collateralId) > 0;
        }
        return false;
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}