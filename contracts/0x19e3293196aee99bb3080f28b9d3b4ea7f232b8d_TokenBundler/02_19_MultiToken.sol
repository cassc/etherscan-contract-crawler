// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";


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
     * @param category Corresponding asset category
     * @param assetAddress Address of the token contract defining the asset
     * @param id TokenID of an NFT or 0
     * @param amount Amount of fungible tokens or 0 -> 1
     */
    struct Asset {
        Category category;
        address assetAddress;
        uint256 id;
        uint256 amount;
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * transferAsset
     * @dev wrapping function for transfer calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _dest Destination address
     */
    function transferAsset(Asset memory _asset, address _dest) internal {
        _transferAssetFrom(_asset, address(this), _dest);
    }

    /**
     * transferAssetFrom
     * @dev wrapping function for transferFrom calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFrom(Asset memory _asset, address _source, address _dest) internal {
        _transferAssetFrom(_asset, _source, _dest);
    }

    function _transferAssetFrom(Asset memory _asset, address _source, address _dest) private {
        if (_asset.category == Category.ERC20) {
            if (_source == address(this))
                require(IERC20(_asset.assetAddress).transfer(_dest, _asset.amount), "MultiToken: ERC20 transfer failed");
            else
                require(IERC20(_asset.assetAddress).transferFrom(_source, _dest, _asset.amount), "MultiToken: ERC20 transferFrom failed");

        } else if (_asset.category == Category.ERC721) {
            IERC721(_asset.assetAddress).safeTransferFrom(_source, _dest, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155(_asset.assetAddress).safeTransferFrom(_source, _dest, _asset.id, _asset.amount == 0 ? 1 : _asset.amount, "");

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET CALLDATA                               *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetCalldata
     * @dev wrapping function for transfer calldata on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that should initiate the transfer
     * @param _dest Destination address
     */
    function transferAssetCalldata(Asset memory _asset, address _source, address _dest) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(true, _asset, _source, _dest);
    }

    /**
     * transferAssetFromCalldata
     * @dev wrapping function for transferFrom calladata on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFromCalldata(Asset memory _asset, address _source, address _dest) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(false, _asset, _source, _dest);
    }

    function _transferAssetFromCalldata(bool fromSender, Asset memory _asset, address _source, address _dest) pure private returns (bytes memory) {
        if (_asset.category == Category.ERC20) {
            if (fromSender) {
                return abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    _dest, _asset.amount
                );
            } else {
                return abi.encodeWithSelector(
                    IERC20.transferFrom.selector,
                    _source, _dest, _asset.amount
                );
            }
        } else if (_asset.category == Category.ERC721) {
            return abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                _source, _dest, _asset.id
            );

        } else if (_asset.category == Category.ERC1155) {
            return abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                _source, _dest, _asset.id, _asset.amount == 0 ? 1 : _asset.amount, ""
            );


        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * permit
     * @dev wrapping function for granting approval via permit signature
     * @param _asset Struct defining all necessary context of a token
     * @param _owner Account/address that signed the permit
     * @param _spender Account/address that would be granted approval to `_asset`
     * @param _permit Data about permit deadline (uint256) and permit signature (64/65 bytes).
     * Deadline and signature should be pack encoded together.
     * Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(Asset memory _asset, address _owner, address _spender, bytes memory _permit) internal {
        if (_asset.category == Category.ERC20) {

            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (_permit.length == 97) {
                assembly {
                    deadline := mload(add(_permit, 0x20))
                    r := mload(add(_permit, 0x40))
                    s := mload(add(_permit, 0x60))
                    v := byte(0, mload(add(_permit, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (_permit.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(_permit, 0x20))
                    r := mload(add(_permit, 0x40))
                    vs := mload(add(_permit, 0x60))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert("MultiToken::Permit: Invalid permit length");
            }

            // Call permit with parsed parameters
            IERC20Permit(_asset.assetAddress).permit(_owner, _spender, _asset.amount, deadline, v, r, s);

        } else {
            // Currently supporting only ERC20 signed approvals via ERC2612
            revert("MultiToken::Permit: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    /**
     * balanceOf
     * @dev wrapping function for checking balances on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function balanceOf(Asset memory _asset, address _target) internal view returns (uint256) {
        if (_asset.category == Category.ERC20) {
            return IERC20(_asset.assetAddress).balanceOf(_target);

        } else if (_asset.category == Category.ERC721) {
            if (IERC721(_asset.assetAddress).ownerOf(_asset.id) == _target) {
                return 1;
            } else {
                return 0;
            }

        } else if (_asset.category == Category.ERC1155) {
            return IERC1155(_asset.assetAddress).balanceOf(_target, _asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * approveAsset
     * @dev wrapping function for approve calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Account/address that would be granted approval to `_asset`
     */
    function approveAsset(Asset memory _asset, address _target) internal {
        if (_asset.category == Category.ERC20) {
            IERC20(_asset.assetAddress).approve(_target, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721(_asset.assetAddress).approve(_target, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155(_asset.assetAddress).setApprovalForAll(_target, true);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

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
            _asset.category == _otherAsset.category &&
            _asset.assetAddress == _otherAsset.assetAddress &&
            _asset.id == _otherAsset.id;
    }
}