// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721AEnumerable
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://block.aocollab.tech
/// An enumerable extension to ERC721A that does not increase gas costs.

import "./IERC721AEnumerable.sol";
import "./ERC721A.sol";

error IndexOutOfBounds();
error QueryForZeroAddress();

contract ERC721AEnumerable is IERC721AEnumerable, ERC721A {
  constructor(
    string memory name_,
    string memory symbol_
  ) ERC721A(name_, symbol_) {}

  /**
   * @dev Returns the total amount of tokens stored by the contract.
   * Uses the ERC721A implementation.
   */
  function totalSupply()
    public
    view
    override(ERC721A, IERC721AEnumerable)
    returns (uint256)
  {
    return ERC721A.totalSupply();
  }

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   * @notice This method is intended for read only purposes.
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) external view override returns (uint256 tokenId) {
    if (owner == address(0)) revert QueryForZeroAddress();
    if (balanceOf(owner) <= index) revert IndexOutOfBounds();

    uint256 upToIndex = 0;
    uint256 highestTokenId = _startTokenId() + _totalMinted();
    for (uint256 i = _startTokenId(); i < highestTokenId; i++) {
      if (_ownerOfWithoutError(i) == owner) {
        if (upToIndex == index) return i;
        upToIndex++;
      }
    }
    // Should never reach this case
    revert IndexOutOfBounds();
  }

  /**
   * A copy of the ERC721A._ownershipOf implementation that returns address(0) when unowned instead of an error.
   */
  function _ownerOfWithoutError(
    uint256 tokenId
  ) internal view returns (address) {
    uint256 curr = tokenId;

    unchecked {
      if (_startTokenId() <= curr && curr < _nextTokenId()) {
        TokenOwnership memory ownership = _ownershipAt(curr);
        if (!ownership.burned) {
          if (ownership.addr != address(0)) return ownership.addr;

          // Invariant:
          // There will always be an ownership that has an address and is not burned
          // before an ownership that does not have an address and is not burned.
          // Hence, curr will not underflow.
          while (true) {
            curr--;
            ownership = _ownershipAt(curr);
            if (ownership.addr != address(0)) return ownership.addr;
          }
        }
      }
    }
    return address(0);
  }

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   * @notice This method is intended for read only purposes.
   */
  function tokenByIndex(
    uint256 index
  ) external view override returns (uint256) {
    uint256 highestTokenId = _startTokenId() + _totalMinted();
    if (index > highestTokenId) revert IndexOutOfBounds();

    uint256 indexedId = 0;
    for (uint256 i = _startTokenId(); i < highestTokenId; i++) {
      if (!_ownershipAt(i).burned) {
        if (indexedId == index) return i;
        indexedId++;
      }
    }
    revert IndexOutOfBounds();
  }

  /**
   * @dev Returns a list of token IDs owned by `owner`.
   * @notice This method is intended for read only purposes.
   */
  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    if (owner == address(0)) revert QueryForZeroAddress();

    uint256 balance = balanceOf(owner);
    uint256[] memory tokens = new uint256[](balance);

    uint256 index = 0;
    uint256 highestTokenId = _startTokenId() + _totalMinted();
    for (uint256 i = _startTokenId(); i < highestTokenId; i++) {
      if (_ownerOfWithoutError(i) == owner) {
        tokens[index] = i;
        index++;
        if (index == balance) break;
      }
    }
    return tokens;
  }
}