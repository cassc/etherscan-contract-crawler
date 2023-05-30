//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC4907} from "./IERC4907.sol";

/// @title ERC4907 - ERC721 Rental
/// @author dev by @dievardump
/// @notice Generic contract for rentals of ERC721 allowing custom rules for allowing rentals and cancelations
/// @dev dev MUST implement _checkCanRent in their own contract to check for Rental allowance
///      dev CAN override _checkCanCancelRental in their own contract to allow or not a cancelation
abstract contract ERC4907 is IERC4907, ERC165 {
    error NotCurrentRenter();

    uint256 private constant _BITPOS_EXPIRES = 160;

    mapping(uint256 => uint256) internal _rentals;

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
    }

    function userOf(uint256 tokenId) public view returns (address) {
        (address renter, uint256 expires) = _rentalData(tokenId);

        // rental has expired, so there is no user
        if (expires < block.timestamp) {
            return address(0);
        }

        return renter;
    }

    function userExpires(uint256 tokenId) public view returns (uint256) {
        (address renter, uint256 expires) = _rentalData(tokenId);

        if (renter == address(0)) {
            expires = 0;
        }

        return expires;
    }

    /////////////////////////////////////////////////////////
    // Actions                                             //
    /////////////////////////////////////////////////////////

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public {
        _checkCanRent(msg.sender, tokenId, user, expires);

        _rentals[tokenId] = (uint256(expires) << _BITPOS_EXPIRES) | uint256(uint160(user));
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice allows current caller to cancel the rental for tokenId
    /// @param tokenId the token id
    function cancelRental(uint256 tokenId) public {
        _checkCanCancelRental(msg.sender, tokenId);

        _rentals[tokenId] = 0;
        emit UpdateUser(tokenId, address(0), 0);
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    function _rentalData(uint256 tokenId) internal view returns (address, uint256) {
        uint256 rental = _rentals[tokenId];
        return (address(uint160(rental)), rental >> _BITPOS_EXPIRES);
    }

    /// @dev by default, only the current renter can cancel a rental
    /// @param operator the current caller
    /// @param tokenId the token id to cancel the rental for
    function _checkCanCancelRental(address operator, uint256 tokenId) internal view virtual {
        if (operator != userOf(tokenId)) {
            revert NotCurrentRenter();
        }
    }

    /// @notice Function used to check if `operator` can rent `tokenId` to `user` until `expires`
    ///         this function MUST REVERT if the rental is invalid
    /// @dev MUST be defined in consumer contract
    /// @param operator the operator trying to do the rent
    /// @param tokenId the token id to rent
    /// @param user the possible renter
    /// @param expires the rent expiration
    function _checkCanRent(
        address operator,
        uint256 tokenId,
        address user,
        uint64 expires
    ) internal view virtual;
}