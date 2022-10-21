// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./IERC2981Royalties.sol";

// @author rollauver.eth

contract ERC721AWithRoyalties is
  Ownable,
  ERC721A,
  IERC2981Royalties
{
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }
  RoyaltyInfo private _royalties;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    address royaltyRecipient,
    uint256 royaltyValue
  ) ERC721A(name_, symbol_, maxBatchSize_) {
    _setRoyalties(royaltyRecipient, royaltyValue);
  }
  
  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC2981Royalties).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// @dev Sets token royalties
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function _setRoyalties(address recipient, uint256 value) internal {
    require(value <= 10000, 'ERC2981Royalties: Too high');
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  /// @inheritdoc IERC2981Royalties
  function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  function updateRoyalties(address recipient, uint256 value) external onlyOwner {
    _setRoyalties(recipient, value);
  }
}