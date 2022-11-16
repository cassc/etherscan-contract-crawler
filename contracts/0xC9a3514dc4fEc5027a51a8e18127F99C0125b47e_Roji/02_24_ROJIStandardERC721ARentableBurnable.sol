// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ROJIStandardERC721ARentable.sol";
import "erc721a/contracts/interfaces/IERC721ABurnable.sol";

/// @title ERC721A based NFT contract.
/// @author Martin Wawrusch for Roji Inc.
/// @dev
/// General
///
/// This contract interhits from {ROJIStandardERC721ARentable}
///
/// Burnable Functionality
/// By default, no one can burn a token.
/// The owner can set the burnMode to either {UNRESTRICTED} or {ROLE_ONLY}. 
///
/// - UNRESTRICTED
/// Any owner of a token can burn the token.
///
/// - ROLE_ONLY
/// Only an owner of a token who also has been granted the {ROLE_BURNER} can burn a token
///
///
/// @custom:security-contact [email protected]
contract ROJIStandardERC721ARentableBurnable is ROJIStandardERC721ARentable, // IMPORTANT MUST ALWAYS BE FIRST - NEVER CHANGE THAT
                                                IERC721ABurnable
{
   enum BurnMode {
        NO_BURNING,    //0
        UNRESTRICTED,  //1
        ROLE_ONLY      //2
    }
    
    bool private _burnModeLocked;
    BurnMode private _burnMode;
 

    /// @dev The role required for the burn function, depending on {burnMode}.
    uint256 public constant ROLE_BURNER = ROJI_ROLE_BURNER;

    /// @notice Emitted when {burnMode} has been updated.
    /// @param burnMode The updated {burnMode}.
    event BurnModeUpdated(BurnMode burnMode);

    /// @dev The caller is not authorized to perform a token burn.
    error BurnUnauthorized();

    /// @dev The caller is not allowed to update the burn mode because it has been locked.
    error BurnModeLocked();

    /// @dev The token that should be burned is rented out.
    error TokenIsRented();

    /// @notice The constructor of this contract.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) ROJIStandardERC721ARentable(defaultRoyaltiesBasisPoints_, name_, symbol_, baseTokenURI_) {
    }


    /// @dev The current {burnMode}. 
    /// See the contract description for how burning works.
    function burnMode() external view returns(BurnMode) {
        return _burnMode;
    }
    /// @dev The current {burnModeLocked} state. 
    /// See the contract description for how burning works.
    function burnModeLocked() external view returns(bool) {
        return _burnModeLocked;
    }

    /// @dev Sets the burnMode
    /// Note if {_BurnModeLocked} is true this function will revert with {BurnModeLocked}.
    /// Valid values
    /// - 0 .. No burning allowed
    /// - 1 .. Burning allowed for all owners
    /// - 2 .. Burning allowed when granted role
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_SETUP] role.
    /// 
    /// @param burnMode_ The new burnMode flags.
    function setBurnMode(BurnMode burnMode_) external onlyOwnerOrRoles(ROJI_ROLE_ADMIN_SETUP) {
        if(_burnModeLocked) revert BurnModeLocked();
        _burnMode = burnMode_;
        emit BurnModeUpdated(burnMode_);
    }
    
    /// @dev Locks the burn mode, it cannot be updated afterwards.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_SETUP] role.
    ///
    function lockBurnMode() external onlyOwnerOrRoles(ROJI_ROLE_ADMIN_SETUP) {
        _burnModeLocked = true;
    }

     /// @dev Burns `tokenId`. See {ERC721A-_burn}.
     ///
     /// Requirements:
     /// 
     /// If {burnMode} is set to {BURNMODE_UNRESTRICTED}:
     ///
     /// - The caller must own `tokenId` or be an approved operator.
     ///
     /// if {burnMode} is set to {BURNMODE_ROLES}
     ///
     /// - The caller must own `tokenId` or be an approved operator.
     /// - The caller must be granted the {ROLE_BURNER} role.
     ///
     /// if neither is set the function will revert with {BurnUnauthorized}.
     ///
     /// Rental behavior:
     /// If the contract is in [BurnMode.UNRESTRICTED] then the token can only be burned if it is not rented out.
     /// If the contract is in [BurnMode.ROLE_ONLY] then a token can be burned, even if rented out. The rented user will no longer have access
    function burn(uint256 tokenId) public virtual override {

        if(_burnMode == BurnMode.UNRESTRICTED) {
            if(userOf(tokenId) != address(0)) { // rented out.
                if( userOf(tokenId) != _msgSenderERC721A()) { // Not self
                    revert TokenIsRented();
                } else {
                    _setUserUnchecked(tokenId, address(0), 0);
                }
            }
            _burn(tokenId, true);
        } else if(_burnMode == BurnMode.ROLE_ONLY && hasAnyRole(_msgSenderERC721A(), ROLE_BURNER)) {
            if (userOf(tokenId) != address(0) ) {
                _setUserUnchecked(tokenId, address(0), 0);
            }
            _burn(tokenId, true);
        } else {
            revert BurnUnauthorized();
        }
    }

    /// @dev Determines if an interface is supported by this contract.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return `true` if the interface is supported.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ROJIStandardERC721ARentable, IERC721A)
        returns (bool)
    {
        return 
                ROJIStandardERC721ARentable.supportsInterface(interfaceId) || 
                (_burnMode != BurnMode.NO_BURNING && interfaceId == type(IERC721ABurnable).interfaceId);
    }
}