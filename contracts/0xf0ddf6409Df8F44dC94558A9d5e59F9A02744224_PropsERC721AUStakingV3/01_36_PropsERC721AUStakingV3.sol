// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/IERC721AQueryableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/ISignatureMinting.sol";
import "../interfaces/IERC20StakingToken.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";

interface SanctionsList {
  function isSanctioned(address addr) external view returns (bool);
}

contract PropsERC721AUStakingV3 is
  Initializable,
  IOwnable,
  IAllowlist,
  IConfig,
  IPropsContract,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  ERC2771ContextUpgradeable,
  MulticallUpgradeable,
  AccessControlEnumerableUpgradeable,
  ERC721ABurnableUpgradeable,
  ERC721AQueryableUpgradeable
{
  using StringsUpgradeable for uint256;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
  using ECDSAUpgradeable for bytes32;

  //////////////////////////////////////////////
  // State Vars
  /////////////////////////////////////////////

  bytes32 private constant MODULE_TYPE = bytes32("PropsERC721AUStaking");
  uint256 private constant VERSION = 1;

  uint256 private nextTokenId;
  mapping(address => uint256) public minted;
  mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

  bytes32 private constant CONTRACT_ADMIN_ROLE =
    keccak256("CONTRACT_ADMIN_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

  uint256 private SECONDS_IN_ISSUANCE_PERIOD;
  bool public isSelfClaimActive;

  // keeps track of unclaimed tokens
  mapping(address => mapping(uint256 => uint256)) public claimTimer;

  // @dev reserving space for 10 more roles
  bytes32[32] private __gap;

  string private baseURI_;
  string public contractURI;
  address private _owner;
  address private accessRegistry;
  address public project;
  address public receivingWallet;
  address public stakingERC20Address;
  address[] private trustedForwarders;

  Allowlists public allowlists;
  Config public config;

  //////////////////////////////////////////////
  // Errors
  /////////////////////////////////////////////

  error AllowlistInactive();
  error MintQuantityInvalid();
  error MerkleProofInvalid();
  error MintClosed();
  error InsufficientFunds();
  error InvalidSignature();

  //////////////////////////////////////////////
  // Events
  /////////////////////////////////////////////

  event Minted(address indexed account, string tokens);

  //////////////////////////////////////////////
  // Init
  /////////////////////////////////////////////

  function initialize(
    address _defaultAdmin,
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address[] memory _trustedForwarders,
    address _receivingWallet,
    address _accessRegistry
  ) public initializer {
    __ReentrancyGuard_init();
    __ERC2771Context_init(_trustedForwarders);
    __ERC721A_init(_name, _symbol);

    receivingWallet = _receivingWallet;
    _owner = _defaultAdmin;
    accessRegistry = _accessRegistry;
    baseURI_ = _baseURI;

    _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, PRODUCER_ROLE);

    nextTokenId = 1;
    SECONDS_IN_ISSUANCE_PERIOD = 86400;
    isSelfClaimActive = false;
  }

  /*///////////////////////////////////////////////////////////////
                      Generic contract logic
  //////////////////////////////////////////////////////////////*/

  /// @dev Returns the type of the contract.
  function contractType() external pure returns (bytes32) {
    return MODULE_TYPE;
  }

  /// @dev Returns the version of the contract.
  function contractVersion() external pure returns (uint8) {
    return uint8(VERSION);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
  }

  modifier onlyOwner() {
    require(tx.origin == _owner || _msgSender() == _owner);
    _;
  }

  /*///////////////////////////////////////////////////////////////
                      ERC 165 / 721A logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev see {ERC721AUpgradeable}
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * @dev see {IERC721Metadata}
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721AUpgradeable, IERC721MetadataUpgradeable)
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(baseURI_, _tokenId.toString(), ".json"));
  }

  /**
   * @dev see {IERC165-supportsInterface}
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
      AccessControlEnumerableUpgradeable,
      ERC721AUpgradeable,
      IERC165Upgradeable
    )
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      type(IERC2981Upgradeable).interfaceId == interfaceId;
  }

  function mint(
    uint256[] calldata _quantities,
    bytes32[][] calldata _proofs,
    uint256[] calldata _allocations,
    uint256[] calldata _allowlistIds
  ) external payable nonReentrant {
    if (isSanctioned(_msgSender())) revert Sanctioned();

    uint256 _cost = 0;
    uint256 _quantity = 0;

    for (uint256 i = 0; i < _quantities.length; i++) {
      _quantity += _quantities[i];

      // @dev Require could save .029kb
      revertOnInactiveList(_allowlistIds[i]);
      revertOnAllocationCheckFailure(
        _msgSender(),
        _allowlistIds[i],
        mintedByAllowlist[_msgSender()][_allowlistIds[i]],
        _quantities[i],
        _allocations[i],
        _proofs[i]
      );
      _cost += allowlists.lists[_allowlistIds[i]].price * _quantities[i];
    }

    require(
      nextTokenId + _quantity - 1 <= config.mintConfig.maxSupply,
      "Exceeded max supply."
    );

    if (_cost > msg.value) revert InsufficientFunds();
    (bool sent, bytes memory data) = receivingWallet.call{ value: msg.value }(
      ""
    );

    // mint _quantity tokens
    string memory tokensMinted = "";
    unchecked {
      for (uint256 i = nextTokenId; i < nextTokenId + _quantity; i++) {
        tokensMinted = string(
          abi.encodePacked(tokensMinted, i.toString(), ",")
        );
      }
      for (uint256 i = 0; i < _quantities.length; i++) {
        mintedByAllowlist[address(_msgSender())][
          _allowlistIds[i]
        ] += _quantities[i];
      }
      minted[address(_msgSender())] += _quantity;
      nextTokenId += _quantity;
      _safeMint(_msgSender(), _quantity);
    }
    emit Minted(_msgSender(), tokensMinted);
  }

  function mintWithSignature(ISignatureMinting.SignatureMintCart calldata cart)
    external
    payable
    nonReentrant
  {
    uint256 _cost = 0;
    uint256 _quantity = 0;

    for (uint256 i = 0; i < cart.items.length; i++) {
      ISignatureMinting.SignatureMintCartItem memory _item = cart.items[i];

      //validate signatures
      //validate quantities against allocations
      IERC20StakingToken(stakingERC20Address).revertOnInvalidMintSignature(
        _msgSender(),
        _item
      );

      IERC20StakingToken(stakingERC20Address).logMintActivity(
        cart.items[i].uid,
        address(_msgSender()),
        cart.items[i].quantity
      );

      _quantity += _item.quantity;
      _cost += _item.price * _item.quantity;
    }

    require(
      nextTokenId + _quantity - 1 <= config.mintConfig.maxSupply,
      "Exceeded max supply."
    );

    if (_cost > msg.value) revert InsufficientFunds();
    (bool sent, bytes memory data) = receivingWallet.call{ value: msg.value }(
      ""
    );

    // mint _quantity tokens
    string memory tokensMinted = "";
    unchecked {
      for (uint256 i = nextTokenId; i < nextTokenId + _quantity; i++) {
        tokensMinted = string(
          abi.encodePacked(tokensMinted, i.toString(), ",")
        );
      }

      minted[address(_msgSender())] += _quantity;
      nextTokenId += _quantity;
      _safeMint(_msgSender(), _quantity);
    }
    emit Minted(_msgSender(), tokensMinted);
  }

  function revertOnInactiveList(uint256 _allowlistId) internal view {
    if (
      paused() ||
      block.timestamp < allowlists.lists[_allowlistId].startTime ||
      block.timestamp > allowlists.lists[_allowlistId].endTime ||
      !allowlists.lists[_allowlistId].isActive
    ) revert AllowlistInactive();
  }

  // @dev +~0.695kb
  function revertOnAllocationCheckFailure(
    address _address,
    uint256 _allowlistId,
    uint256 _minted,
    uint256 _quantity,
    uint256 _alloted,
    bytes32[] calldata _proof
  ) internal view {
    Allowlist storage allowlist = allowlists.lists[_allowlistId];
    if (_quantity + _minted > allowlist.maxMintPerWallet)
      revert MintQuantityInvalid();
    if (allowlist.typedata != bytes32(0)) {
      if (_quantity > _alloted || ((_quantity + _minted) > _alloted))
        revert MintQuantityInvalid();
      (bool validMerkleProof, ) = MerkleProof.verify(
        _proof,
        allowlist.typedata,
        keccak256(abi.encodePacked(_address, _alloted))
      );
      if (!validMerkleProof) revert MerkleProofInvalid();
    }
  }

  /*///////////////////////////////////////////////////////////////
                      Allowlist Logic
  //////////////////////////////////////////////////////////////*/

  function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
    external
    minRole(PRODUCER_ROLE)
  {
    allowlists.lists[i] = _allowlist;
  }

  function addAllowlist(Allowlist calldata _allowlist)
    external
    minRole(PRODUCER_ROLE)
  {
    allowlists.lists[allowlists.count] = _allowlist;
    allowlists.count++;
  }

  /*///////////////////////////////////////////////////////////////
                      Getters
  //////////////////////////////////////////////////////////////*/

  /// @dev Returns the allowlist at the given uid.
  function getAllowlistById(uint256 _allowlistId)
    external
    view
    returns (Allowlist memory allowlist)
  {
    allowlist = allowlists.lists[_allowlistId];
  }

  /// @dev Returns the number of minted tokens for sender by allowlist.
  function getMintedByAllowlist(uint256 _allowlistId)
    external
    view
    returns (uint256 mintedBy)
  {
    mintedBy = mintedByAllowlist[_msgSender()][_allowlistId];
  }

  /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

  function setReceivingWallet(address _address) external onlyOwner {
    receivingWallet = _address;
  }

  function setStakingERC20Address(address _address)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    stakingERC20Address = _address;
  }

  function setConfig(Config calldata _config) external minRole(PRODUCER_ROLE) {
    config = _config;
  }

  /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
  function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
    address _prevOwner = _owner;
    _owner = _newOwner;

    emit OwnerUpdated(_prevOwner, _newOwner);
  }

  /// @dev Lets a contract admin set the URI for contract-level metadata.
  function setContractURI(string calldata _uri)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    contractURI = _uri;
  }

  /// @dev Lets a contract admin set the URI for the baseURI.
  function setBaseURI(string calldata _baseURI)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    baseURI_ = _baseURI;
  }

  /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

  
  function pause() external minRole(MINTER_ROLE) {
    _pause();
  }

  function unpause() external minRole(MINTER_ROLE) {
    _unpause();
  }

  function grantRole(bytes32 role, address account)
    public
    virtual
    override(AccessControlUpgradeable, IAccessControlUpgradeable)
    minRole(CONTRACT_ADMIN_ROLE)
  {
    if (!hasRole(role, account)) {
      super._grantRole(role, account);
    }
  }

  function revokeRole(bytes32 role, address account)
    public
    virtual
    override(AccessControlUpgradeable, IAccessControlUpgradeable)
    minRole(CONTRACT_ADMIN_ROLE)
  {
    if (hasRole(role, account)) {
      if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
      super._revokeRole(role, account);
    }
  }

  /**
   * @dev Check if minimum role for function is required.
   */
  modifier minRole(bytes32 _role) {
    require(_hasMinRole(_role), "Not authorized");
    _;
  }

  function hasMinRole(bytes32 _role) public view virtual returns (bool) {
    return _hasMinRole(_role);
  }

  function _hasMinRole(bytes32 _role) internal view returns (bool) {
    // @dev does account have role?
    if (hasRole(_role, _msgSender())) return true;
    // @dev are we checking against default admin?
    if (_role == DEFAULT_ADMIN_ROLE) return false;
    // @dev walk up tree to check if user has role admin role
    return _hasMinRole(getRoleAdmin(_role));
  }

  // @dev See {ERC721-_beforeTokenTransfer}.
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override(ERC721AUpgradeable) {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);

    if (isSanctioned(from)) revert Sanctioned();
    if (isSanctioned(to)) revert Sanctioned();
    for (uint256 i = 0; i < quantity; i++) {
      // claim unclaimed erc20 tokens if not mint
      if (from != address(0x0)) {
        forceClaimERC20Tokens(from, startTokenId + i);
      }

      // closed stream represented by 0
      claimTimer[from][startTokenId + i] = 0;

      // open stream to
      claimTimer[to][startTokenId + i] = block.timestamp;
    }
  }

  //@dev retrieves the number of unclaimed ERC20 tokens for a specific token
  function unclaimedERC20BalanceByToken(uint256 tokenId, address holder)
    public
    view
    returns (uint256 unclaimedERC20Tokens)
  {
    // get time acquired nft
    uint256 acquiredTime = claimTimer[holder][tokenId];

    if (acquiredTime == 0) {
      return 0;
    }

    // get current time
    uint256 timestamp = block.timestamp;

    // calculate delta
    uint256 timeDelta = timestamp - acquiredTime;

    // divide delta by seconds to get amounts of days (tokens)

    unclaimedERC20Tokens = timeDelta / SECONDS_IN_ISSUANCE_PERIOD;
  }

  //@dev retrieves the number of unclaimed ERC20 tokens by the holder
  function aggregateUnclaimedERC20TokenBalance(address holder)
    public
    view
    returns (uint256 erc20tokens)
  {
    // retrieve 721A tokens owned
    uint256[] memory tokensOwned = IERC721AQueryableUpgradeable(address(this))
      .tokensOfOwner(holder);

    erc20tokens = 0;

    // iterate over owned tokens
    for (uint256 i = 0; i < tokensOwned.length; i++) {
      erc20tokens += unclaimedERC20BalanceByToken(tokensOwned[i], holder);
    }
  }

  //@dev aggregates the number of ERC20 tokens owned/claimed by the holder and the number of unclaimed ERC20 tokens for the holder
  function aggregateTotalERC20TokenBalance(address holder)
    public
    view
    returns (uint256 erc20tokens)
  {
    //retrieve balance of non-transferable ERC20 and add to unclaimed
    erc20tokens = IERC20Upgradeable(stakingERC20Address).balanceOf(holder);
  }

  //@dev, called on beforeTokenTransfers to mint unclaimed erc20 tokens to sender of token
  function forceClaimERC20Tokens(address from, uint256 tokenId) public {
    // require msg sender owner of eggs
    require(ownerOf(tokenId) == from, "Not Owner");

    // get unstored balance
    uint256 unclaimedERC20Tokens = unclaimedERC20BalanceByToken(tokenId, from);

    // add to current balance
    IERC20StakingToken(stakingERC20Address).issueTokens(
      from,
      unclaimedERC20Tokens
    );

    // reset time delta
    claimTimer[from][tokenId] = block.timestamp;
  }

  function claimERC20Tokens() public {
    require(isSelfClaimActive, "Self-Claim Inactive");
    // retrieve 721A tokens owned
    uint256[] memory tokensOwned = IERC721AQueryableUpgradeable(address(this))
      .tokensOfOwner(_msgSender());

    for (uint256 i = 0; i < tokensOwned.length; i++) {
      forceClaimERC20Tokens(_msgSender(), tokensOwned[i]);
      claimTimer[_msgSender()][tokensOwned[i]] = block.timestamp;
    }
  }

  function _msgSender()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (address sender)
  {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (bytes calldata)
  {
    return ERC2771ContextUpgradeable._msgData();
  }

  //Upgrades

  function isSanctioned(address _operatorAddress) public view returns (bool) {
    SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
    bool isToSanctioned = sanctionsList.isSanctioned(_operatorAddress);
    return isToSanctioned;
  }

  function setSanctionsContract(address _address) external {
    require(hasMinRole(CONTRACT_ADMIN_ROLE));
    SANCTIONS_CONTRACT = _address;
  }

  function setSelfClaimActive(bool _isSelfClaimActive) external {
    require(hasMinRole(CONTRACT_ADMIN_ROLE));
    isSelfClaimActive = _isSelfClaimActive;
  }

   /// @dev Returns the number of minted tokens for sender by allowlist.
    function getMintedByUid(string calldata _uid, address _wallet)
      external
      view
      returns (uint256)
    {
      return IERC20StakingToken(stakingERC20Address).getMintedByUid(_uid,_wallet);
    }

  address public SANCTIONS_CONTRACT;
  error Sanctioned();

  uint256[47] private ___gap;
}