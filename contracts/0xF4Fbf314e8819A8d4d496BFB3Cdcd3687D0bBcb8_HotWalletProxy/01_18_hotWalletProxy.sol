// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface ERC721Interface {
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
}

interface ERC1155Interface {
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
}

/**
 * Enables setting a hot wallet as a proxy for your cold wallet, so that you
 * can submit a transaction from your cold wallet once, and other contracts can
 * use this contract to map ownership of an ERC721 or ERC1155 token to your hot wallet.
 *
 * NB: There is a fixed limit to the number of cold wallets that a single hot wallet can
 * point to. This is to avoid a scenario where an attacker could add so many links to a
 * hot wallet that the original cold wallet is no longer able to update their hot wallet
 * address because doing so would run out of gas.
 *
 * Additionally, we provide affordance for locking a hot wallet address so that this
 * attack's surface area can be further reduced.
 *
 * Example:
 *
 *   - Cold wallet 0x123 owns BAYC #456
 *   - Cold wallet 0x123 calls setHotWallet(0xABC)
 *   - Another contract that wants to check for BAYC ownership calls ownerOf(BAYC_ADDRESS, 456);
 *     + This contract calls BAYC's ownerOf(456)
 *     + This contract will see that BAYC #456 is owned by 0x123, which is mapped to 0xABC, and
 *     + returns 0xABC from ownerOf(BAYC_ADDRESS, 456)
 *
 * NB: With balanceOf and balanceOfBatch, this contract will look up the balance of both the cold
 * wallets and the requested wallet, _and return their sum_.
 *
 * To remove a hot wallet, you can either:
 *   - Submit a transaction from the hot wallet you want to remove, renouncing the link, or
 *   - Submit a transaction from the cold wallet, setting its hot wallet to address(0).
 *
 * When setting a link, there is also the option to pass an expirationTimestamp. This value
 * is in seconds since the epoch. Links will only be good until this time. If an indefinite
 * link is desired, passing in MAX_UINT256 is recommended.
 */
contract HotWalletProxy is
  AccessControlEnumerableUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
  {
  uint256 public constant MAX_HOT_WALLET_COUNT = 128;
  uint256 public constant MAX_UINT256 = type(uint256).max;
  uint256 public constant NOT_FOUND = type(uint256).max;
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  struct WalletLink {
    address walletAddress;
    uint256 expirationTimestamp;
  }

  mapping(address => WalletLink) internal coldWalletToHotWallet;
  mapping(address => WalletLink[]) internal hotWalletToColdWallets;
  mapping(address => bool) internal lockedHotWallets;

  /**
   * expirationTimestamp is kept in seconds since the epoch.
   * In the case where there's no expiration, the expirationTimestamp will be MAX_UINT256.
   */
  event HotWalletChanged(address coldWallet, address from, address to, uint256 expirationTimestamp);

  function initialize(
    address adminAddress,
    address operatorAddress
  )
  public
  initializer
  {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __AccessControlEnumerable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

    _setupRole(OPERATOR_ROLE, _msgSender());
    _setupRole(OPERATOR_ROLE, operatorAddress);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function version()
  external
  pure
  virtual
  returns (string memory) {
    return "1.0.2";
  }

  function _getColdWalletAddresses(
    address hotWalletAddress
  )
  internal
  view
  returns (address[] memory coldWalletAddresses)
  {
    WalletLink[] memory walletLinks = hotWalletToColdWallets[hotWalletAddress];

    uint256 length = walletLinks.length;
    uint256 timestamp = block.timestamp;

    address[] memory addresses = new address[](length);

    bool needsResize = false;
    uint256 index = 0;
    for (uint256 i = 0; i < length;) {
      WalletLink memory walletLink = walletLinks[i];
      if (walletLink.expirationTimestamp >= timestamp) {
        addresses[index] = walletLink.walletAddress;

        unchecked{ ++index; }
      }
      else {
        needsResize = true;
      }

      unchecked{ ++i; }
    }

    /**
     * Resize array down to the correct size, if needed
     */
    if (needsResize) {
      address[] memory resizedAddresses = new address[](index);

      for (uint256 i = 0; i < index;) {
        resizedAddresses[i] = addresses[i];

        unchecked{ ++i; }
      }

      return resizedAddresses;
    }

    return addresses;
  }

  /**
   * Remove expired wallet links, which will reduce the gas cost of future lookups.
   */
  function removeExpiredWalletLinks(
    address hotWalletAddress
  )
  external
  {
    WalletLink[] memory coldWalletLinks = hotWalletToColdWallets[hotWalletAddress];
    uint256 length = coldWalletLinks.length;
    uint256 timestamp = block.timestamp;

    if (length > 0) {
      for (uint256 i = length; i > 0;) {
        uint256 index = i - 1;
        if (coldWalletLinks[index].expirationTimestamp < timestamp) {
          /**
           * Swap with the last element in the array so we can pop the expired item off.
           * Index (length - 1) is already the last item, and doesn't need to swap.
           */
          if (index == length - 1) {
            hotWalletToColdWallets[hotWalletAddress].pop();
          }
          else {
            WalletLink memory toSwap = coldWalletLinks[length - 1];
            hotWalletToColdWallets[hotWalletAddress][index] = toSwap;

            hotWalletToColdWallets[hotWalletAddress].pop();
          }
        }

        unchecked{ --i; }
      }
    }
  }

  /**
   * Returns the index of the cold wallet in the list of cold wallets that
   * point to this hot wallet.
   *
   * Returns NOT_FOUND if not found (we don't support storing this many wallet
   * connections, so this should never be an actual cold wallet's index).
   */
  function _findColdWalletIndex(
    address coldWalletAddress,
    address hotWalletAddress
  )
  internal
  view
  returns (uint256)
  {
    address[] memory coldWallets = _getColdWalletAddresses(hotWalletAddress);

    uint256 length = coldWallets.length;
    for (uint256 i = 0; i < length;) {
      if (coldWallets[i] == coldWalletAddress) {
        return i;
      }

      unchecked{ ++i; }
    }

    return NOT_FOUND;
  }

  function _removeColdWalletFromHotWallet(
    address coldWalletAddress,
    address hotWalletAddress
  )
  internal
  {
    uint256 coldWalletIndex = _findColdWalletIndex(coldWalletAddress, hotWalletAddress);

    if (coldWalletIndex != NOT_FOUND) {
      delete hotWalletToColdWallets[hotWalletAddress][coldWalletIndex];
    }

    this.removeExpiredWalletLinks(hotWalletAddress);
  }

  function _addColdWalletToHotWallet(
    address coldWalletAddress,
    address hotWalletAddress,
    uint256 expirationTimestamp
  )
  internal
  {
    uint256 coldWalletIndex = _findColdWalletIndex(coldWalletAddress, hotWalletAddress);

    if (coldWalletIndex == NOT_FOUND) {
      hotWalletToColdWallets[hotWalletAddress].push(
        WalletLink(
          coldWalletAddress,
          expirationTimestamp
        )
      );
    }
  }

  function _setColdWalletToHotWallet(
    address coldWalletAddress,
    address hotWalletAddress,
    uint256 expirationTimestamp
  )
  internal
  {
    address currentHotWalletAddress = coldWalletToHotWallet[coldWalletAddress].walletAddress;
    coldWalletToHotWallet[coldWalletAddress] = WalletLink(
      hotWalletAddress,
      expirationTimestamp
    );

    emit HotWalletChanged(coldWalletAddress, currentHotWalletAddress, hotWalletAddress, expirationTimestamp);
  }

  /**
   * Submit a transaction from your cold wallet, thus verifying ownership of the cold wallet.
   *
   * If the hot wallet address is already locked, then the only address that can link to it
   * is the cold wallet that's currently linked to it (e.g. to unlink the hot wallet).
   */
  function setHotWallet(
    address hotWalletAddress,
    uint256 expirationTimestamp,
    bool lockHotWalletAddress
  )
  external
  {
    address coldWalletAddress = _msgSender();

    require(coldWalletAddress != hotWalletAddress, "Can't link to self");
    require(coldWalletToHotWallet[coldWalletAddress].walletAddress != hotWalletAddress, "Already linked");

    if (lockedHotWallets[hotWalletAddress]) {
      require(coldWalletToHotWallet[coldWalletAddress].walletAddress == hotWalletAddress, "Hot wallet locked");
    }

    /**
     * Set the hot wallet address for this cold wallet, and notify.
     */
    address currentHotWalletAddress = coldWalletToHotWallet[coldWalletAddress].walletAddress;
    _setColdWalletToHotWallet(coldWalletAddress, hotWalletAddress, expirationTimestamp);

    /**
     * Update the list of cold wallets this hot wallet points to.
     * If the new hot wallet address is address(0), remove the cold wallet
     * from the hot wallet's list of wallets.
     */
    _removeColdWalletFromHotWallet(coldWalletAddress, currentHotWalletAddress);
    if (hotWalletAddress != address(0)) {
      require(hotWalletToColdWallets[hotWalletAddress].length < MAX_HOT_WALLET_COUNT, "Too many linked wallets");

      _addColdWalletToHotWallet(coldWalletAddress, hotWalletAddress, expirationTimestamp);

      if (lockedHotWallets[hotWalletAddress] != lockHotWalletAddress) {
        lockedHotWallets[hotWalletAddress] = lockHotWalletAddress;
      }
    }
  }

  function renounceHotWallet()
  external
  {
    address hotWalletAddress = _msgSender();

    address[] memory coldWallets = _getColdWalletAddresses(hotWalletAddress);

    uint256 length = coldWallets.length;
    for (uint256 i = 0; i < length;) {
      address coldWallet = coldWallets[i];

      _setColdWalletToHotWallet(coldWallet, address(0), 0);

      unchecked{ ++i; }
    }

    delete hotWalletToColdWallets[hotWalletAddress];
  }

  function getHotWallet(address coldWallet)
  external
  view
  returns (address)
  {
    return coldWalletToHotWallet[coldWallet].walletAddress;
  }

  function getHotWalletLink(address coldWallet)
  external
  view
  returns (WalletLink memory)
  {
    return coldWalletToHotWallet[coldWallet];
  }

  function getColdWallets(address hotWallet)
  external
  view
  returns (address[] memory)
  {
    return _getColdWalletAddresses(hotWallet);
  }

  function getColdWalletLinks(address hotWallet)
  external
  view
  returns (WalletLink[] memory)
  {
    return hotWalletToColdWallets[hotWallet];
  }

  function isLocked(address hotWallet)
  external
  view
  returns (bool)
  {
    return lockedHotWallets[hotWallet];
  }

  function setLocked(
    bool locked
  )
  external
  {
    lockedHotWallets[_msgSender()] = locked;
  }

  /**
   * This must be called from the cold wallet, so a once-granted hot wallet can't arbitrarily
   * extend its link forever.
   */
  function setExpirationTimestamp(
    uint256 expirationTimestamp
  )
  external
  {
    address coldWalletAddress = _msgSender();
    address hotWalletAddress = coldWalletToHotWallet[coldWalletAddress].walletAddress;

    if (hotWalletAddress != address(0)) {
      coldWalletToHotWallet[coldWalletAddress].expirationTimestamp = expirationTimestamp;

      WalletLink[] memory coldWalletLinks = hotWalletToColdWallets[hotWalletAddress];
      uint256 length = coldWalletLinks.length;

      for (uint256 i = 0; i < length;) {
        if (coldWalletLinks[i].walletAddress == coldWalletAddress) {
          hotWalletToColdWallets[hotWalletAddress][i].expirationTimestamp = expirationTimestamp;
          emit HotWalletChanged(coldWalletAddress, hotWalletAddress, hotWalletAddress, expirationTimestamp);
        }

        unchecked{ ++i; }
      }
    }
  }

  /**
   * Return the hot wallet address, if this is a cold wallet.
   */
  function getProxiedAddress(
    address walletAddress
  )
  public
  view
  returns(
    address
  )
  {
    address hotWallet = coldWalletToHotWallet[walletAddress].walletAddress;

    if (hotWallet != address(0)) {
      return hotWallet;
    }

    return walletAddress;
  }

  /**
   * ERC721 Methods
   */
  function balanceOf(
    address contractAddress,
    address owner
  )
  external
  view
  returns (
    uint256
  )
  {
    ERC721Interface erc721Contract = ERC721Interface(contractAddress);

    address[] memory coldWallets = _getColdWalletAddresses(owner);

    uint256 total = 0;
    uint256 length = coldWallets.length;
    for (uint256 i = 0; i < length;) {
      address coldWallet = coldWallets[i];

      total += erc721Contract.balanceOf(coldWallet);

      unchecked{ ++i; }
    }

    return total + erc721Contract.balanceOf(owner);
  }

  function ownerOf(
    address contractAddress,
    uint256 tokenId
  )
  external
  view
  returns (
    address
  )
  {
    ERC721Interface erc721Contract = ERC721Interface(contractAddress);

    address owner = erc721Contract.ownerOf(tokenId);

    return getProxiedAddress(owner);
  }

  /**
   * ERC1155 Methods
   */
  function balanceOfBatch(
    address contractAddress,
    address[] calldata owners,
    uint256[] calldata ids
  )
  external
  view
  returns(
    uint256[] memory
  )
  {
    require(owners.length == ids.length, "Mismatched owners and ids");

    ERC1155Interface erc1155Contract = ERC1155Interface(contractAddress);

    uint256 ownersLength = owners.length;

    uint256[] memory totals = new uint256[](ownersLength);

    for (uint256 i = 0; i < ownersLength;) {
      address owner = owners[i];
      uint256 id = ids[i];

      /**
       * Sum the balance of the owner's wallet with the balance of all of the
       * cold wallets linking to it.
       */
      address[] memory coldWallets = _getColdWalletAddresses(owner);
      uint256 coldWalletsLength = coldWallets.length;

      uint256 allWalletsLength = coldWallets.length;

      /**
       * The ordering of addresses in allWallets is:
       * [
       *   ...coldWallets,
       *   owner
       * ]
       */
      address[] memory allWallets = new address[](allWalletsLength + 1);
      uint256[] memory batchIds = new uint256[](allWalletsLength + 1);

      allWallets[allWalletsLength] = owner;
      batchIds[allWalletsLength] = id;

      for (uint256 j = 0; j < coldWalletsLength;) {
        address coldWallet = coldWallets[j];

        allWallets[j] = coldWallet;
        batchIds[j] = id;

        unchecked{ ++j; }
      }

      uint256[] memory balances = erc1155Contract.balanceOfBatch(allWallets, batchIds);

      uint256 total = 0;
      uint256 balancesLength = balances.length;
      for (uint256 j = 0; j < balancesLength;) {
        total += balances[j];

        unchecked{ ++j; }
      }

      totals[i] = total;

      unchecked{ ++i; }
    }

    return totals;
  }

  function balanceOf(
    address contractAddress,
    address owner,
    uint256 tokenId
  )
  external
  view
  returns (
    uint256
  )
  {
    ERC1155Interface erc1155Contract = ERC1155Interface(contractAddress);

    address[] memory coldWallets = _getColdWalletAddresses(owner);

    uint256 total = 0;
    uint256 length = coldWallets.length;
    for (uint256 i = 0; i < length;) {
      address coldWallet = coldWallets[i];

      total += erc1155Contract.balanceOf(coldWallet, tokenId);

      unchecked{ ++i; }
    }

    return total + erc1155Contract.balanceOf(owner, tokenId);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}