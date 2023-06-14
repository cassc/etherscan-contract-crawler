// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
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
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../../interfaces/ISignatureMinting.sol";
import "../../interfaces/IPropsContract.sol";
import "../../interfaces/ISanctionsList.sol";
import "../PropsERC20Rewards/interfaces/IPropsERC20Rewards.sol";

import {DefaultOperatorFiltererUpgradeable} from "../../external/opensea/DefaultOperatorFiltererUpgradeable.sol";



contract PropsERC721A is
  Initializable,
  IOwnable,
  IPropsContract,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  ERC2771ContextUpgradeable,
  DefaultOperatorFiltererUpgradeable,
  MulticallUpgradeable,
  AccessControlEnumerableUpgradeable,
  ERC721AUpgradeable,
  ERC721AQueryableUpgradeable,
  ERC721ABurnableUpgradeable,
  ERC2981
{
  using StringsUpgradeable for uint256;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
  using ECDSAUpgradeable for bytes32;

  //////////////////////////////////////////////
  // State Vars
  /////////////////////////////////////////////

  bytes32 private constant MODULE_TYPE = bytes32("PropsERC721A");
  uint256 private constant VERSION = 2;

  uint256 private nextTokenId;
  mapping(address => uint256) public minted;

  bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

  uint256 public MAX_SUPPLY;
  uint256 private SECONDS_IN_ISSUANCE_PERIOD;
  bool public isSelfClaimActive;

  mapping(address => mapping(uint256 => uint256)) public claimTimer;
  mapping(string => mapping(address => uint256)) public mintedByID;

  string private baseURI_;
  string public contractURI;
  address private _owner;
  address private accessRegistry;
  address public project;
  address public receivingWallet;
  address public rWallet;
  address public signatureVerifier;
  address public stakingERC20Address;
  address[] private trustedForwarders;
  address public SANCTIONS_CONTRACT;


  //////////////////////////////////////////////
  // Errors
  /////////////////////////////////////////////

  error AllowlistInactive();
  error MintQuantityInvalid();
  error MerkleProofInvalid();
  error MintClosed();
  error InsufficientFunds();
  error InvalidSignature();
  error Sanctioned();
  error ExpiredSignature();

  //////////////////////////////////////////////
  // Events
  /////////////////////////////////////////////

  event Minted(address indexed account, string tokens);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  //////////////////////////////////////////////
  // Init
  /////////////////////////////////////////////

  function initialize(
    address _defaultAdmin,
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address[] memory _trustedForwarders,
    address _sigVerifier,
    address _receivingWallet,
    address _royaltyWallet,
    uint96 _royaltyBIPs,
    uint256 _maxSupply,
    address _accessRegistry,
    address _OFAC
    
  ) public initializerERC721A initializer {
    __ReentrancyGuard_init();
    __ERC2771Context_init(_trustedForwarders);
    __ERC721A_init(_name, _symbol);

    receivingWallet = _receivingWallet;
    rWallet = _royaltyWallet;
    _owner = _defaultAdmin;
    accessRegistry = _accessRegistry;
    signatureVerifier = _sigVerifier;
    baseURI_ = _baseURI;
    MAX_SUPPLY = _maxSupply;
    SANCTIONS_CONTRACT = _OFAC;

    _setDefaultRoyalty(rWallet, _royaltyBIPs);

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
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "!t"
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
      IERC721AUpgradeable,
      ERC2981
    )
    returns (bool)
  {
    return super.supportsInterface(interfaceId) || ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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

      revertOnInvalidMintSignature(
        _msgSender(),
        _item
      );

      _logMintActivity(
        cart.items[i].uid,
        address(_msgSender()),
        cart.items[i].quantity
      );

      _quantity += _item.quantity;
      _cost += _item.price * _item.quantity;
    }

    require(
      nextTokenId + _quantity - 1 <= MAX_SUPPLY,
      "Max Supply"
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
      emit Minted(_msgSender(), tokensMinted);
    }
  }

  /*///////////////////////////////////////////////////////////////
                            Signature Enforcement
    //////////////////////////////////////////////////////////////*/

  function revertOnInvalidMintSignature(
    address sender,
    ISignatureMinting.SignatureMintCartItem memory cartItem
  ) internal view {
    if (cartItem.expirationTime < block.timestamp) revert ExpiredSignature();

    if (
      mintedByID[cartItem.uid][sender] + cartItem.quantity >
      cartItem.allocation
    ) revert MintQuantityInvalid();

    address recoveredAddress = ECDSAUpgradeable.recover(
      keccak256(
        abi.encodePacked(
          sender,
          cartItem.uid,
          cartItem.quantity,
          cartItem.price,
          cartItem.allocation,
          cartItem.expirationTime
        )
      ).toEthSignedMessageHash(),
      cartItem.signature
    );

    if (recoveredAddress != signatureVerifier) revert InvalidSignature();
  }

  function _logMintActivity(
    string memory uid,
    address wallet_address,
    uint256 incrementalQuantity
  ) internal {
    mintedByID[uid][wallet_address] += incrementalQuantity;
  }
  

  function setRoyaltyConfig(address _address, uint96 _royalty) external {
    require(_hasMinRole(PRODUCER_ROLE));
        rWallet = _address;
        _setDefaultRoyalty(rWallet, _royalty);
  }

  function setReceivingWallet(address _address) external {
    require(_hasMinRole(PRODUCER_ROLE));
    receivingWallet = _address;
  }

  function getReceivingWallet() external view returns (address) {
    return receivingWallet;
  }

  function setStakingERC20Address(address _address)
    external
  {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    stakingERC20Address = _address;
  }

  /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
  function setOwner(address _newOwner) external {
    require(_hasMinRole(DEFAULT_ADMIN_ROLE));
    require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!Admin");
    address _prevOwner = _owner;
    _owner = _newOwner;

    emit OwnerUpdated(_prevOwner, _newOwner);
  }

  /// @dev Lets a contract admin set the URI for contract-level metadata.
  function setContractURI(string calldata _uri)
    external
  {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    contractURI = _uri;
  }

  /// @dev Lets a contract admin set the URI for the baseURI.
  function setBaseURI(string calldata _baseURI)
    external
  {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    baseURI_ = _baseURI;
    emit BatchMetadataUpdate(1, totalSupply());
    
  }

  function setSignatureVerifier(address _address)
    external
  {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    signatureVerifier = _address;
  }

  /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

  
  function togglePause(bool isPaused) external {
    require(_hasMinRole(MINTER_ROLE));
    if(isPaused){
      _pause();
    }
    else{
      _unpause();
    }
  }

  function grantRole(bytes32 role, address account)
    public
    virtual
    override(AccessControlUpgradeable, IAccessControlUpgradeable)
  {
     require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    if (!hasRole(role, account)) {
      super._grantRole(role, account);
    }
  }

  function revokeRole(bytes32 role, address account)
    public
    virtual
    override(AccessControlUpgradeable, IAccessControlUpgradeable)
  {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    if (hasRole(role, account)) {
      if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
      super._revokeRole(role, account);
    }
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

    if (isSanctioned(from) || isSanctioned(to)) revert Sanctioned();
    if(stakingERC20Address != address(0x0)){
      for (uint256 i = 0; i < quantity; i++) {
        // claim unclaimed erc20 tokens if not mint
        if (from != address(0x0)) forceClaimERC20Tokens(from, startTokenId + i);

        // closed stream represented by 0
        claimTimer[from][startTokenId + i] = 0;

        // open stream to
        claimTimer[to][startTokenId + i] = block.timestamp;
      }
    }
  }

   function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(operator), "Operator not allowed");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(operator), "Operator not allowed");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), "Operator not allowed");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), "Operator not allowed");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
       
    {
       require(onlyAllowedOperatorApproval(from), "Operator not allowed");
        super.safeTransferFrom(from, to, tokenId, data);
    }

  //@dev retrieves the number of unclaimed ERC20 tokens for a specific token
  function unclaimedERC20BalanceByToken(uint256 tokenId, address holder)
    public
    view
    returns (uint256 unclaimedERC20Tokens)
  {
    // get time acquired nft
    uint256 acquiredTime = claimTimer[holder][tokenId];

    if (acquiredTime == 0) return 0;

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
    require(ownerOf(tokenId) == from, "Not owner of token");

    // add to current balance
    IPropsERC20Rewards(stakingERC20Address).issueTokens(
      from,
      unclaimedERC20BalanceByToken(tokenId, from)
    );

    // reset time delta
    claimTimer[from][tokenId] = block.timestamp;
  }

  function claimERC20Tokens() public {
    require(isSelfClaimActive, "Self claim not active");
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



  function isSanctioned(address _operatorAddress) public view returns (bool) {
    SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
    bool isToSanctioned = sanctionsList.isSanctioned(_operatorAddress);
    return isToSanctioned;
  }

  function setSanctionsContract(address _address) external {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    SANCTIONS_CONTRACT = _address;
  }

  function setSelfClaimActive(bool _isSelfClaimActive) external {
    require(_hasMinRole(CONTRACT_ADMIN_ROLE));
    isSelfClaimActive = _isSelfClaimActive;
  }

   /// @dev Returns the number of minted tokens for sender by allowlist.
    function getMintedByUid(string calldata _uid, address _wallet)
      external
      view
      returns (uint256)
    {
      return mintedByID[_uid][_wallet];
    }

  

  uint256[46] private ___gap;
}