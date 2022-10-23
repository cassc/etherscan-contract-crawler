// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Helpers } from "./libraries/Helpers.sol";

contract CollectibleBatchToken is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter public totalMinted;

  mapping(address => bool) public whitelist; // whitelisted addresses map
  address[] whitelistedAddresses; // array for keeping track of whitelisted users
  string[] public tokenUris;

  uint256 public immutable maxPerUser;
  uint256 public immutable price;
  uint256 public immutable startMintBlock;
  uint256 public immutable endMintBlock;
  bool public immutable publicMint;
  bool public immutable isWhitelistEnabled;
  bool public constant isBatchVersion = true;
  bool public constant verificationSupported = true;

  modifier publicMintAllowed(address receiver) {
    require(
      publicMint || owner() == receiver,
      "Public mint is not allowed, only token owner can mint!"
    );
    _;
  }

  modifier costs() {
    require(price == 0 || msg.value == price, "Wrong amount sent for mint!");
    _;
  }

  modifier limitedByMaxSupply() {
    require(
      tokenUris.length == 0 || totalMinted.current() < tokenUris.length,
      "Not enough NFT's!"
    );
    _;
  }

  modifier limitedPerUser(address receiver) {
    if (receiver != owner()) {
      require(
        maxPerUser == 0 || ERC721.balanceOf(receiver) < maxPerUser,
        "Maximum NFT's for this account has been minted!"
      );
    }
    _;
  }

  modifier startTime() {
    require(
      block.timestamp >= startMintBlock,
      "Sale not started yet"
    );
    _;
  }

  modifier endTime() {
    require(
      endMintBlock == 0 || block.timestamp < endMintBlock,
      "Sale already ended"
    );
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxPerUser_,
    uint256 mintPrice_,
    address creatorAddress,
    bool publicMint_,
    uint256 startMintBlock_,
    uint256 endMintBlock_,
    address payable feeReceiver,
    bool isWhitelistEnabled_
  ) payable ERC721(name_, symbol_) {
    require(msg.value > 0, "Deployment fee required");

    Address.sendValue(feeReceiver, msg.value);

    maxPerUser = maxPerUser_;
    price = mintPrice_;
    publicMint = publicMint_;
    isWhitelistEnabled = isWhitelistEnabled_;
    startMintBlock = startMintBlock_;
    endMintBlock = endMintBlock_;

    if (creatorAddress != msg.sender) {
      transferOwnership(creatorAddress);
    }
  }

  /**
   * @notice method which is used to mint nft.
   */
  function mint(address receiver)
    external
    payable
    publicMintAllowed(receiver)
    startTime
    endTime
    costs
    limitedByMaxSupply
    limitedPerUser(receiver)
    returns (uint256)
  {
    if (isWhitelistEnabled && owner() != receiver) {
      require(whitelist[receiver], "Minter not whitelisted");
    }

    payForMint(msg.value);

    uint256 newItemId = totalMinted.current();
    totalMinted.increment();
    _mint(receiver, newItemId);
    _setTokenURI(newItemId, tokenUris[newItemId]);

    return newItemId;
  }

  /**
   * @notice method which is used to pay for mint.
   */
  function payForMint(uint256 _amount) internal {
    Address.sendValue(payable(owner()), _amount);
  }

  function maxSupply() external view returns (uint256) {
    return tokenUris.length;
  }

  function getTokenUris() external view returns (string[] memory) {
    return tokenUris;
  }

  function addTokenUris(string[] calldata _tokenUris) external onlyOwner {
    for (uint256 i = 0; i < _tokenUris.length; i++) {
      tokenUris.push(_tokenUris[i]);
    }
  }

  /**
   * @notice Method for updating whitelist
   * @param updatedAddresses new whitelist addresses
   */
  function updateWhitelist(address[] calldata updatedAddresses)
    external
    payable
    onlyOwner
  {
    require(isWhitelistEnabled, "Whitelist not enabled");

    _removeFromWhitelist(whitelistedAddresses);
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
  }

  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @dev Adds list of addresses to whitelist.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function _addManyToWhitelist(address[] memory _beneficiaries) internal {
    for (uint256 i = 0; i < _beneficiaries.length; ) {
      Helpers.requireNonZeroAddress(_beneficiaries[i]);

      whitelist[_beneficiaries[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Cleans whitelist, removing every user.
   * @param _beneficiaries Addresses to be unlisted
   */
  function _removeFromWhitelist(address[] memory _beneficiaries) internal {
    for (uint256 i = 0; i < _beneficiaries.length; ) {
      whitelist[_beneficiaries[i]] = false;
      unchecked {
        ++i;
      }
    }
  }
}