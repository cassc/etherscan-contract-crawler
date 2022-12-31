// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Helpers } from "./lib/Helpers.sol";

contract CollectibleToken is ERC721URIStorage, Ownable {
  /// @notice total number of tokens minted
  uint256 public totalMinted;
  /// @notice max supply of tokens allowed
  uint256 public immutable maxSupply;
  /// @notice max tokens allowed per wallet
  uint256 public immutable maxPerUser;
  /// @notice price for minting a token
  uint256 public immutable price;
  /// @notice default uri for token
  string public defaultTokenUri;
  /// @notice start block for minting
  uint40 public immutable startMintBlock;
  /// @notice end block for minting
  uint40 public immutable endMintBlock;
  /// @notice boolean to check if anyone can mint a new token
  bool public immutable publicMint;

  /// @notice raised when public minting is not allowed
  error PublicMintNotAllowed();
  /// @notice raised when not enough funds are sent for fee
  error InvalidFeeAmount(uint256 amount);
  /// @notice raised when the max supply has been reached
  error MaxSupplyReached(uint256 maxSupply);
  /// @notice raised when the max per user has been reached
  error MaxPerUserReached(uint256 maxPerUser);
  /// @notice raised when the sale has not started
  error SaleNotStarted();
  /// @notice raised when the sale has already ended
  error SaleAlreadyEnded();
  /// @notice raised when max per user is greater than max supply during initialization
  error MaxPerUserGtMaxSupply(uint256 maxPerUser, uint256 maxSupply);

  /**
   * @notice modifier which checks if public minting is allowed
   */
  modifier publicMintAllowed(address receiver) {
    if (!publicMint && receiver != owner()) {
      revert PublicMintNotAllowed();
    }
    _;
  }

  /**
   * @notice modifier which checks if the correct amount of is sent as fees for mint
   */
  modifier costs() {
    if (price != 0 && msg.value != price) {
      revert InvalidFeeAmount(msg.value);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max supply has been reached
   */
  modifier limitedByMaxSupply() {
    if (maxSupply != 0 && totalMinted >= maxSupply) {
      revert MaxSupplyReached(maxSupply);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max tokens per wallet has been reached
   * @param receiver - address of the user to check if max tokens per wallet has been reached
   */
  modifier limitedPerUser(address receiver) {
    if (maxPerUser != 0 && balanceOf(receiver) >= maxPerUser) {
      revert MaxPerUserReached(maxPerUser);
    }
    _;
  }

  /**
   * @notice modifier which checks if sale has started and not ended
   */
  modifier saleIsOpen() {
    if (block.timestamp < startMintBlock) {
      revert SaleNotStarted();
    }
    if (endMintBlock != 0 && block.timestamp >= endMintBlock) {
      revert SaleAlreadyEnded();
    }
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
    uint40 startMintBlock_,
    uint40 endMintBlock_,
    string memory tokenURI_
  ) ERC721(name_, symbol_) {
    if (maxPerUser_ > maxSupply_) {
      revert MaxPerUserGtMaxSupply(maxPerUser_, maxSupply_);
    }

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
   * @notice method which is used for minting NFTs
   * @param receiver - address of the receiver of the NFT
   * @return newItemId - id of the newly minted NFT
   */
  function mint(address receiver)
    external
    payable
    publicMintAllowed(receiver)
    saleIsOpen
    costs
    limitedByMaxSupply
    limitedPerUser(receiver)
    returns (uint256)
  {
    uint256 newItemId = totalMinted;
    unchecked {
      ++totalMinted;
    }
    Helpers.safeTransferETH(owner(), msg.value);
    _safeMint(receiver, newItemId);
    _setTokenURI(newItemId, defaultTokenUri);
    return newItemId;
  }
}