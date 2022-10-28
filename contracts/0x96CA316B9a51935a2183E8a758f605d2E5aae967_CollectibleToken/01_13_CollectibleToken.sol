// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract CollectibleToken is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter public totalMinted;

  uint256 public immutable maxSupply;
  uint256 public immutable maxPerUser;
  uint256 public immutable price;
  uint256 public immutable startMintBlock;
  uint256 public immutable endMintBlock;
  string public defaultTokenUri;
  bool public constant verificationSupported = true;
  bool public immutable publicMint;

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
      maxSupply == 0 || totalMinted.current() < maxSupply,
      "Not enough NFT's!"
    );
    _;
  }

  modifier limitedPerUser(address receiver) {
    require(
      maxPerUser == 0 || ERC721.balanceOf(receiver) < maxPerUser,
      "Maximum NFT's for this account has been minted!"
    );
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
    uint256 maxSupply_,
    uint256 maxPerUser_,
    uint256 mintPrice_,
    address payable creatorAddress,
    bool publicMint_,
    uint256 startMintBlock_,
    uint256 endMintBlock_,
    string memory tokenURI_,
    address payable feeReceiver
  ) payable ERC721(name_, symbol_) {
    require(msg.value > 0, "Deployment fee required");
    require(maxPerUser_ <= maxSupply_, "Max per user cannot be greater than max supply!");

    Address.sendValue(feeReceiver, msg.value);

    maxSupply = maxSupply_;
    maxPerUser = maxPerUser_;
    price = mintPrice_;
    publicMint = publicMint_;
    startMintBlock = startMintBlock_;
    endMintBlock = endMintBlock_;
    defaultTokenUri = tokenURI_;

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
    payForMint(msg.value);

    uint256 newItemId = totalMinted.current();
    totalMinted.increment();
    _mint(receiver, newItemId);
    _setTokenURI(newItemId, defaultTokenUri);

    return newItemId;
  }

  /**
   * @notice method which is used to pay for mint.
   */
  function payForMint(uint256 _amount) internal {
    Address.sendValue(payable(owner()), _amount);
  }
}