// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ROJIStandardERC721A.sol";
import "erc721a/contracts/interfaces/IERC721ABurnable.sol";
import "erc721a/contracts/extensions/IERC4907A.sol";

/// @title ERC721A based NFT contract.
/// @author Martin Wawrusch for Roji Inc.
/// @dev
/// General
///
/// This contract interhits from {ROJIStandardERC721A} 
///
/// @custom:security-contact [email protected]
contract ROJIStandardERC721ARentable is ROJIStandardERC721A, // IMPORTANT MUST ALWAYS BE FIRST - NEVER CHANGE THAT
                                        IERC4907A
{

    // The bit position of `expires` in packed user info.
    uint256 private constant _BITPOS_EXPIRES = 160;

    // The interface ID for ERC4907 is `0xad092b5c`,
    // as defined in [ERC4907](https://eips.ethereum.org/EIPS/eip-4907).
    bytes4 private constant _INTERFACE_ID_ERC4907 = 0xad092b5c;

    // Mapping from token ID to user info.
    //
    // Bits Layout:
    // - [0..159]   `user`
    // - [160..223] `expires`
    mapping(uint256 => uint256) private _packedUserInfo;



    /// @notice The constructor of this contract.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) ROJIStandardERC721A(defaultRoyaltiesBasisPoints_, name_, symbol_, baseTokenURI_) {
    }


/**
     * @dev Sets the `user` and `expires` for `tokenId`.
     * The zero address indicates there is no user.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual override {
        // Require the caller to be either the token owner or an approved operator.
        address owner = ownerOf(tokenId);
        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A()))
                if (getApproved(tokenId) != _msgSenderERC721A()) revert SetUserCallerNotOwnerNorApproved();

        _packedUserInfo[tokenId] = (uint256(expires) << _BITPOS_EXPIRES) | uint256(uint160(user));

        emit UpdateUser(tokenId, user, expires);
    }

    function _setUserUnchecked(
        uint256 tokenId,
        address user,
        uint64 expires
    ) internal {
        _packedUserInfo[tokenId] = (uint256(expires) << _BITPOS_EXPIRES) | uint256(uint160(user));
        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * @dev Returns the user address for `tokenId`.
     * The zero address indicates that there is no user or if the user is expired.
     */
    function userOf(uint256 tokenId) public view virtual override returns (address) {
        uint256 packed = _packedUserInfo[tokenId];
        assembly {
            // Branchless `packed *= (block.timestamp <= expires ? 1 : 0)`.
            // If the `block.timestamp == expires`, the `lt` clause will be true
            // if there is a non-zero user address in the lower 160 bits of `packed`.
            packed := mul(
                packed,
                // `block.timestamp <= expires ? 1 : 0`.
                lt(shl(_BITPOS_EXPIRES, timestamp()), packed)
            )
        }
        return address(uint160(packed));
    }

    /**
     * @dev Returns the user's expires of `tokenId`.
     */
    function userExpires(uint256 tokenId) public view virtual override returns (uint256) {
        return _packedUserInfo[tokenId] >> _BITPOS_EXPIRES;
    }

    /**
     * @dev Override of {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual 
                override(ROJIStandardERC721A, IERC721A) returns (bool) {
        return ROJIStandardERC721A.supportsInterface(interfaceId) || 
               interfaceId == _INTERFACE_ID_ERC4907;
    }

    /**
     * @dev Returns the user address for `tokenId`, ignoring the expiry status.
     */
    function _explicitUserOf(uint256 tokenId) internal view virtual returns (address) {
        return address(uint160(_packedUserInfo[tokenId]));
    }

    function explicitUserOf(uint256 tokenId) public view returns (address) {
        return _explicitUserOf(tokenId);
    }
}