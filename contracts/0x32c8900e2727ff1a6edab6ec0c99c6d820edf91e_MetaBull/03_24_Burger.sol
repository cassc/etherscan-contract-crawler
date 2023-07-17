//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Grill2.sol";

error BurningNotActive();
error ClaimingNotActive();
error CallerIsNotABurner();
error InsufficientClaimsRemaining();

/**
 * @title Burgers
 * @author Matt Carter
 * June 6, 2022
 *
 * This contract is for accounts to claim emission tokens (burgers) from their grill stakes.
 * Burgers have a `tokenId` of 1 and are burnable by owner-set `burner` addresses.
 */
contract Burger is ERC1155, Ownable {
  using Strings for uint256;
  /// contract instances ///
  Grill2 public immutable TheGrill;
  Grill2 public SpecialGrill;
  /// is claiming/burning/special grill active ///
  bool public isClaiming = false;
  bool public isBurning = false;
  bool public isSpecial = false;
  /// the number of burgers minted/burned ///
  uint256 public totalMints;
  uint256 public totalBurns;
  /// addresses allowed to burn burgers ///
  mapping(address => bool) public burners;
  /// the number of claims used by each account ///
  mapping(address => uint256) public claimsUsed;
  /// the number of burgers burned by each account ///
  mapping(address => uint256) public accountBurns;
  /// the number of burgers burned by each burner ///
  mapping(address => uint256) public burnerBurns;

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Sets the initial base URI and address for the grill
   * @param _URI The baseURI for each token
   * @param aGrill The address of the astro grill contract
   */
  constructor(string memory _URI, address aGrill) ERC1155(_URI) {
    TheGrill = Grill2(aGrill);
  }

  /// ============ INTERNAL ============ ///

  /**
   * Gets the total number of burgers `account` has earned from the grill(s)
   * @param account The address to lookup
   * @return quantity The number of claims
   */
  function _totalClaimsEarned(address account)
    internal
    view
    returns (uint256 quantity)
  {
    quantity += TheGrill.totalClaims(account);
    /// @dev additionally counts special grill stakes ///
    if (isSpecial) {
      quantity += SpecialGrill.totalClaims(account);
    }
  }

  /// ============ OWNER ============ ///

  /**
   * Sets the new base URI for tokens
   * @param _URI The new base URI
   * @notice Uses the format: baselink.com/{}.json
   */
  function setURI(string memory _URI) public onlyOwner {
    _setURI(_URI);
  }

  /**
   * Toggles if claiming tokens is allowed
   */
  function toggleClaiming() public onlyOwner {
    isClaiming = !isClaiming;
  }

  /**
   * Toggles if burning tokens is allowed
   */
  function toggleBurning() public onlyOwner {
    isBurning = !isBurning;
  }

  /**
   * Approve an address to burn burgers
   * @param account The burner address
   * @param status The status of the approval
   * @notice A burner should be a contract address that correctly handles the burning of an operators tokens
   */
  function setBurner(address account, bool status) public onlyOwner {
    burners[account] = status;
  }

  /**
   * Mints `quantity` burgers to `account` without restrictions
   * @param quantity The number of tokens to mint
   * @param account The address to mint the tokens to
   */
  function ownerMint(uint256 quantity, address account) public onlyOwner {
    _mint(account, 1, quantity, "0x00");
    totalMints += quantity;
  }

  /**
   * Toggles if the special grill is running
   */
  function toggleSpecial() public onlyOwner {
    isSpecial = !isSpecial;
  }

  /**
   * Sets the special grill interface
   * @param aGrill The address of the special grill
   */
  function setSpecial(address aGrill) public onlyOwner {
    SpecialGrill = Grill2(aGrill);
  }

  /// ============ PUBLIC ============ ///

  /**
   * Mints `quantity` burgers to caller
   * @param quantity The number of burgers caller is trying to mint
   */
  function claimBurgers(uint256 quantity) public {
    if (!isClaiming) {
      revert ClaimingNotActive();
    }
    if (claimsUsed[msg.sender] + quantity > _totalClaimsEarned(msg.sender)) {
      revert InsufficientClaimsRemaining();
    }
    /// @dev mints `quantity` tokens with `tokenId` 1 to caller ///
    _mint(msg.sender, 1, quantity, "0x00");
    /// @dev sets contract state ///
    claimsUsed[msg.sender] += quantity;
    totalMints += quantity;
  }

  /**
   * Burns burgers on behalf of `account`
   * @param account The address having it's burgers burned
   * @param quantity The number of burgers to burn
   * @notice Only burners may call this function
   */
  function burnBurger(address account, uint256 quantity) public {
    if (!isBurning) {
      revert BurningNotActive();
    }
    if (!burners[msg.sender]) {
      revert CallerIsNotABurner();
    }
    /// @dev burns `quantity` tokens of `tokenId` 1 for `account` ///
    _burn(account, 1, quantity);
    /// @dev sets contract state ///
    totalBurns += quantity;
    accountBurns[account] += quantity;
    burnerBurns[msg.sender] += quantity;
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets the balance of burgers for `account`
   * @param account The address to lookup
   * @return _balance The number of burgers
   * @notice burgers have a `tokenId` of 1
   */
  function balanceOf(address account) public view returns (uint256 _balance) {
    _balance = balanceOf(account, 1);
  }

  /**
   * Gets the total number of burgers in circulation
   * @return _totalSupply The number of burgers
   */
  function totalSupply() public view returns (uint256 _totalSupply) {
    _totalSupply = totalMints - totalBurns;
  }

  /**
   * Gets the number of claims `account` has remaining
   * @param account The address to lookup
   * @return _remaining The number of claims
   */
  function tokenClaimsLeft(address account)
    public
    view
    returns (uint256 _remaining)
  {
    _remaining = _totalClaimsEarned(account) - claimsUsed[account];
  }
}