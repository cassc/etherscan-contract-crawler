// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/INiftyLaunchComics.sol";

contract NiftyBurningComicsL2 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  event ComicsBurned(address indexed by, uint256[] tokenIds, uint256[] values);
  event KeyMinted(address indexed by, uint256 tokenId, uint256 value, uint256 startIdForIMX);
  event ItemMinted(address indexed by, uint256[] tokenIds, uint256[] values, uint256[] startIdForIMX);

  /// @dev NiftyLaunchComics address
  address public comics;

  /// @dev Item index
  uint256 public itemIndex;

  /// @dev Token ID -> Item ID
  mapping(uint256 => uint256) public itemIdByTokenId;

  function initialize(address _comics) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    comics = _comics;

    // set the current item index
    itemIndex = 1;
  }

  /**
   * @notice Burn comics and returns the items associated with its page
   * @dev User can burn all 6 comics at once to receive a key to the citadel
   * @param _values Number of comics to burn, nth value means the number of nth comics(tokenId = n) to burn
   */
  function burnComics(uint256[] calldata _values) external nonReentrant whenNotPaused {
    // check _values param
    require(_values.length == 6, "Invalid length");

    // tokenIds and values to be minted
    uint256[] memory tokenIds = new uint256[](6);
    uint256[] memory tokenNumbersForItems = new uint256[](6);
    uint256[] memory tokenItemIndexs = new uint256[](6);

    // get tokenIds and the number of keys to mint
    uint256 valueForKeys = type(uint256).max;
    for (uint256 i; i < _values.length; i++) {
      // burning comics for keys
      // get the min value in _values
      if (_values[i] < valueForKeys) valueForKeys = _values[i];

      // set tokenIds
      tokenIds[i] = i + 1;
    }

    // in case of the keys should be minted, set the number of items to be minted
    if (valueForKeys != 0) {
      for (uint256 i; i < _values.length; i++) {
        tokenNumbersForItems[i] = _values[i] - valueForKeys;
      }
    }

    // burn comics
    INiftyLaunchComics(comics).burnBatch(msg.sender, tokenIds, _values);
    emit ComicsBurned(msg.sender, tokenIds, _values);

    // mint the keys and items
    if (valueForKeys != 0) {
      // mint the key and items
      emit KeyMinted(msg.sender, 1, valueForKeys, itemIndex);

      // set the itemId by the tokenId
      for (uint256 i; i < valueForKeys; i++) {
        itemIdByTokenId[itemIndex + i] = 7; // 7: Key
      }

      // increase the itemIndex for next items
      itemIndex += valueForKeys;

      for (uint256 i; i < _values.length; i++) {
        tokenItemIndexs[i] = itemIndex;

        for (uint256 j; j < _values.length; j++) {
          itemIdByTokenId[tokenItemIndexs[i] + j] = i + 1; // 1: Item1, 2: Item2, ..., 6 : Item6
        }

        // increase the itemIndex for next items
        itemIndex += tokenNumbersForItems[i];
      }

      emit ItemMinted(msg.sender, tokenIds, tokenNumbersForItems, tokenItemIndexs);
    } else {
      // mint items
      for (uint256 i; i < _values.length; i++) {
        tokenItemIndexs[i] = itemIndex;

        // set the itemId by the tokenId
        for (uint256 j; j < _values[i]; j++) {
          itemIdByTokenId[tokenItemIndexs[i] + j] = i + 1; // 1: Item1, 2: Item2, ..., 6 : Item6
        }

        // increase the itemIndex for next items
        itemIndex += _values[i];
      }

      emit ItemMinted(msg.sender, tokenIds, _values, tokenItemIndexs);
    }
  }

  /**
   * @notice Pause comics burning
   * @dev Only owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause comics burning
   * @dev Only owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}