// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CallerIsNotPanicOwner();
error CallerIsNotWhitelistedDepositor();
error CannotChangePanicDetailsOnLockedVault();
error EtherTransferWasUnsuccessful();
error MustSendAssetsToAtLeastOneRecipient();
error Unsupported1155Interface();
error Unsupported721Interface();

/**
  @title A vault for securely holding assets. This vault can hold Ether, ERC-20
    tokens, ERC-721 tokens, or ERC-1155 tokens.
  @author Tim Clancy
  @author Egor Dergunov

  The context of this vault contract is such that it is intended for use when
  owned by a separate multisignature-driven timelock contract. The justification
  for the timelock is such that, if the multisignature wallet is compromised,
  this vault empowers signatories to mitigate potential damage from an attacker
  via the `panic` function.

  It is recommended that assets be sent to this vault using the `deposit`
  function, which will correctly configure contract storage such that the
  `panic` function covers all assets. In the event that using `deposit` is not
  possible, assets may be manually configured via the `configure` function.

  August 30th, 2022.
*/
contract AssetVault is
  ERC721Holder,
  ERC1155Holder,
  Ownable,
  ReentrancyGuard
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /**
    The ERC-165 interface identifier for ERC-721. We use this to detect whether
    or not an asset in this vault is actually a valid ERC-721 item.
  */
  bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;

  /**
    The ERC-165 interface identifier for ERC-1155. We use this to detect whether
    or not an asset in this vault is actually a valid ERC-1155 item.
  */
  bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;

  /// A version number for this TokenVault contract's interface.
  uint256 public constant version = 2;

  /// A user-specified, descriptive name for this TokenVault.
  string public name;

  /**
    The panic owner is an optional address allowed to immediately send the
    contents of the vault to the address specified in `panicDestination`. The
    intention of this system is to support a series of cascading vaults secured
    by their own multisignature wallets. If, for instance, vault one is
    compromised via its attached multisignature wallet, vault two could
    intercede to save the tokens from vault one before the malicious token send
    clears the owning timelock.
  */
  address public panicOwner;

  /**
    An address where tokens may be immediately sent by `panicOwner`. If this
    address is the zero address, then the vault will attempt to burn assets
    immediately upon panic.
  */
  address public panicDestination;

  /**
    A counter to limit the number of times a vault can panic before taking a
    final emergency action on the underlying supply of tokens. This limit is in
    place to protect against a situation where multiple vaults linked in a
    cycle are all compromised. In the event of such an attack, this still gives
    the original multisignature holders the chance to either evacuate or burn
    the tokens by repeatedly calling `panic` before the attacker can use `send`.

    When the panic limit is reached, assets will be sent to
    `evacuationDestination`. If they fail to transfer, they will be burnt.
  */
  uint256 public immutable panicLimit;

  /**
    An address where tokens are attempted to be evacuated to in the event the
    `panicLimit` is tripped.
  */
  address public immutable evacuationDestination;

  /**
    A backup burn destination to use in the event that an asset is not
    conventionally-burnable, i.e. cannot be burnt using a `burn` function. It is
    recommended to use a recognized blackhole address such as `0x...DEAD`.
  */
  address public immutable backupBurnDestination;

  /**
    A mapping for certifying whether or not a particular caller is a whitelisted
    depositor. Only the owner of this contract may add or remove depositors.
  */
  mapping ( address => bool ) public depositors;

  /**
    A flag to determine whether or not alteration of this vault's `panicOwner`
    and `panicDestination` panic routing details have been locked.
  */
  bool public panicDetailsLocked;

  /// A counter for the number of times this vault has panicked.
  uint256 public panicCounter;

  /**
    An enumerable set that stores values of ERC-20 contract addresses which are
    known to the `panic` function. Assets handled via `deposit` will be
    automatically added to this set' they may otherwise be configured via
    `configure`.
  */
  EnumerableSet.AddressSet private erc20Assets;

  /**
    An enumerable set that stores values of ERC-721 contract addresses which are
    known to the `panic` function. Assets handled via `deposit` will be
    automatically added to this set' they may otherwise be configured via
    `configure`.
  */
  EnumerableSet.AddressSet private erc721Assets;

  /**
    An enumerable set that stores values of ERC-1155 contract addresses which
    are known to the `panic` function. Assets handled via `deposit` will be
    automatically added to this set' they may otherwise be configured via
    `configure`.
  */
  EnumerableSet.AddressSet private erc1155Assets;

  /**
    Enumerate all possible asset types which this vault may handle. These asset
    types are used to flag the type of each `Asset` struct when handling the
    transfer of specific tokens.

    @param Ether This value denotes that an asset is Ether.
    @param ERC20 This value denotes that an asset is an ERC-20 token.
    @param ERC721 This value denotes that an asset is an ERC-721 token.
    @param ERC1155 This value denotes that an asset is an ERC-1155 token.
  */
  enum AssetType {
    Ether,
    ERC20,
    ERC721,
    ERC1155
  }

  /**
    This struct defines one or more instances of a single specific type of asset
    in this vault. It is used to prepare this vault's configuration to accept
    ERC-20, ERC-721, and ERC-1155 tokens. It is used when sending tokens to
    specify the amount of the specific asset to send. In the case of ERC-721
    items, it specifies the particular IDs under a contract address to send. In
    the case of ERC-1155 items, it specifies the particular IDs and their
    corresponding amounts to send.

    @param assetType An `AssetType` type to classify this asset.
    @param amounts An array of token amounts, keyed against the elements in
      `ids`. In the case that `assetType` is Ether or ERC20, this should be a
      singleton array containing just the amount that should be transfered.
    @param ids An array of IDs which should be transfered in the event that
      `assetType` is ERC721 or ERC1155.
  */
  struct Asset {
    AssetType assetType;
    uint256[] amounts;
    uint256[] ids;
  }

  /**
    This mapping links the addresses of ERC-721 or ERC-1155 item collections to
    `Asset` structs that indicate the current holdings of this vault.
  */
  mapping ( address => Asset ) public assets;

  /**
    This struct defines a single operation on some single specific type of asset
    in this vault. It is used to prepare this vault's configuration to accept
    ERC-20, ERC-721, and ERC-1155 tokens. It is used when sending tokens to
    specify the amount of the specific asset to send. In the case of ERC-721
    items, it specifies the particular IDs under a contract address to send. In
    the case of ERC-1155 items, it specifies the particular IDs and their
    corresponding amounts to send. It includes the address of the smart contract
    which the `Asset` struct otherwise lacks.

    @param assetType An `AssetType` type to classify this asset.
    @param assetAddress The address of the asset's smart contract.
    @param amounts An array of token amounts, keyed against the elements in
      `ids`. In the case that `assetType` is Ether or ERC20, this should be a
      singleton array containing just the amount that should be transfered.
    @param ids An array of IDs which should be transfered in the event that
      `assetType` is ERC721 or ERC1155.
  */
  struct AssetSpecification {
    AssetType assetType;
    address assetAddress;
    uint256[] amounts;
    uint256[] ids;
  }

  /**
    This struct defines the information required to send some single specific
    type of asset in this vault to a recipient. It is used when sending tokens
    to specify the amount of the specific asset to send. In the case of ERC-721
    items, it specifies the particular IDs under a contract address to send. In
    the case of ERC-1155 items, it specifies the particular IDs and their
    corresponding amounts to send. It includes the address of the smart contract
    which the `Asset` struct otherwise lacks.

    @param assetType An `AssetType` type to classify this asset.
    @param recipientAddress The address of the recipient to send the asset to.
    @param assetAddress The address of the asset's smart contract.
    @param amounts An array of token amounts, keyed against the elements in
      `ids`. In the case that `assetType` is Ether or ERC20, this should be a
      singleton array containing just the amount that should be transfered.
    @param ids An array of IDs which should be transfered in the event that
      `assetType` is ERC721 or ERC1155.
  */
  struct SendSpecification {
    AssetType assetType;
    address recipientAddress;
    address assetAddress;
    uint256[] amounts;
    uint256[] ids;
  }

  /**
    This struct defines the information required to update the whitelist status
    of a specific potential depositor address. This allows the owner of this
    vault to control which callers may or may not deposit assets.

    @param depositor The address of the depositor to update.
    @param status Whether or not the `depositor` should be whitelisted.
  */
  struct UpdateDepositor {
    address depositor;
    bool status;
  }

  /**
    An event for tracking a deposit of assets into this vault.

    @param etherAmount The amount of Ether that was deposited.
    @param erc20Count The number of different instances of ERC-20 tokens
      deposited.
    @param erc721Count The number of different instances of deposits from
      different ERC-721 addresses.
    @param erc1155Count The number of different instances of deposits from
      different ERC-1155 addresses.
  */
  event Deposit (
    uint256 etherAmount,
    uint256 erc20Count,
    uint256 erc721Count,
    uint256 erc1155Count
  );

  /// An event emitted when vault asset reconfiguration occurs.
  event Reconfigured ();

  /**
    An event for tracking a disbursement of assets from this vault.

    @param etherAmount The amount of Ether that was transferred.
    @param erc20Count The number of different instances of ERC-20 token
      transfers.
    @param erc721Count The number of different instances of transfers from
      different ERC-721 addresses.
    @param erc1155Count The number of different instances of transfers from
      different ERC-1155 addresses.
  */
  event Send (
    uint256 etherAmount,
    uint256 erc20Count,
    uint256 erc721Count,
    uint256 erc1155Count
  );

  /**
    An event for tracking a change in panic details.

    @param panicOwner The address of this vault's new panic owner.
    @param panicDestination The address of the vault's new panic destination.
  */
  event PanicDetailsChange (
    address indexed panicOwner,
    address indexed panicDestination
  );

  /// An event for tracking a lock on alteration of panic details.
  event PanicDetailsLocked ();

  /**
    An event for tracking a panic transfer of tokens. This kind of emergency
    operation attempts to destroy all assets in the vault.

    @param panicCounter The count of the number of times the vault has panicked
      when this event is emitted.
    @param etherAmount The amount of Ether that was burnt.
    @param erc20Count The number of different ERC-20 tokens that were burnt.
    @param erc721Count The number of different ERC-721 addresses from which
      items were burnt.
    @param erc1155Count The number of different ERC-1155 addresses from which
      items were burnt.
  */
  event PanicBurn (
    uint256 panicCounter,
    uint256 etherAmount,
    uint256 erc20Count,
    uint256 erc721Count,
    uint256 erc1155Count
  );

  /**
    An event for tracking a panic transfer of tokens. This kind of emergency
    transfer is initiated by the `panicOwner` and sends all vault assets to the
    `panicDestination`.

    @param panicCounter The count of the number of times the vault has panicked
      when this event is emitted.
    @param etherAmount The amount of Ether that was panic transferred.
    @param erc20Count The number of different ERC-20 tokens that were panic
      transferred.
    @param erc721Count The number of different ERC-721 addresses from which
      items were panic transferred.
    @param erc1155Count The number of different ERC-1155 addresses from which
      items were panic transferred.
    @param panicDestination The address that the items were transferred to.
  */
  event PanicTransfer (
    uint256 panicCounter,
    uint256 etherAmount,
    uint256 erc20Count,
    uint256 erc721Count,
    uint256 erc1155Count,
    address indexed panicDestination
  );

  /**
    An event for tracking when the whitelist status of a depositor changes.

    @param depositor The depositor whose whitelist status has changed.
    @param isWhitelisted Whether or not the depositor is allowed to deposit.
  */
  event WhitelistedDepositor (
    address indexed depositor,
    bool isWhitelisted
  );

  /**
    An event indicating that the vault contract has received Ether.

    @param caller The address of the caller which sent Ether to this vault.
    @param amount The amount of Ether that `caller` sent to this vault.
  */
  event Receive (
    address caller,
    uint256 amount
  );

  /// A modifier to see if a caller is a member of the whitelisted `depositors`.
  modifier onlyDepositors () {
    if (!depositors[_msgSender()]) {
      revert CallerIsNotWhitelistedDepositor();
    }
    _;
  }

  /// A modifier to see if a caller is the `panicOwner`.
  modifier onlyPanicOwner () {
    if (panicOwner != _msgSender()) {
      revert CallerIsNotPanicOwner();
    }
    _;
  }

  /**
    Construct a new asset vault by providing it a name and configuration details
    for the vault's panic routing features.

    Please note that if the goal is to support emergency token burning without
    reaching the panic limit, consider using an address such as `0x...DEAD`
    instead of the zero address as the `_panicDestination`. This will result in
    better support for non-burnable tokens.

    @param _name The name of this vault.
    @param _panicOwner The address to grant emergency withdrawal powers to.
    @param _panicDestination The destination to withdraw to in emergency.
    @param _panicLimit A limit for the number of times `panic` can be called
      before assets are self-destructed.
    @param _evacuationDestination An address where tokens are attempted to be
      evacuated to in the event the `panicLimit` is tripped.
    @param _backupBurnDestination A backup burn destination to use in the event
      that an asset is not conventionally-burnable.
  */
  constructor (
    string memory _name,
    address _panicOwner,
    address _panicDestination,
    uint256 _panicLimit,
    address _evacuationDestination,
    address _backupBurnDestination
  ) {
    name = _name;
    panicOwner = _panicOwner;
    panicDestination = _panicDestination;
    panicLimit = _panicLimit;
    evacuationDestination = _evacuationDestination;
    backupBurnDestination = _backupBurnDestination;
  }

  /**
    A private helper function to configure this vault to add assets to the
    contract that may have been directly transferred without using `deposit`.
    Assets must first be configured in order to be transferrable via `panic`.

    @param _assets An array of `AssetSpecification` structs containing
      configuration details about each asset being configured.
  */
  function _configure (
    AssetSpecification[] memory _assets
  ) private {

    /*
      If it isn't already present, add each asset being configured to its
      appropriate set. Then, update the asset details mapping.
    */
    for (uint256 i = 0; i < _assets.length;) {

      // Add any new ERC-20 token addresses.
      if (_assets[i].assetType == AssetType.ERC20 &&
        !erc20Assets.contains(_assets[i].assetAddress)) {
        erc20Assets.add(_assets[i].assetAddress);
      }

      // Add any new ERC-721 token addresses.
      if (_assets[i].assetType == AssetType.ERC721 &&
        !erc721Assets.contains(_assets[i].assetAddress)) {
        erc721Assets.add(_assets[i].assetAddress);
      }

      // Add any new ERC-1155 token addresses.
      if (_assets[i].assetType == AssetType.ERC1155 &&
        !erc1155Assets.contains(_assets[i].assetAddress)) {
        erc1155Assets.add(_assets[i].assetAddress);
      }

      // Update the asset details mapping.
      assets[_assets[i].assetAddress] = Asset({
        assetType: _assets[i].assetType,
        ids: _assets[i].ids,
        amounts: _assets[i].amounts
      });
      unchecked { ++i; }
    }

    // Emit an event indicating that reconfiguration occurred.
    emit Reconfigured();
  }

  /**
    Deposit assets directly into this vault such that panic details are
    automatically configured. Calling this deposit function requires first
    approving any involved assets for transfer.

    @param _assets An array of `AssetSpecification` structs containing
      configuration details about each asset being deposited.
  */
  function deposit (
    AssetSpecification[] memory _assets
  ) external payable nonReentrant onlyDepositors {

    // Transfer each asset to the vault. This requires approving the vault.
    uint256 erc20Count = 0;
    uint256 erc721Count = 0;
    uint256 erc1155Count = 0;
    for (uint256 i = 0; i < _assets.length;) {
      address assetAddress = _assets[i].assetAddress;
      AssetSpecification memory asset = _assets[i];

      // Send ERC-20 tokens to the vault.
      if (asset.assetType == AssetType.ERC20) {
        uint256 amount = asset.amounts[0];
        IERC20(assetAddress).safeTransferFrom(
          _msgSender(),
          address(this),
          amount
        );
        erc20Count += 1;
      }

      // Send ERC-721 tokens to the recipient.
      if (asset.assetType == AssetType.ERC721) {
        IERC721 item = IERC721(assetAddress);

        // Only attempt to send valid ERC-721 items.
        if (!item.supportsInterface(
          ERC721_INTERFACE_ID
        )) {
          revert Unsupported721Interface();
        }

        // Perform a transfer of each asset.
        for (uint256 j = 0; j < asset.ids.length;) {
          item.safeTransferFrom(
            _msgSender(),
            address(this),
            asset.ids[j]
          );
          unchecked { ++j; }
        }
        erc721Count += 1;
      }

      // Send ERC-1155 tokens to the recipient.
      if (asset.assetType == AssetType.ERC1155) {
        IERC1155 item = IERC1155(assetAddress);

        // Only attempt to send valid ERC-1155 items.
        if (!item.supportsInterface(
          ERC1155_INTERFACE_ID
        )) {
          revert Unsupported1155Interface();
        }

        // Perform a transfer of each asset.
        item.safeBatchTransferFrom(
          _msgSender(),
          address(this),
          asset.ids,
          asset.amounts,
          ""
        );
        erc1155Count += 1;
      }
      unchecked { ++i; }
    }

    // Configure all assets which were just deposited.
    _configure(_assets);

    // Emit a deposit event.
    emit Deposit(msg.value, erc20Count, erc721Count, erc1155Count);
  }

  /**
    Configure this vault to add assets to the contract that may have been
    directly transferred without using `deposit`. Assets must first be
    configured in order to be transferrable via `panic`.

    @param _assets An array of `AssetSpecification` structs containing
      configuration details about each asset being configured.
  */
  function configure (
    AssetSpecification[] memory _assets
  ) external nonReentrant onlyOwner {
    _configure(_assets);
  }

  /**
    This private helper function removes from panic storage the particular
    `_asset` details from their corresponding contract addresses because said
    assets were transferred out of the vault and should no longer be tracked.

    @param _asset An `AssetSpecification` struct tracking the assets which were
      transferred and ought to be removed from panic storage.
  */
  function _removeToken (
    AssetSpecification memory _asset
  ) private {

    // Remove a tracked ERC-20 asset if the vault no longer has a balance.
    if (_asset.assetType == AssetType.ERC20) {
      IERC20 token = IERC20(_asset.assetAddress);
      uint256 balance = token.balanceOf(address(this));
      if (balance == 0) {
        erc20Assets.remove(_asset.assetAddress);
      }
    }

    // Remove an ERC-721 asset entirely if the vault no longer has a balance.
    if (_asset.assetType == AssetType.ERC721) {
      IERC721 token = IERC721(_asset.assetAddress);
      uint256 balance = token.balanceOf(address(this));
      if (balance == 0) {
        erc721Assets.remove(_asset.assetAddress);

      // The vault still carries a balance; remove particular ERC-721 token IDs.
      } else {

        // Remove specific elements in `_asset` from the storage asset.
        uint256[] storage oldIds = assets[_asset.assetAddress].ids;
        for (uint256 i; i < oldIds.length;) {
          for (uint256 j = 0; j < _asset.ids.length;) {
            uint256 candidateId = _asset.ids[j];

            // Remove the element at the matching index.
            if (candidateId == oldIds[i]) {
              if (i != oldIds.length - 1) {
                oldIds[i] = oldIds[oldIds.length - 1];
              }
              oldIds.pop();
              break;
            }
            unchecked { ++j; }
          }
          unchecked { ++i; }
        }
      }
    }

    /*
      Reduce the tracked supply of each ERC-1155 item in this vault. Remove a
      tracked ID entirely if its supply is zero. Removed a tracked ERC-1155 item
      entirely if no IDs are held.
    */
    if (_asset.assetType == AssetType.ERC1155) {

      // Reduce the amount held of specific IDs in `_asset`.
      uint256[] storage oldIds = assets[_asset.assetAddress].ids;
      uint256[] storage oldAmounts = assets[_asset.assetAddress].amounts;
      for (uint256 i; i < oldIds.length;) {
        for (uint256 j = 0; j < _asset.ids.length;) {
          uint256 candidateId = _asset.ids[j];
          uint256 candidateAmount = _asset.amounts[j];

          // Process the element at the matching index.
          if (candidateId == oldIds[i]) {

            /*
              We are removing the entire supply of the specified token ID and
              therefore should remove the ID being tracked in `assets` entirely.
            */
            if (candidateAmount == oldAmounts[i]) {
              if (i != oldIds.length - 1) {
                oldIds[i] = oldIds[oldIds.length - 1];
                oldAmounts[i] = oldAmounts[oldAmounts.length - 1];
              }
              oldIds.pop();
              oldAmounts.pop();

            // Otherwise, we are only removing some of the supply.
            } else {
              oldAmounts[i] -= candidateAmount;
            }
            break;
          }
          unchecked { ++j; }
        }
        unchecked { ++i; }
      }

      // If we removed every component ID, remove the ERC-1155 asset entirely.
      if (oldIds.length == 0) {
        erc1155Assets.remove(_asset.assetAddress);
      }
    }
  }

  /**
    Allows this vault's owner to send assets out of the vault.

    @param _sends An array of `SendSpecification` structs that each request
      sending some specific assets from this vault to a recipient.
  */
  function send (
    SendSpecification[] memory _sends
  ) external nonReentrant onlyOwner {
    if (_sends.length == 0) {
      revert MustSendAssetsToAtLeastOneRecipient();
    }

    /*
      Iterate through every specified recipient and send them each corresponding
      asset in the correct amount.
    */
    uint256 totalEth = 0;
    uint256 erc20Count = 0;
    uint256 erc721Count = 0;
    uint256 erc1155Count = 0;
    for (uint256 i = 0; i < _sends.length;) {
      SendSpecification memory send = _sends[i];

      // Send Ether to the recipient.
      if (send.assetType == AssetType.Ether) {
        uint256 amount = send.amounts[0];
        (bool success, ) = send.recipientAddress.call{ value: amount }("");
        if (!success) {
          revert EtherTransferWasUnsuccessful();
        }
        totalEth += amount;
      }

      // Send ERC-20 tokens to the recipient.
      if (send.assetType == AssetType.ERC20) {
        uint256 amount = send.amounts[0];
        IERC20(send.assetAddress).safeTransfer(send.recipientAddress, amount);
        erc20Count += 1;
      }

      // Send ERC-721 tokens to the recipient.
      if (send.assetType == AssetType.ERC721) {
        IERC721 item = IERC721(send.assetAddress);

        // Only attempt to send valid ERC-721 items.
        if (!item.supportsInterface(
          ERC721_INTERFACE_ID
        )) {
          revert Unsupported721Interface();
        }

        // Perform a transfer of each asset.
        for (uint256 j = 0; j < send.ids.length;) {
          item.safeTransferFrom(
            address(this),
            send.recipientAddress,
            send.ids[j]
          );
          unchecked { ++j; }
        }
        erc721Count += 1;
      }

      // Send ERC-1155 tokens to the recipient.
      if (send.assetType == AssetType.ERC1155) {
        IERC1155 item = IERC1155(send.assetAddress);

        // Only attempt to send valid ERC-1155 items.
        if (!item.supportsInterface(
          ERC1155_INTERFACE_ID
        )) {
          revert Unsupported1155Interface();
        }

        // Perform a transfer of each asset.
        item.safeBatchTransferFrom(
          address(this),
          send.recipientAddress,
          send.ids,
          send.amounts,
          ""
        );
        erc1155Count += 1;
      }

      // Remove the transferred asset from vault storage.
      _removeToken(AssetSpecification({
        assetAddress: send.assetAddress,
        assetType: send.assetType,
        ids: send.ids,
        amounts: send.amounts
      }));
      unchecked { ++i; }
    }

    // Emit an event tracking details about this asset transfer.
    emit Send(totalEth, erc20Count, erc721Count, erc1155Count);
  }

  /**
    Allow the owner of this vault to update the `panicOwner` and
    `panicDestination` details governing its panic functionality.

    @param _panicOwner The new panic owner to set.
    @param _panicDestination The new emergency destination to send tokens to.
  */
  function changePanicDetails (
    address _panicOwner,
    address _panicDestination
  ) external nonReentrant onlyOwner {
    if (panicDetailsLocked) {
      revert CannotChangePanicDetailsOnLockedVault();
    }

    // Panic details are not locked, so update them and emit an event.
    panicOwner = _panicOwner;
    panicDestination = _panicDestination;
    emit PanicDetailsChange(panicOwner, panicDestination);
  }

  /**
    Allow the owner of the vault to lock the the state of `panicOwner` and
    `panicDestination` to prevent all future panic detail changes.
  */
  function lock () external nonReentrant onlyOwner {
    panicDetailsLocked = true;
    emit PanicDetailsLocked();
  }

  /**
    Allow this vault's `panicOwner` to immediately send the contents of this
    vault to the predefined `panicDestination`. This can be used to circumvent
    the timelock in case of an emergency.
  */
  function panic () external nonReentrant onlyPanicOwner {
    uint256 totalBalanceEth = address(this).balance;
    uint256 totalAmountERC20 = erc20Assets.length();
    uint256 totalAmountERC721 = erc721Assets.length();
    uint256 totalAmountERC1155 = erc1155Assets.length();

    /*
      If the panic limit is reached, or the panic destination is the zero
      address, attempt to burn all assets in the vault.
    */
    if (panicCounter == panicLimit || panicDestination == address(0)) {
      address targetedAddress = evacuationDestination;
      if (panicDestination == address(0)) {
        targetedAddress = address(0);
      }

      // Attempt to burn all Ether; we proceed whether this succeeds or not.
      address(targetedAddress).call{ value: totalBalanceEth }("");

      /*
        Attempt to burn all ERC-20 tokens. If they supply a burn function, we
        will try to use it. In the event that a "proper" burn fails, we will
        transfer the tokens to a configurable backup burn address.
      */
      for (uint256 i = 0; i < totalAmountERC20;) {
        address assetAddress = erc20Assets.at(i);
        IERC20 token = IERC20(assetAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        if (targetedAddress == address(0)) {
          ERC20Burnable burnable = ERC20Burnable(assetAddress);
          try burnable.burn(tokenBalance) {
          } catch {
            token.safeTransfer(backupBurnDestination, tokenBalance);
          }
        } else {
          try token.transfer(targetedAddress, tokenBalance) {
          } catch {
            token.safeTransfer(backupBurnDestination, tokenBalance);
          }
        }
        unchecked { ++i; }
      }

      /*
        Attempt to burn all ERC-721 items held by this vault. Invalid items will
        be left behind.
      */
      for (uint256 i = 0; i < totalAmountERC721;) {
        address assetAddress = erc721Assets.at(i);
        IERC721 item = IERC721(assetAddress);
        Asset memory asset = assets[assetAddress];

        /*
          Panic burning is an emergency self-destruct and therefore we will not
          fail upon encountering potentially-invalid items. It is more important
          to ensure that whatever items may be burnt are burnt.
        */
        if (item.supportsInterface(ERC721_INTERFACE_ID)) {
          for (uint256 j = 0; j < asset.ids.length;) {
            if (targetedAddress == address(0)) {
              ERC721Burnable burnable = ERC721Burnable(assetAddress);
              try burnable.burn(asset.ids[j]) {
              } catch {
                item.safeTransferFrom(
                  address(this),
                  backupBurnDestination,
                  asset.ids[j]
                );
              }
            } else {
              try item.safeTransferFrom(
                address(this),
                targetedAddress,
                asset.ids[j]
              ) {
              } catch {
                item.safeTransferFrom(
                  address(this),
                  backupBurnDestination,
                  asset.ids[j]
                );
              }
            }
            unchecked { ++j; }
          }
        }
        unchecked { ++i; }
      }

      /*
        Attempt to transfer all ERC-1155 items held by this vault. Invalid items
        will be left behind.
      */
      for (uint256 i = 0; i < totalAmountERC1155;) {
        address assetAddress = erc1155Assets.at(i);
        IERC1155 item = IERC1155(assetAddress);
        Asset memory asset = assets[assetAddress];

        /*
          Panic burning is an emergency self-destruct and therefore we will not
          fail upon encountering potentially-invalid items. It is more important
          to ensure that whatever items may be burnt are burnt.
        */
        if (item.supportsInterface(ERC1155_INTERFACE_ID)) {
          if (targetedAddress == address(0)) {
            ERC1155Burnable burnable = ERC1155Burnable(assetAddress);
            try burnable.burnBatch(
              address(this),
              asset.ids,
              asset.amounts
            ) {
            } catch {
              item.safeBatchTransferFrom(
                address(this),
                backupBurnDestination,
                asset.ids,
                asset.amounts,
                ""
              );
            }
          } else {
            try item.safeBatchTransferFrom(
              address(this),
              targetedAddress,
              asset.ids,
              asset.amounts,
              ""
            ) {
            } catch {
              item.safeBatchTransferFrom(
                address(this),
                backupBurnDestination,
                asset.ids,
                asset.amounts,
                ""
              );
            }
          }
        }
        unchecked { ++i; }
      }

      // Emit an event recording the panic burn that happened.
      emit PanicBurn(
        panicCounter,
        totalBalanceEth,
        totalAmountERC20,
        totalAmountERC721,
        totalAmountERC1155
      );

    /*
      Attempt a panic transfer to immediately send all assets to the
      configured `panicDestination`.
    */
    } else {

      // Attempt to transfer all Ether.
      (bool success, ) = panicDestination.call{ value: totalBalanceEth }("");
      if (!success) {
        revert EtherTransferWasUnsuccessful();
      }

      /*
        Attempt to transfer all ERC-20 tokens. For each token in the ERC-20
        assets set, retrieve this vault's balance and transfer it to the
        `panicDestination`.
      */
      for (uint256 i = 0; i < totalAmountERC20;) {
        IERC20 token = IERC20(erc20Assets.at(i));
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(panicDestination, tokenBalance);
        unchecked { ++i; }
      }

      /*
        Attempt to transfer all ERC-721 items held by this vault. Invalid items
        will be left behind.
      */
      for (uint256 i = 0; i < totalAmountERC721;) {
        address assetAddress = erc721Assets.at(i);
        IERC721 item = IERC721(assetAddress);
        Asset memory asset = assets[assetAddress];

        /*
          Panic is an emergency withdrawal function and therefore we will not
          fail upon encountering potentially-invalid items. It is more important
          to ensure that whatever items may be properly transferred are properly
          transferred.
        */
        if (item.supportsInterface(ERC721_INTERFACE_ID)) {
          for (uint256 j = 0; j < asset.ids.length;) {
            item.safeTransferFrom(
              address(this),
              panicDestination,
              asset.ids[j]
            );
            unchecked { ++j; }
          }
        }
        unchecked { ++i; }
      }

      /*
        Attempt to transfer all ERC-1155 items held by this vault. Invalid items
        will be left behind.
      */
      for (uint256 i = 0; i < totalAmountERC1155;) {
        address assetAddress = erc1155Assets.at(i);
        IERC1155 item = IERC1155(assetAddress);
        Asset memory asset = assets[assetAddress];

        /*
          Panic is an emergency withdrawal function and therefore we will not
          fail upon encountering potentially-invalid items. It is more important
          to ensure that whatever items may be properly transferred are properly
          transferred.
        */
        if (item.supportsInterface(ERC1155_INTERFACE_ID)) {
          item.safeBatchTransferFrom(
            address(this),
            panicDestination,
            asset.ids,
            asset.amounts,
            ""
          );
        }
        unchecked { ++i; }
      }

      // Record the happening of this panic operation and emit an event.
      panicCounter += 1;
      emit PanicTransfer(
        panicCounter,
        totalBalanceEth,
        totalAmountERC20,
        totalAmountERC721,
        totalAmountERC1155,
        panicDestination
      );
    }
  }

  /**
    Configure this vault by updating the whitelisted depositing status of
    various potential depositors.

    @param _depositors An array of `UpdateDepositor` structs containing
      configuration details about each depositor being updated.
  */
  function updateDepositors (
    UpdateDepositor[] memory _depositors
  ) external nonReentrant onlyOwner {
    for (uint256 i = 0; i < _depositors.length;) {
      UpdateDepositor memory update = _depositors[i];
      depositors[update.depositor] = update.status;
      emit WhitelistedDepositor(update.depositor, update.status);
      unchecked { ++i; }
    }
  }

  /**
    Emit a payment receipt event upon this vault receiving Ether.
  */
  receive () external payable {
    emit Receive(_msgSender(), msg.value);
  }
}