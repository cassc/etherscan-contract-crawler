// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

import "../utils/Base64.sol";
import "../interfaces/IAllowlist.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";
import "../interfaces/IPropsAccessRegistry.sol";

contract PropsERC721AUltraPass is
  Initializable,
  IOwnable,
  IAllowlist,
  IConfig,
  IPropsContract,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  ERC2771ContextUpgradeable,
  AccessControlEnumerableUpgradeable,
  ERC721ABurnableUpgradeable,
  ERC721AQueryableUpgradeable
{

  using StringsUpgradeable for uint256;

  bytes32 private constant MODULE_TYPE = bytes32("PropsERC721AUltraPass");
  uint256 private constant VERSION = 1;

  uint256 private nextTokenId;
  mapping(address => uint256) public minted;
  mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

  bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
  bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

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

  struct MembershipPass {
        string name;
        string description;
        string image;
        string imageExt;
        string url;
  }

  mapping(uint256 => MembershipPass) public tokens;
  mapping(uint256 => uint256) internal tokenTypes;

  uint256 public totalStaked;

  struct StakingTier {
        uint tierLevel;
        uint256 periodToAchieve;
  }

  struct StakedToken {
    uint lockedTier;
    uint256 timer;
    bool isStaked;
    bool isUltimate;
  }

  mapping(uint256 => StakedToken) internal stakedTokens;
  mapping(uint256 => StakingTier) public stakingTiers;
  uint256 public numStakingTiers;

  error AllowlistInactive();
  error MintQuantityInvalid();
  error MerkleProofInvalid();
  error MintClosed();
  error InsufficientFunds();

  event Minted(address indexed account, string tokens);
  event Staked(address indexed account, uint256[] id);
  event Unstaked(address indexed account, uint256[] id);

  bool public reveal;

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

    reveal = false;

    _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);

    nextTokenId = 1;

    IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
  }

  function contractType() external pure returns (bytes32) {
      return MODULE_TYPE;
  }

  function contractVersion() external pure returns (uint8) {
      return uint8(VERSION);
  }

  function owner() public view returns (address) {
      return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
  }

  function _startTokenId() internal view virtual override returns (uint256){
    return 1;
  }

  function getStakingLevel(uint256 _tokenId) public view returns (uint) {
    unchecked {
     if(stakedTokens[_tokenId].isStaked) return calcTier(_tokenId, calcTimeDelta(_tokenId));
     return stakedTokens[_tokenId].lockedTier > 1 ? stakedTokens[_tokenId].lockedTier : 1;
    }
  }

  function calcPreviousTiersTimeElapse(uint256 _tokenId) internal view returns (uint256){
    unchecked {
      uint256 elapsed = 0;
      uint stakingLevel = getStakingLevel(_tokenId);

      for(uint256 i = 0; i < numStakingTiers; i++){
        if(stakingTiers[i].tierLevel == stakingLevel) elapsed += (stakingTiers[i].periodToAchieve * 86400);
      }
      return elapsed;
    }

  }

  function calcTier(uint256 _tokenId, uint256 _timeDelta) public view returns (uint) {
      uint tier = 1;
      unchecked {
        for(uint256 i = 0; i < numStakingTiers; i++){
          if(_timeDelta >= stakingTiers[i].periodToAchieve * 86400) tier = stakingTiers[i].tierLevel;
        }
      }
    return tier;
  }

  function calcTimeDelta(uint256 _tokenId) public view returns (uint256) {
      if(stakedTokens[_tokenId].timer == 0) return 0;
      unchecked {
        return block.timestamp - stakedTokens[_tokenId].timer;
      }
  }

  function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override (ERC721AUpgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "No Token"
        );

        if(!reveal) return baseURI_;

        MembershipPass storage token = tokens[tokenTypes[tokenId]];

        bytes memory json;
        json = concatString(json, '{"name": "ULTRAPASS #');
        json = concatString(json, StringsUpgradeable.toString(tokenId));
        json = concatString(json, '", "description": "');
        json = concatString(json, token.description);
        json = concatString(json, '", "image": "');
        json = concatString(json, token.image);
        json = concatString(json, StringsUpgradeable.toString(getStakingLevel(tokenId)));
        json = concatString(json, (stakedTokens[tokenId].isUltimate ? "_ultimate" : "" ));
        json = concatString(json, token.imageExt);
        json = concatString(json, '", "external_url": "');
        json = concatString(json, token.url);
        json = concatString(json, '", "attributes": [{"trait_type": "Segmint","value": "');
        json = concatString(json, token.name);
        json = concatString(json, '"}, {"trait_type": "Staking Level","value": "');
        json = concatString(json, StringsUpgradeable.toString(getStakingLevel(tokenId)));
        json = concatString(json, '"}, {"trait_type": "Ultimate","value": "');
        json = concatString(json, (stakedTokens[tokenId].isUltimate ? "Yes" : "No" ));
        json = concatString(json, '"}]}');

        return string(concatString("data:application/json;base64,", Base64.encode(
            bytes(
                string(json)
                )
        )));

    }

  function concatString(bytes memory _input, string memory _append) internal view returns(bytes memory){
    unchecked {
      return abi.encodePacked(_input, _append);
    }

  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC721AUpgradeable, IERC165Upgradeable) returns (bool) {
      return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
  }

  struct AllocationCheck{
    address _address;
    uint256 _allowlistId;
    uint256 _minted;
    uint256 _quantity;
    uint256 _alloted;
    bytes32[] _proof;
  }

  struct MintCart{
    uint256 _cost;
    uint256 _quantity;
    string _tokensMinted;
  }

  function mint(
    uint256[] calldata _quantities,
    bytes32[][] calldata _proofs,
    uint256[] calldata _allotments,
    uint256[] calldata _allowlistIds,
    uint256[] calldata _traits,
    bool _autostake
  ) external payable nonReentrant {
    require(isTrustedForwarder(msg.sender) || _msgSender() == tx.origin, "BOT");

    MintCart memory cart;

    cart._cost = 0;
    cart._quantity = 0;
    cart._tokensMinted = "";

    unchecked {
      for(uint256 i = 0; i < _quantities.length; i++) {
        cart._quantity += _quantities[i];

        revertOnInactiveList(_allowlistIds[i]);

        revertOnAllocationCheckFailure(
          AllocationCheck(
            msg.sender,
            _allowlistIds[i],
            mintedByAllowlist[msg.sender][_allowlistIds[i]],
            _quantities[i],
            _allotments[i],
            _proofs[i]
          )
        );

        cart._cost += allowlists.lists[_allowlistIds[i]].price * _quantities[i];
      }
    }

    require(nextTokenId + cart._quantity - 1 <= config.mintConfig.maxSupply, "Exceeded max supply.");

    if(cart._cost > msg.value) revert InsufficientFunds();
    (bool sent, bytes memory data) = receivingWallet.call{value: msg.value}("");


    unchecked {
        for (uint i = 0; i < _quantities.length; i++) {
          mintedByAllowlist[address(msg.sender)][_allowlistIds[i]] += _quantities[i];

             for (uint t = nextTokenId; t < nextTokenId + _quantities[i]; t++) {
                cart._tokensMinted = string(concatString(concatString(bytes(cart._tokensMinted), t.toString()), ","));
                tokenTypes[t] = _traits[i];
                uint256 ra = 0;
                for(uint r = 0; r < 5; r++) ra += uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, r))) % 2;
                if(ra >= 5) stakedTokens[t].isUltimate = true;

                if(_autostake) _stake(t);

               }
            nextTokenId += _quantities[i];
        }
        minted[address(msg.sender)] += cart._quantity;

        _safeMint(msg.sender, cart._quantity);
    }
    emit Minted(msg.sender, cart._tokensMinted);
  }

  function revertOnInactiveList(uint256 _allowlistId) internal view{
      if(paused() || block.timestamp < allowlists.lists[_allowlistId].startTime || block.timestamp > allowlists.lists[_allowlistId].endTime || !allowlists.lists[_allowlistId].isActive) revert AllowlistInactive();
  }


  function revertOnAllocationCheckFailure(
    AllocationCheck memory _allocationCheck
  ) internal view{
    unchecked {
      Allowlist storage allowlist = allowlists.lists[_allocationCheck._allowlistId];
      if(_allocationCheck._quantity + _allocationCheck._minted > allowlist.maxMintPerWallet) revert MintQuantityInvalid();
      if(allowlist.typedata != bytes32(0)){
        if (_allocationCheck._quantity > _allocationCheck._alloted || ((_allocationCheck._quantity + _allocationCheck._minted) > _allocationCheck._alloted)) revert MintQuantityInvalid();
        (bool validMerkleProof, ) = MerkleProof.verify(
          _allocationCheck._proof,
          allowlist.typedata,
          keccak256(abi.encodePacked(_allocationCheck._address, _allocationCheck._alloted))
        );
        if (!validMerkleProof) revert MerkleProofInvalid();
      }
    }
  }

  /**
     * @notice Update token metadata
     */
    function updateTokenMetadata(
        uint256 tokenId,
        string memory name,
        string memory description,
        string memory image,
        string memory imageExt,
        string memory url
    ) external onlyRole(CONTRACT_ADMIN_ROLE) {
        MembershipPass storage token = tokens[tokenId];
        token.name = name;
        token.description = description;
        token.image = image;
        token.imageExt = imageExt;
        token.url = url;
    }

  function toggleReveal()
      public
  {
     require(hasMinRole(PRODUCER_ROLE), "Auth");
     reveal = true;
  }

  function updateIndividualToken(uint256 id, uint256 tokenType, bool isUltimate)
      external
  {
    require(hasMinRole(PRODUCER_ROLE), "Auth");
     tokenTypes[id] = tokenType;
     stakedTokens[id].isUltimate = isUltimate;
  }

  function upsertStakingTier(uint256 _i, uint _tierLevel, uint256 _periodToAchieve)
      public
  {
      require(hasMinRole(PRODUCER_ROLE), "Auth");
      if(stakingTiers[_i].tierLevel == 0 ) numStakingTiers++;
      stakingTiers[_i].tierLevel = _tierLevel;
      stakingTiers[_i].periodToAchieve = _periodToAchieve;
  }

  function _stake(uint256 id) internal{
    StakedToken storage stakedToken = stakedTokens[id];
    stakedToken.timer = block.timestamp - calcPreviousTiersTimeElapse(id);
    stakedToken.isStaked = true;
    totalStaked++;
  }

  function stake(uint256[] calldata id) public {
    for(uint256 i = 0; i < id.length; i++){
      require(ownerOf(id[i]) == _msgSender(), "Not Owner");
      _stake(id[i]);
    }

    emit Staked(_msgSender(), id);
  }


  function unstake(uint256[] calldata id) public {
    unchecked {
      for(uint256 i = 0; i < id.length; i++){
        require(ownerOf(id[i]) == _msgSender(), "Not Owner");
        StakedToken storage stakedToken = stakedTokens[id[i]];
        uint stakingLevel = getStakingLevel(id[i]);
        stakedToken.lockedTier = stakingLevel == 1 ? 1 : stakingLevel - 1;
        stakedToken.isStaked = false;
        stakedToken.timer = 0;
        totalStaked--;
      }
    }
    emit Unstaked(_msgSender(), id);
  }

  function getStakedToken(uint256 id) public view returns (StakedToken memory){
    if(reveal) return stakedTokens[id];
  }

  function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
      public
  {
      require(hasMinRole(PRODUCER_ROLE), "Auth");
      allowlists.lists[i] = _allowlist;
  }

  function addAllowlist(Allowlist calldata _allowlist)
      external
  {
      updateAllowlistByIndex(_allowlist, allowlists.count);
      allowlists.count++;
  }

  function getAllowlistById(uint256 _allowlistId) external view returns (Allowlist memory allowlist) {
      allowlist = allowlists.lists[_allowlistId];
  }

  function getMintedByAllowlist(uint256 _allowlistId) external view returns (uint256 mintedBy) {
      mintedBy = mintedByAllowlist[msg.sender][_allowlistId];
  }

  function setReceivingWallet(address _address)
      external

  {
    require(hasMinRole(CONTRACT_ADMIN_ROLE), "Auth");
    receivingWallet = _address;
  }


  function setConfig(Config calldata _config)
      external
  {
    require(hasMinRole(PRODUCER_ROLE), "Auth");
    config = _config;
  }

  function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
      address _prevOwner = _owner;
      _owner = _newOwner;

      emit OwnerUpdated(_prevOwner, _newOwner);
  }

  function setContractURI(string calldata _uri) external {
    require(hasMinRole(CONTRACT_ADMIN_ROLE), "Auth");
      contractURI = _uri;
  }

  function setBaseURI(string calldata _baseURI) external {
    require(hasMinRole(CONTRACT_ADMIN_ROLE), "Auth");
      baseURI_ = _baseURI;
  }

  function setAccessRegistry(address _accessRegistry) external {
    require(hasMinRole(CONTRACT_ADMIN_ROLE), "Auth");
      accessRegistry = _accessRegistry;
  }

  function setProject(address _project) external{
      require(hasMinRole(PRODUCER_ROLE), "Auth");
      project = _project;
  }

  function togglePause(bool isPaused) external{
    require(hasMinRole(PRODUCER_ROLE), "Auth");
    isPaused ? _pause() : _unpause();
  }

  function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
    require(hasMinRole(CONTRACT_ADMIN_ROLE), "Auth");
    if(!hasRole(role, account)){
      super._grantRole(role,account);
      IPropsAccessRegistry(accessRegistry).add(account, address(this));
    }
  }

  function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
    require(hasMinRole(CONTRACT_ADMIN_ROLE), "Auth");
    if(hasRole(role, account)){
      if(role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
      super._revokeRole(role,account);
      IPropsAccessRegistry(accessRegistry).remove(account, address(this));
    }
  }

  function hasMinRole(bytes32 _role) public view virtual returns (bool){
     if(hasRole(_role, _msgSender())) return true;
      if(_role == DEFAULT_ADMIN_ROLE) return false;
      return hasMinRole(getRoleAdmin(_role));
  }

  function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
  ) internal override(ERC721AUpgradeable) {

      super._beforeTokenTransfers(from, to, startTokenId, quantity);
       for(uint i = 0; i < quantity; i++ ){
         if(from != address(0x0) && to != address(0x0)) require(stakedTokens[startTokenId + i].isStaked == false, "ULTRAPASS must be unstaked before sale or transfer");
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