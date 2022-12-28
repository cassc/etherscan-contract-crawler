// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Helpers } from "./lib/Helpers.sol";

contract CollectibleBatchToken is ERC721URIStorage, Ownable {
  /// @notice mapping of whitelisted addresses to a boolean
  mapping(address => bool) public whitelist;
  /// @notice array holding all whitelisted addresses
  address[] public whitelistedAddresses;
  /// @notice array holding tokenUris
  string[] public tokenUris;
  /// @notice total number of tokens minted
  uint256 public totalMinted;
  /// @notice max tokens allowed per wallet
  uint256 public immutable maxPerUser;
  /// @notice price for minting a token
  uint256 public immutable price;
  /// @notice start block for minting
  uint40 public immutable startMintBlock;
  /// @notice end block for minting
  uint40 public immutable endMintBlock;
  /// @notice boolean to check if anyone can mint a new token
  bool public immutable publicMint;
  /// @notice boolean to check if whitelisting is enabled
  bool public immutable isWhitelistEnabled;
  /// @notice used internally
  // solhint-disable-next-line const-name-snakecase
  bool public constant isBatchVersion = true;

  /// @notice raised when public minting is not allowed
  error PublicMintNotAllowed();
  /// @notice raised when the fee amount is invalid
  error InvalidFeeAmount(uint256 amount);
  /// @notice raised when the max supply has been reached
  error MaxSupplyReached(uint256 maxSupply);
  /// @notice raised when the max per user has been reached
  error MaxPerUserReached(uint256 maxPerUser);
  /// @notice raised when the sale has not started
  error SaleNotStarted();
  /// @notice raised when the sale has already ended
  error SaleAlreadyEnded();
  /// @notice raised when whitelisting is not enabled
  error WhitelistNotEnabled();
  /// @notice raised when the address is not whitelisted
  error NotWhitelisted(address addr);

  /**
   * @notice modifier which checks if public minting is allowed
   * or if the minter is the owner of the contract
   * @param receiver - address of the receiver
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
    if (tokenUris.length != 0 && totalMinted >= tokenUris.length) {
      revert MaxSupplyReached(tokenUris.length);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max per user has been reached
   * @param receiver - address of the user to check if max per user has been reached
   */
  modifier limitedPerUser(address receiver) {
    if (owner() != receiver) {
      if (maxPerUser != 0 && balanceOf(receiver) >= maxPerUser) {
        revert MaxPerUserReached(maxPerUser);
      }
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
    uint256 maxPerUser_,
    uint256 mintPrice_,
    address creatorAddress,
    bool publicMint_,
    uint40 startMintBlock_,
    uint40 endMintBlock_,
    bool isWhitelistEnabled_
  ) ERC721(name_, symbol_) {
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
    if (isWhitelistEnabled && owner() != receiver) {
      if (!whitelist[receiver]) {
        revert NotWhitelisted(receiver);
      }
    }
    uint256 newItemId = totalMinted;
    unchecked {
      ++totalMinted;
    }
    Helpers.safeTransferETH(owner(), msg.value);
    _safeMint(receiver, newItemId);
    _setTokenURI(newItemId, tokenUris[newItemId]);
    return newItemId;
  }

  /**
   * @notice method used to return the maxSupply
   * @return maxSupply - maxSupply of the NFT
   */
  function maxSupply() external view returns (uint256) {
    return tokenUris.length;
  }

  /**
   * @notice method which is used to return the tokenUris array
   * @return tokenUris - array of tokenUris
   */
  function getTokenUris() external view returns (string[] memory) {
    return tokenUris;
  }

  /**
   * @notice method which is used to set the tokenUris
   * @param _tokenUris - array of token uris to be added
   */
  function addTokenUris(string[] calldata _tokenUris) external onlyOwner {
    for (uint256 i; i < _tokenUris.length; ) {
      tokenUris.push(_tokenUris[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method for updating the whitelist if whitelist is enabled
   * @param updatedAddresses - whitelisted addresses to be added
   */
  function updateWhitelist(address[] calldata updatedAddresses)
    external
    onlyOwner
  {
    if (!isWhitelistEnabled) {
      revert WhitelistNotEnabled();
    }
    _clearWhitelist();
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
  }

  /**
   * @notice method for returning the whitelisted addresses
   * @return whitelistedAddresses - array of whitelisted addresses
   */
  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @notice method for adding addresses to whitelist
   * @param addresses - addresses to be added to the whitelist
   */
  function _addManyToWhitelist(address[] calldata addresses) private {
    for (uint256 i; i < addresses.length; ) {
      Helpers.validateAddress(addresses[i]);
      whitelist[addresses[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method for resetting the whitelist
   */
  function _clearWhitelist() private {
    unchecked {
      address[] memory addresses = whitelistedAddresses;
      for (uint256 i; i < addresses.length; i++) {
        whitelist[addresses[i]] = false;
      }
    }
  }
}