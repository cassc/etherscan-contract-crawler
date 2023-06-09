// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/interfaces/IERC20.sol";
import "@openzeppelin/interfaces/IERC721.sol";
import "@openzeppelin/interfaces/IERC1155.sol";
import "@openzeppelin/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/introspection/ERC165Checker.sol";

import "@MT/interfaces/ICryptoKitties.sol";


library MultiToken {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    bytes4 public constant ERC20_INTERFACE_ID = 0x36372b07;
    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 public constant CRYPTO_KITTIES_INTERFACE_ID = 0x9a20483d;

    /**
     * @title Category
     * @dev Enum representation Asset category.
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155,
        CryptoKitties
    }

    /**
     * @title Asset
     * @param category Corresponding asset category.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id TokenID of an NFT or 0.
     * @param amount Amount of fungible tokens or 0 -> 1.
     */
    struct Asset {
        Category category;
        address assetAddress;
        uint256 id;
        uint256 amount;
    }


    /*----------------------------------------------------------*|
    |*  # FACTORY FUNCTIONS                                     *|
    |*----------------------------------------------------------*/

    function ERC20(address assetAddress, uint256 amount) internal pure returns (Asset memory) {
        return Asset(Category.ERC20, assetAddress, 0, amount);
    }

    function ERC721(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.ERC721, assetAddress, id, 0);
    }

    function ERC1155(address assetAddress, uint256 id, uint256 amount) internal pure returns (Asset memory) {
        return Asset(Category.ERC1155, assetAddress, id, amount);
    }

    function ERC1155(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.ERC1155, assetAddress, id, 0);
    }

    function CryptoKitties(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.CryptoKitties, assetAddress, id, 0);
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetFrom
     * @dev Wrapping function for `transferFrom` calls on various token interfaces.
     *      If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, false);
    }

    /**
     * safeTransferAssetFrom
     * @dev Wrapping function for `safeTransferFrom` calls on various token interfaces.
     *      If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, true);
    }

    function _transferAssetFrom(Asset memory asset, address source, address dest, bool isSafe) private {
        if (asset.category == Category.ERC20) {
            if (source == address(this))
                IERC20(asset.assetAddress).safeTransfer(dest, asset.amount);
            else
                IERC20(asset.assetAddress).safeTransferFrom(source, dest, asset.amount);

        } else if (asset.category == Category.ERC721) {
            if (!isSafe)
                IERC721(asset.assetAddress).transferFrom(source, dest, asset.id);
            else
                IERC721(asset.assetAddress).safeTransferFrom(source, dest, asset.id, "");

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).safeTransferFrom(source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, "");

        } else if (asset.category == Category.CryptoKitties) {
            if (source == address(this))
                ICryptoKitties(asset.assetAddress).transfer(dest, asset.id);
            else
                ICryptoKitties(asset.assetAddress).transferFrom(source, dest, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * getTransferAmount
     * @dev Get amount of asset that would be transferred.
     *      NFTs (ERC721, CryptoKitties & ERC1155 with amount 0) with return 1.
     *      Fungible tokens will return its amount (ERC20 with 0 amount is valid state).
     *      In combination with `MultiToken.balanceOf`, `getTransferAmount` can be used to check successful asset transfer.
     * @param asset Struct defining all necessary context of a token.
     * @return Number of tokens that would be transferred of the asset.
     */
    function getTransferAmount(Asset memory asset) internal pure returns (uint256) {
        if (asset.category == Category.ERC20)
            return asset.amount;
        else if (asset.category == Category.ERC1155 && asset.amount > 0)
            return asset.amount;
        else // Return 1 for ERC721, CryptoKitties and ERC1155 used as NFTs (amount = 0)
            return 1;
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET CALLDATA                               *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetFromCalldata
     * @dev Wrapping function for `transferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, false);
    }

    /**
     * safeTransferAssetFromCalldata
     * @dev Wrapping function for `safeTransferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, true);
    }

    function _transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender, bool isSafe) pure private returns (bytes memory) {
        if (asset.category == Category.ERC20) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)", dest, asset.amount
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.amount
                );
            }
        } else if (asset.category == Category.ERC721) {
            if (!isSafe) {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,bytes)", source, dest, asset.id, ""
                );
            }

        } else if (asset.category == Category.ERC1155) {
            return abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)", source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, ""
            );

        } else if (asset.category == Category.CryptoKitties) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)", dest, asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.id
                );
            }

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * permit
     * @dev Wrapping function for granting approval via permit signature.
     * @param asset Struct defining all necessary context of a token.
     * @param owner Account/address that signed the permit.
     * @param spender Account/address that would be granted approval to `asset`.
     * @param permitData Data about permit deadline (uint256) and permit signature (64/65 bytes).
     *                   Deadline and signature should be pack encoded together.
     *                   Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(Asset memory asset, address owner, address spender, bytes memory permitData) internal {
        if (asset.category == Category.ERC20) {

            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (permitData.length == 97) {
                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    s := mload(add(permitData, 0x60))
                    v := byte(0, mload(add(permitData, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (permitData.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    vs := mload(add(permitData, 0x60))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert("MultiToken::Permit: Invalid permit length");
            }

            // Call permit with parsed parameters
            IERC20Permit(asset.assetAddress).permit(owner, spender, asset.amount, deadline, v, r, s);

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
     * @dev Wrapping function for checking balances on various token interfaces.
     * @param asset Struct defining all necessary context of a token.
     * @param target Target address to be checked.
     */
    function balanceOf(Asset memory asset, address target) internal view returns (uint256) {
        if (asset.category == Category.ERC20) {
            return IERC20(asset.assetAddress).balanceOf(target);

        } else if (asset.category == Category.ERC721) {
            return IERC721(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else if (asset.category == Category.ERC1155) {
            return IERC1155(asset.assetAddress).balanceOf(target, asset.id);

        } else if (asset.category == Category.CryptoKitties) {
            return ICryptoKitties(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * approveAsset
     * @dev Wrapping function for `approve` calls on various token interfaces.
     *      By using `safeApprove` for ERC20, caller can set allowance to 0 or from 0.
     *      Cannot set non-zero value if allowance is also non-zero.
     * @param asset Struct defining all necessary context of a token.
     * @param target Account/address that would be granted approval to `asset`.
     */
    function approveAsset(Asset memory asset, address target) internal {
        if (asset.category == Category.ERC20) {
            IERC20(asset.assetAddress).safeApprove(target, asset.amount);

        } else if (asset.category == Category.ERC721) {
            IERC721(asset.assetAddress).approve(target, asset.id);

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).setApprovalForAll(target, true);

        } else if (asset.category == Category.CryptoKitties) {
            ICryptoKitties(asset.assetAddress).approve(target, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

    /**
     * isValid
     * @dev Checks that provided asset is contract, has correct format and stated category.
     *      Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param asset Asset that is examined.
     * @return True if assets amount and id is valid in stated category.
     */
    function isValid(Asset memory asset) internal view returns (bool) {
        if (asset.category == Category.ERC20) {
            // Check format
            if (asset.id != 0)
                return false;

            // ERC20 has optional ERC165 implementation
            if (asset.assetAddress.supportsERC165()) {
                // If ERC20 implements ERC165, it has to return true for its interface id
                return asset.assetAddress.supportsERC165InterfaceUnchecked(ERC20_INTERFACE_ID);

            } else {
                // In case token doesn't implement ERC165, its safe to assume that provided category is correct,
                // because any other category have to implement ERC165.

                // Check that asset address is contract
                // Tip: asset address will return code length 0, if this code is called from the asset constructor
                return asset.assetAddress.code.length > 0;
            }

        } else if (asset.category == Category.ERC721) {
            // Check format
            if (asset.amount != 0)
                return false;

            // Check it's ERC721 via ERC165
            return asset.assetAddress.supportsInterface(ERC721_INTERFACE_ID);

        } else if (asset.category == Category.ERC1155) {
            // Check it's ERC1155 via ERC165
            return asset.assetAddress.supportsInterface(ERC1155_INTERFACE_ID);

        } else if (asset.category == Category.CryptoKitties) {
            // Check format
            if (asset.amount != 0)
                return false;

            // Check it's CryptoKitties via ERC165
            return asset.assetAddress.supportsInterface(CRYPTO_KITTIES_INTERFACE_ID);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }

    /**
     * isSameAs
     * @dev Compare two assets, ignoring their amounts.
     * @param asset First asset to examine.
     * @param otherAsset Second asset to examine.
     * @return True if both structs represents the same asset.
     */
    function isSameAs(Asset memory asset, Asset memory otherAsset) internal pure returns (bool) {
        return
            asset.category == otherAsset.category &&
            asset.assetAddress == otherAsset.assetAddress &&
            asset.id == otherAsset.id;
    }
}