// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/IERC721AQueryableUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";
// import "../interfaces/IPropsAccessRegistry.sol";

import "hardhat/console.sol";

contract PropsERC721AUStaking is
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

  //////////////////////////////////////////////
  // State Vars
  /////////////////////////////////////////////

  bytes32 private constant MODULE_TYPE = bytes32("PropsERC721AUStaking");
  uint256 private constant VERSION = 1;

  uint256 private nextTokenId;
  mapping(address => uint256) public minted;
  mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

  bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
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
  ) initializer public {
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

    // call registry add here
    // add default admin entry to registry
    // IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
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

  modifier onlyOwner {
      require(tx.origin == _owner || msg.sender == _owner);
      _;
   }

  /*///////////////////////////////////////////////////////////////
                      ERC 165 / 721A logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev see {ERC721AUpgradeable}
   */
  function _startTokenId() internal view virtual override returns (uint256){
    return 1;
  }

  /**
   * @dev see {IERC721Metadata}
   */
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721AUpgradeable, IERC721MetadataUpgradeable) returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      return string(abi.encodePacked(baseURI_, _tokenId.toString(), ".json"));
  }

  /**
   * @dev see {IERC165-supportsInterface}
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC721AUpgradeable, IERC165Upgradeable) returns (bool) {
      return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
  }

  function mint(
    uint256[] calldata _quantities,
    bytes32[][] calldata _proofs,
    uint256[] calldata _allotments,
    uint256[] calldata _allowlistIds
  ) external payable nonReentrant {
    require(isTrustedForwarder(msg.sender) || _msgSender() == tx.origin, "BOT");

    uint256 _cost = 0;
    uint256 _quantity = 0;

    for(uint256 i = 0; i < _quantities.length; i++) {
      _quantity += _quantities[i];

      // @dev Require could save .029kb
      revertOnInactiveList(_allowlistIds[i]);
      revertOnAllocationCheckFailure(
        msg.sender,
        _allowlistIds[i],
        mintedByAllowlist[msg.sender][_allowlistIds[i]],
        _quantities[i],
        _allotments[i],
        _proofs[i]
      );
      _cost += allowlists.lists[_allowlistIds[i]].price * _quantities[i];
    }

    require(nextTokenId + _quantity - 1 <= config.mintConfig.maxSupply, "Exceeded max supply.");

    if(_cost > msg.value) revert InsufficientFunds();
    (bool sent, bytes memory data) = receivingWallet.call{value: msg.value}("");


    // mint _quantity tokens
    string memory tokensMinted = "";
    unchecked {
        for (uint i = nextTokenId; i < nextTokenId + _quantity; i++) {
            tokensMinted = string(abi.encodePacked(tokensMinted, i.toString(), ","));
        }
        for (uint i = 0; i < _quantities.length; i++) {
          mintedByAllowlist[address(msg.sender)][_allowlistIds[i]] += _quantities[i];
        }
        minted[address(msg.sender)] += _quantity;
        nextTokenId += _quantity;
        _safeMint(msg.sender, _quantity);
    }
    emit Minted(msg.sender, tokensMinted);
  }

  function airdrop(address[] calldata __to, uint256[] calldata __quantities) external minRole(MINTER_ROLE){
     for (uint i = 0; i < __to.length; i++) {
       nextTokenId += __quantities[i];
       _safeMint(__to[i], __quantities[i]);
     }
  }

  function revertOnInactiveList(uint256 _allowlistId) internal view{
      if(paused() || block.timestamp < allowlists.lists[_allowlistId].startTime || block.timestamp > allowlists.lists[_allowlistId].endTime || !allowlists.lists[_allowlistId].isActive) revert AllowlistInactive();
  }

  // @dev +~0.695kb
  function revertOnAllocationCheckFailure(
    address _address,
    uint256 _allowlistId,
    uint256 _minted,
    uint256 _quantity,
    uint256 _alloted,
    bytes32[] calldata _proof
  ) internal view{
    Allowlist storage allowlist = allowlists.lists[_allowlistId];
    if(_quantity + _minted > allowlist.maxMintPerWallet) revert MintQuantityInvalid();
    if(allowlist.typedata != bytes32(0)){
      if (_quantity > _alloted || ((_quantity + _minted) > _alloted)) revert MintQuantityInvalid();
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

  function setAllowlists(Allowlist[] calldata _allowlists)
      external
      minRole(PRODUCER_ROLE)
  {
    allowlists.count = _allowlists.length;
    for (uint256 i = 0; i < _allowlists.length; i++) {
      allowlists.lists[i] = _allowlists[i];
    }
  }

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
  function getAllowlistById(uint256 _allowlistId) external view returns (Allowlist memory allowlist) {
      allowlist = allowlists.lists[_allowlistId];
  }

  /// @dev Returns the number of minted tokens for sender by allowlist.
  function getMintedByAllowlist(uint256 _allowlistId) external view returns (uint256 mintedBy) {
      mintedBy = mintedByAllowlist[msg.sender][_allowlistId];
  }

  /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

  function setReceivingWallet(address _address) external onlyOwner{
    receivingWallet = _address;
  }

  function setStakingERC20Address(address _address)
      external
      minRole(CONTRACT_ADMIN_ROLE)
  {
    stakingERC20Address = _address;
  }

  function setIssuancePeriod(uint256 _seconds)
      external
      minRole(CONTRACT_ADMIN_ROLE)
  {
    SECONDS_IN_ISSUANCE_PERIOD = _seconds;
  }

  function setConfig(Config calldata _config)
      external
      minRole(PRODUCER_ROLE)
  {
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
  function setContractURI(string calldata _uri) external minRole(CONTRACT_ADMIN_ROLE) {
      contractURI = _uri;
  }

  /// @dev Lets a contract admin set the URI for the baseURI.
  function setBaseURI(string calldata _baseURI) external minRole(CONTRACT_ADMIN_ROLE) {
      baseURI_ = _baseURI;
  }

  /// @dev Lets a contract admin set isSelfClaimActive.
  function setSelfClaimActive(bool _isSelfClaimActive) external minRole(CONTRACT_ADMIN_ROLE) {
      isSelfClaimActive = _isSelfClaimActive;
  }



  /// @dev Lets a contract admin set the address for the access registry.
  function setAccessRegistry(address _accessRegistry) external minRole(CONTRACT_ADMIN_ROLE) {
      accessRegistry = _accessRegistry;
  }

  /// @dev Lets a contract admin set the address for the parent project.
  function setProject(address _project) external minRole(PRODUCER_ROLE) {
      project = _project;
  }


  /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

  function pause() external minRole(MINTER_ROLE){
    _pause();
  }

  function unpause() external minRole(MINTER_ROLE){
    _unpause();
  }

  function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) minRole(CONTRACT_ADMIN_ROLE) {
    if(!hasRole(role, account)){
      super._grantRole(role,account);
      // IPropsAccessRegistry(accessRegistry).add(account, address(this));
    }
  }

  function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) minRole(CONTRACT_ADMIN_ROLE) {
    if(hasRole(role, account)){
      if(role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
      super._revokeRole(role,account);
      // IPropsAccessRegistry(accessRegistry).remove(account, address(this));
    }
  }

  /**
   * @dev Check if minimum role for function is required.
   */
  modifier minRole(bytes32 _role) {
      require(_hasMinRole(_role), "Not authorized");
      _;
  }

  function hasMinRole(bytes32 _role) public view virtual returns (bool){
    return _hasMinRole(_role);
  }

  function _hasMinRole(bytes32 _role) internal view returns (bool) {
      // @dev does account have role?
      if(hasRole(_role, _msgSender())) return true;
      // @dev are we checking against default admin?
      if(_role == DEFAULT_ADMIN_ROLE) return false;
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

        for(uint i = 0; i < quantity; i++ ){
           // claim unclaimed erc20 tokens if not mint
           if(from != address(0x0)){
              forceClaimERC20Tokens(from, startTokenId + i);
           }
           // close stream from (if stream open - mint case)
          // closed stream represented by 0
          claimTimer[from][startTokenId + i] = 0;

          // open stream to
          claimTimer[to][startTokenId + i] = block.timestamp;
        }


  }

 //@dev retrieves the number of unclaimed ERC20 tokens for a specific token
  function unclaimedERC20BalanceByToken(
    uint256 tokenId,
    address holder
  ) public view returns (uint256 unclaimedERC20Tokens) {
      // get time acquired nft
      uint256 acquiredTime = claimTimer[holder][tokenId];

      if(acquiredTime == 0){
        return 0;
      }

      // get current time
      uint256 timestamp = block.timestamp;

      // calculate delta
      uint256 timeDelta = timestamp - acquiredTime;

      // divide delta by seconds to get amounts of days (tokens)
      // 1 token a day
      unclaimedERC20Tokens = timeDelta / SECONDS_IN_ISSUANCE_PERIOD;
  }

 //@dev retrieves the number of unclaimed ERC20 tokens by the holder
  function aggregateUnclaimedERC20TokenBalance(address holder) public view returns (uint256 erc20tokens){

    // retrieve 721A tokens owned
    uint256[] memory tokensOwned = IERC721AQueryableUpgradeable(address(this)).tokensOfOwner(holder);

    erc20tokens = 0;

    // iterate over owned tokens
    for(uint i = 0; i < tokensOwned.length; i++ ){
        erc20tokens += unclaimedERC20BalanceByToken(tokensOwned[i], holder);
    }
  }

 //@dev aggregates the number of ERC20 tokens owned/claimed by the holder and the number of unclaimed ERC20 tokens for the holder
  function aggregateTotalERC20TokenBalance(address holder) public view returns (uint256 erc20tokens){
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
    ERC20StakingToken(stakingERC20Address).issueTokens(from, unclaimedERC20Tokens);

    // reset time delta
    claimTimer[from][tokenId] = block.timestamp;

  }

  function claimERC20Tokens() public {

    require(isSelfClaimActive, "Self-Claim Inactive");
     // retrieve 721A tokens owned
     uint256[] memory tokensOwned = IERC721AQueryableUpgradeable(address(this)).tokensOfOwner(msg.sender);

     for(uint i = 0; i < tokensOwned.length; i++ ){
          forceClaimERC20Tokens(msg.sender, tokensOwned[i]);
          claimTimer[msg.sender][tokensOwned[i]] = block.timestamp;
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

  uint256[49] private ___gap;
}

contract ERC20StakingToken {
    function issueTokens(address _to, uint256 _amount) public {}
}