// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.4; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4907.sol";
import "../Error.sol";

contract ERC4907 is ERC721, IERC4907 {
  struct UserInfo {
    address user;   // address of user role
    uint64 expires; // unix timestamp, user expires
  }

  mapping(uint256 => UserInfo) internal _users;

  constructor(
    string memory name_, 
    string memory symbol_
  ) ERC721(name_, symbol_) { }
  
  /// @notice set the user and expires of a NFT
  /// @dev The zero address indicates there is no user 
  /// Throws if `tokenId` is not valid NFT
  /// @param user  The new user of the NFT
  /// @param expires  UNIX timestamp, The new user could use the NFT before expires
  function setUser(uint256 tokenId, address user, uint64 expires) public virtual override {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerNorApproved();
    
    UserInfo storage info = _users[tokenId];
    info.user = user;
    info.expires = expires;
    emit UpdateUser(tokenId, user, expires);
  }

  /// @notice Get the user address of an NFT
  /// @dev The zero address indicates that there is no user or the user is expired
  /// @param tokenId The NFT to get the user address for
  /// @return The user address for this NFT
  function userOf(uint256 tokenId) public view virtual override returns (address) {
    if (uint256(_users[tokenId].expires) >= block.timestamp) {
      return _users[tokenId].user; 
    } else {
      return address(0);
    }
  }

  /// @notice Get the user expires of an NFT
  /// @dev The zero value indicates that there is no user 
  /// @param tokenId The NFT to get the user expires for
  /// @return The user expires for this NFT
  function userExpires(uint256 tokenId) public view virtual override returns (uint256) {
    return _users[tokenId].expires;
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override{
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != to && _users[tokenId].user != address(0)) {
      delete _users[tokenId];
      emit UpdateUser(tokenId, address(0), 0);
    }
  }
}