// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library MultiToken {

    /**
     * @title Category
     * @dev enum representation Asset category
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     * @title Asset
     * @param assetAddress Address of the token contract defining the asset
     * @param category Corresponding asset category
     * @param amount Amount of fungible tokens or 0 -> 1
     * @param id TokenID of an NFT or 0
     */
    struct Asset {
        address assetAddress;
        Category category;
        uint256 amount;
        uint256 id;
    }

    /**
     * transferAsset
     * @dev wrapping function for transfer calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _dest Destination address
     */
    function transferAsset(Asset memory _asset, address _dest) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.transfer(_dest, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.safeTransferFrom(address(this), _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            if (_asset.amount == 0) {
                _asset.amount = 1;
            }
            token.safeTransferFrom(address(this), _dest, _asset.id, _asset.amount, "");

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * transferAssetFrom
     * @dev wrapping function for transfer From calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFrom(Asset memory _asset, address _source, address _dest) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.transferFrom(_source, _dest, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.safeTransferFrom(_source, _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            if (_asset.amount == 0) {
                _asset.amount = 1;
            }
            token.safeTransferFrom(_source, _dest, _asset.id, _asset.amount, "");

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * balanceOf
     * @dev wrapping function for checking balances on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function balanceOf(Asset memory _asset, address _target) internal view returns (uint256) {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            return token.balanceOf(_target);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            if (token.ownerOf(_asset.id) == _target) {
                return 1;
            } else {
                return 0;
            }

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            return token.balanceOf(_target, _asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * approveAsset
     * @dev wrapping function for approve calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function approveAsset(Asset memory _asset, address _target) internal {
        if (_asset.category == Category.ERC20) {
            IERC20 token = IERC20(_asset.assetAddress);
            token.approve(_target, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721 token = IERC721(_asset.assetAddress);
            token.approve(_target, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155 token = IERC1155(_asset.assetAddress);
            token.setApprovalForAll(_target, true);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * isValid
     * @dev checks that assets amount and id is valid in stated category
     * @dev this function don't check that stated category is indeed the category of a contract on a stated address
     * @param _asset Asset that is examined
     * @return True if assets amount and id is valid in stated category
     */
    function isValid(Asset memory _asset) internal pure returns (bool) {
        // ERC20 token has to have id set to 0
        if (_asset.category == Category.ERC20 && _asset.id != 0)
            return false;

        // ERC721 token has to have amount set to 1
        if (_asset.category == Category.ERC721 && _asset.amount != 1)
            return false;

        // Any categories have to have non-zero amount
        if (_asset.amount == 0)
            return false;

        return true;
    }

    /**
     * isSameAs
     * @dev compare two assets, ignoring their amounts
     * @param _asset First asset to examine
     * @param _otherAsset Second asset to examine
     * @return True if both structs represents the same asset
     */
    function isSameAs(Asset memory _asset, Asset memory _otherAsset) internal pure returns (bool) {
        return
            _asset.assetAddress == _otherAsset.assetAddress &&
            _asset.category == _otherAsset.category &&
            _asset.id == _otherAsset.id;
    }
}