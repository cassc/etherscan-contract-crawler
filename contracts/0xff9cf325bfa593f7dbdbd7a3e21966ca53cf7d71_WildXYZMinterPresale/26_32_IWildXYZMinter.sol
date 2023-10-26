// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

pragma solidity ^0.8.17;

interface IDelegationRegistry {
  /** @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
   * @param delegate The hotwallet to act on your behalf
   * @param contract_ The address for the contract you're delegating
   * @param vault The cold wallet who issued the delegation
   */
  function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);
}

interface IWildXYZMinter {
  // enums

  /// @dev States for the minter
  enum State {
    Setup, // also "comingsoon"
    Live, // defer to phases for state name
    Complete, // also "soldout"
    Paused // temporary paused state
  }

  enum MintType {
    // DO NOT CHANGE ORDERING - APPEND ONLY
    // DO NOT CHANGE ORDERING, I WILL FIND YOU AND MAKE YOU PAY FOR YOUR SINS
    // DO NOT CHANGE ORDERING - APPEND ONLY

    // promo mint types
    Promo,
    CreditCard,
    WildPass,
    // groups
    Oasis,
    Allowlist,
    PublicSale,
    // artist
    ArtistAllowlist,
    // presale
    PresalePurchase,
    // not used
    // other
    Auction,
    Raffle,
    DutchAuction
  }

  // structs

  /// @dev Represents a minting group
  struct Group {
    string name;
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint256 price;
  }

  struct MinterInfo {
    State minterState;
    uint256 maxSupply;
    uint256 totalSupply;
    uint256 maxPerOasis;
    uint256 maxPerAddress;
    address allowlistSigner;
    Group[] groups;
  }

  struct UserInfo {
    uint256 userGroupId;
    uint256 allowance;
    uint256 totalSupply;
    bool isGroupLive;
  }

  // events

  /** @notice Emitted when a new token is minted
   * @dev Generalized mint event, uses the mintType parameter to distinguish mint types
   * @param to - address of the token owner
   * @param tokenIds - token ID array
   * @param mintType - MintType enum
   * @param amountPaid - amount paid for the mint
   * @param isDelegated - whether or not the mint was delegated
   * @param delegatedVault - address of the delegated vault
   * @param oasisUsed - whether or not an Oasis pass was used. Can be true even if oasisIds is empty (ex. oasis price in public sale).
   * @param oasisIds - Oasis pass ID array (same index/length as tokenId). Empty if ids not specified.
   */
  event TokenMint(address indexed to, uint256[] tokenIds, MintType indexed mintType, uint256 amountPaid, bool isDelegated, address delegatedVault, bool oasisUsed, uint256[] oasisIds);

  // errors

  /// @notice Emitted when trying to call setup twice
  error AlreadySetup();

  /// @notice Emitted when not in live state
  error NotLive();

  /// @notice Emitted when not in complete state
  error NotComplete();

  /// @notice Emitted when group is not allowed to mint yet
  error GroupNotLive(uint256 _groupId);

  /// @notice Emitted when a non-admin tries to call an admin function
  error OnlyAdmin();

  /// @notice Emitted when given a zero address
  error ZeroAddress();

  /// @notice Emitted when given a zero amount
  error ZeroAmount();

  /// @notice Emitted when setting group start time to an invalid value
  error InvalidGroupStartTime(uint256 _startTime);

  /// @notice Emitted when a signature is invalid
  error InvalidSignature(bytes _signature);

  /// @notice Emitted when an OFAC sanctioned address tries to interact with a function
  error SanctionedAddress(address _to);

  /// @notice Emitted when a function is called by a non-delegated address
  error NotDelegated(address _sender, address _vault, address _contract);

  /// @notice Emitted when failing to withdraw to wallet
  error FailedToWithdraw(string _walletName, address _wallet);

  /// @notice Emitted when given a non-existing groupId
  error GroupDoesNotExist(uint256 _groupId);

  /// @notice Emitted when amount requested exceeds nft max supply
  error MaxSupplyExceeded();

  /// @notice Emitted when the value provided is not enough for the function
  error InsufficientFunds();

  /// @notice Emitted when two or more arrays do not match in size
  error ArraySizeMismatch();

  error NotEnoughOasisMints(address _receiver);
  error ZeroOasisAllowance(address _receiver);

  error FailedToMint(address _receiver);

  /// @notice Emitted when a user tries to mint too many toksns
  error MaxPerAddressExceeded(address _receiver, uint256 _amount);

  /// @notice Emitted when a non-admin or non-manager tries to call an admin or manager function
  error OnlyAdminOrManager();

  /// @notice Emitted when presaleMint function receives a non-presale mint type
  error InvalidPresaleMintType(MintType _mintType);

  /// @notice Emitted when presaleMint function fails to mint
  error FailedToPresaleMint(address _receiver, MintType _mintType);

  /// @notice Emitted when presaleMint function is called by a non-presale minter
  error OnlyPresaleMinterOrAdmin();
}