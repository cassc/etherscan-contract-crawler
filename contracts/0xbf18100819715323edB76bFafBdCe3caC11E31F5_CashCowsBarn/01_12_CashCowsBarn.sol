// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-------------------------------------------------------------------------------------------
//
//   /$$$$$$                      /$$              /$$$$$$                                   
//  /$$__  $$                    | $$             /$$__  $$                                  
// | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$       | $$  \__/  /$$$$$$  /$$  /$$  /$$  /$$$$$$$
// | $$       |____  $$ /$$_____/| $$__  $$      | $$       /$$__  $$| $$ | $$ | $$ /$$_____/
// | $$        /$$$$$$$|  $$$$$$ | $$  \ $$      | $$      | $$  \ $$| $$ | $$ | $$|  $$$$$$ 
// | $$    $$ /$$__  $$ \____  $$| $$  | $$      | $$    $$| $$  | $$| $$ | $$ | $$ \____  $$
// |  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$      |  $$$$$$/|  $$$$$$/|  $$$$$/$$$$/ /$$$$$$$/
//  \______/  \_______/|_______/ |__/  |__/       \______/  \______/  \_____/\___/ |_______/
//
//-------------------------------------------------------------------------------------------
//
// Moo.

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../IERC20Mintable.sol";

// ============ Interfaces ============

interface IERC721OwnsAll is IERC721 {
  /**
   * @dev Returns true if `owner` owns all the `tokenIds`
   */
  function ownsAll(
    address owner, 
    uint256[] memory tokenIds
  ) external view returns(bool);
}

// ============ Contract ============

/**
 * @dev This produces milk for CC and CCC
 */
contract CashCowsBarn is AccessControl {
  using Address for address;

  // ============ Errors ============

  error InvalidCall();

  // ============ Constants ============

  //roles
  bytes32 internal constant _MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public immutable START_TIME;
  IERC20Mintable public immutable TOKEN;

  // ============ Storage ============

  //mapping of collection, token id to how much was redeemed
  mapping(address => mapping(uint256 => uint256)) private _released;

  // ============ Deploy ============

  /**
   * @dev Sets the role admin, token and start time
   */
  constructor(IERC20Mintable token, uint256 start, address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    TOKEN = token;
    START_TIME = start;
  }

  // ============ Read Methods ============

  /**
   * @dev Calculate how many a tokens an NFT earned
   */
  function releaseable(
    address collection, 
    uint256 tokenId,
    uint256 rate
  ) public view returns(uint256) {
    //FORMULA: (now - when we first started) * rate
    uint256 totalEarned = ((block.timestamp - START_TIME) * rate);
    uint256 totalReleased = released(collection, tokenId);

    //if the total earned is less than what was redeemed
    if (totalEarned < totalReleased) {
      //prevent underflow error
      return 0;
    }
    //otherwise should be the total earned less what was already redeemed
    return totalEarned - totalReleased;
  }

  /**
   * @dev Returns how many token tokens were already 
   * released for `collection` `tokenId`
   */
  function released(
    address collection, 
    uint256 tokenId
  ) public view returns(uint256) {
    return _released[collection][tokenId];
  }
  
  // ============ Write Methods ============

  /**
   * @dev Releases tokens for just one NFT. Rate is determined off chain.
   */
  function release(
    address collection, 
    uint256 tokenId, 
    uint256 rate, 
    bytes memory proof
  ) external {
    //revert if invalid proof
    if (!hasRole(_MINTER_ROLE, ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(
          "release", 
          collection,
          tokenId,
          rate
        ))
      ),
      proof
    ))) revert InvalidCall();
    //get the staker
    address staker = _msgSender();
    //if not owner
    if (IERC721(collection).ownerOf(tokenId) != staker) 
      revert InvalidCall();
    //get pending
    uint256 pending = releaseable(collection, tokenId, rate);
    //add to what was already released
    _released[collection][tokenId] += pending;

    //next mint tokens
    address(TOKEN).functionCall(
      abi.encodeWithSelector(
        IERC20Mintable(TOKEN).mint.selector, 
        staker, 
        pending
      ), 
      "Low-level mint failed"
    );
  }

  /**
   * @dev Releases tokens for many NFTs. Rates are determined off chain.
   */
  function release(
    address collection, 
    uint256[] memory tokenIds, 
    uint256[] memory rates, 
    bytes[] memory proofs
  ) external {
    //arrays should be the same length
    if (tokenIds.length != rates.length 
      || rates.length != proofs.length
    ) revert InvalidCall(); 
    //get the staker
    address staker = _msgSender();
    //revert of does not owns all
    if (!IERC721OwnsAll(collection).ownsAll(
      staker, 
      tokenIds
    )) revert InvalidCall();
 
    uint256 toRelease = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      //revert if invalid proof
      if (!hasRole(_MINTER_ROLE, ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(
            "release", 
            collection,
            tokenIds[i],
            rates[i]
          ))
        ),
        proofs[i]
      ))) revert InvalidCall();
      //get pending
      uint256 pending = releaseable(collection, tokenIds[i], rates[i]);
      //add to what was already released
      _released[collection][tokenIds[i]] += pending;
      //add to be released
      toRelease += pending;
    }

    //next mint tokens
    address(TOKEN).functionCall(
      abi.encodeWithSelector(
        IERC20Mintable(TOKEN).mint.selector, 
        staker, 
        toRelease
      ), 
      "Low-level mint failed"
    );
  }
}