// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWNS_Passes.sol";
import "./IWRLD_Name_Service_Bridge.sol";
import "./IWRLD_Name_Service_Metadata.sol";
import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Registry.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service_Registry is ERC721, IWRLD_Name_Service_Registry, IWRLD_Records, Ownable, ReentrancyGuard {
  using StringUtils for *;

  /**
   * @dev @iamarkdev was here
   * @dev @niftyorca was here
   * */

  IWRLD_Name_Service_Metadata metadata;
  IWRLD_Name_Service_Resolver resolver;
  IWRLD_Name_Service_Bridge bridge;

  uint256 private constant YEAR_SECONDS = 31557600; // 365.25 days

  mapping(uint256 => WRLDName) public wrldNames;
  mapping(string => uint256) private nameTokenId;

  address private approvedWithdrawer;
  mapping(address => bool) private approvedRegistrars;

  struct WRLDName {
    string name;
    address controller;
    uint256 expiresAt;
  }

  constructor() ERC721("WRLD Name Service", "WNS") {}

  /************
   * Metadata *
   ************/

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return metadata.getMetadata(wrldNames[_tokenId].name, wrldNames[_tokenId].expiresAt);
  }

  /****************
   * Registration *
   ****************/

  function register(address _registerer, string[] calldata _names, uint16[] memory _registrationYears) external override isApprovedRegistrar {
    require(_names.length == _registrationYears.length, "Arg size mismatched");

    for (uint256 i = 0; i < _names.length; i++) {
      require(_registrationYears[i] > 0 && _registrationYears[i] <= 100, "Years must be between 1 and 100");

      string memory name = _names[i].UTS46Normalize();
      uint256 expiresAt = block.timestamp + YEAR_SECONDS * _registrationYears[i];
      uint256 tokenId = _generateNameId(name);  // tokenId is normalized name hashed to an address

      if (_exists(tokenId)) {
        require(wrldNames[tokenId].expiresAt < block.timestamp, "Unavailable name");
        _burn(tokenId);
      }

      wrldNames[tokenId] = WRLDName(name, address(0), expiresAt);
      nameTokenId[name] = tokenId;

      _safeMint(_registerer, tokenId);

      emit NameRegistered(name, name, _registrationYears[i]);
    }
  }

  /*************
   * Extension *
   *************/

  function extendRegistration(string[] memory _names, uint16[] calldata _additionalYears) external override isApprovedRegistrar {
    require(_names.length == _additionalYears.length, "Arg size mismatched");

    for (uint256 i = 0; i < _names.length; i++) {
      require(_additionalYears[i] > 0, "Years must be greater than zero");

      _names[i] = _names[i].UTS46Normalize();

      WRLDName storage wrldName = wrldNames[nameTokenId[_names[i]]];
      wrldName.expiresAt = wrldName.expiresAt + YEAR_SECONDS * _additionalYears[i];

      emit NameRegistrationExtended(_names[i], _names[i], _additionalYears[i]);
    }

    if (_hasBridge()) {
      bridge.extendRegistration(_names, _additionalYears);
    }
  }

  /***********
   * Resolve *
   ***********/

  function nameAvailable(string memory _name) external view normalizeName(_name) returns (bool) {
    return !nameExists(_name) || getNameExpiration(_name) < block.timestamp;
  }

  function nameExists(string memory _name) public view normalizeName(_name) returns (bool) {
    return nameTokenId[_name] != 0;
  }

  function getNameTokenId(string memory _name) external view override normalizeName(_name) returns (uint256) {
    return nameTokenId[_name];
  }

  function getTokenName(uint256 _tokenId) external view returns (string memory) {
    return wrldNames[_tokenId].name;
  }

  function getName(string memory _name) external view normalizeName(_name) returns (WRLDName memory) {
    return wrldNames[nameTokenId[_name]];
  }

  function getNameOwner(string memory _name) public view normalizeName(_name) returns (address) {
    return ownerOf(nameTokenId[_name]);
  }

  function getNameController(string memory _name) public view normalizeName(_name) returns (address) {
    return wrldNames[nameTokenId[_name]].controller;
  }

  function getNameExpiration(string memory _name) public view normalizeName(_name) returns (uint256) {
    return wrldNames[nameTokenId[_name]].expiresAt;
  }

  function getNameStringRecord(string memory _name, string calldata _record) external view normalizeName(_name) returns (StringRecord memory) {
    return resolver.getNameStringRecord(_name, _record);
  }

  function getNameStringRecordsList(string memory _name) external view normalizeName(_name) returns (string[] memory) {
    return resolver.getNameStringRecordsList(_name);
  }

  function getNameStringRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory) {
    return resolver.getNameStringRecordsListPaginated(_name, _offset, _limit);
  }

  function getNameAddressRecord(string memory _name, string calldata _record) external view normalizeName(_name) returns (AddressRecord memory) {
    return resolver.getNameAddressRecord(_name, _record);
  }

  function getNameAddressRecordsList(string memory _name) external view normalizeName(_name) returns (string[] memory) {
    return resolver.getNameAddressRecordsList(_name);
  }

  function getNameAddressRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory) {
    return resolver.getNameAddressRecordsListPaginated(_name, _offset, _limit);
  }

  function getNameUintRecord(string memory _name, string calldata _record) external view normalizeName(_name) returns (UintRecord memory) {
    return resolver.getNameUintRecord(_name, _record);
  }

  function getNameUintRecordsList(string memory _name) external view normalizeName(_name) returns (string[] memory) {
    return resolver.getNameUintRecordsList(_name);
  }

  function getNameUintRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory) {
    return resolver.getNameUintRecordsListPaginated(_name, _offset, _limit);
  }

  function getNameIntRecord(string memory _name, string calldata _record) external view normalizeName(_name) returns (IntRecord memory) {
    return resolver.getNameIntRecord(_name, _record);
  }

  function getNameIntRecordsList(string memory _name) external view normalizeName(_name) returns (string[] memory) {
    return resolver.getNameIntRecordsList(_name);
  }

  function getNameIntRecordsListPaginated(string calldata _name, uint256 _offset, uint256 _limit) external view returns (string[] memory) {
    return resolver.getNameIntRecordsListPaginated(_name, _offset, _limit);
  }

  function getStringEntry(address _setter, string memory _name, string calldata _entry) external view normalizeName(_name) returns (string memory) {
    return resolver.getStringEntry(_setter, _name, _entry);
  }

  function getAddressEntry(address _setter, string memory _name, string calldata _entry) external view normalizeName(_name) returns (address) {
    return resolver.getAddressEntry(_setter, _name, _entry);
  }

  function getUintEntry(address _setter, string memory _name, string calldata _entry) external view normalizeName(_name) returns (uint256) {
    return resolver.getUintEntry(_setter, _name, _entry);
  }

  function getIntEntry(address _setter, string memory _name, string calldata _entry) external view normalizeName(_name) returns (int256) {
    return resolver.getIntEntry(_setter, _name, _entry);
  }

  /***********
   * Control *
   ***********/

  function migrate(string memory _name, uint256 _networkFlags) external normalizeName(_name) isOwnerOrController(_name) {
    require(_hasBridge(), "Bridge not set");

    bridge.migrate(_name, _networkFlags);
  }

  function setController(string memory _name, address _controller) external normalizeName(_name) {
    require(getNameOwner(_name) == msg.sender, "Sender is not owner");

    wrldNames[nameTokenId[_name]].controller = _controller;

    emit NameControllerUpdated(_name, _name, _controller);

    if (_hasBridge()) {
      bridge.setController(_name, _controller);
    }
  }

  function setStringRecord(string memory _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external normalizeName(_name) isOwnerOrController(_name) {
    resolver.setStringRecord(_name, _record, _value, _typeOf, _ttl);

    emit ResolverStringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl, address(resolver));

    if (_hasBridge()) {
      bridge.setStringRecord(_name, _record, _value, _typeOf, _ttl);
    }
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external normalizeName(_name) isOwnerOrController(_name) {
    resolver.setAddressRecord(_name, _record, _value, _ttl);

    emit ResolverAddressRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));

    if (_hasBridge()) {
      bridge.setAddressRecord(_name, _record, _value, _ttl);
    }
  }

  function setUintRecord(string memory _name, string calldata _record, uint256 _value, uint256 _ttl) external normalizeName(_name) isOwnerOrController(_name) {
    resolver.setUintRecord(_name, _record, _value, _ttl);

    emit ResolverUintRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));

    if (_hasBridge()) {
      bridge.setUintRecord(_name, _record, _value, _ttl);
    }
  }

  function setIntRecord(string memory _name, string calldata _record, int256 _value, uint256 _ttl) external normalizeName(_name) isOwnerOrController(_name) {
    resolver.setIntRecord(_name, _record, _value, _ttl);

    emit ResolverIntRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));

    if (_hasBridge()) {
      bridge.setIntRecord(_name, _record, _value, _ttl);
    }
  }

  /***********
   * Entries *
   ***********/

  function setStringEntry(string memory _name, string calldata _entry, string calldata _value) external normalizeName(_name) {
    resolver.setStringEntry(msg.sender, _name, _entry, _value);

    emit ResolverStringEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (_hasBridge()) {
      bridge.setStringEntry(msg.sender, _name, _entry, _value);
    }
  }

  function setAddressEntry(string memory _name, string calldata _entry, address _value) external normalizeName(_name) {
    resolver.setAddressEntry(msg.sender, _name, _entry, _value);

    emit ResolverAddressEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (_hasBridge()) {
      bridge.setAddressEntry(msg.sender, _name, _entry, _value);
    }
  }

  function setUintEntry(string memory _name, string calldata _entry, uint256 _value) external normalizeName(_name) {
    resolver.setUintEntry(msg.sender, _name, _entry, _value);

    emit ResolverUintEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (_hasBridge()) {
      bridge.setUintEntry(msg.sender, _name, _entry, _value);
    }
  }

  function setIntEntry(string memory _name, string calldata _entry, int256 _value) external normalizeName(_name) {
    resolver.setIntEntry(msg.sender, _name, _entry, _value);

    emit ResolverIntEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);

    if (_hasBridge()) {
      bridge.setIntEntry(msg.sender, _name, _entry, _value);
    }
  }

  /*********
   * Owner *
   *********/

  function setApprovedWithdrawer(address _approvedWithdrawer) external onlyOwner {
    approvedWithdrawer = _approvedWithdrawer;
  }

  function setApprovedRegistrar(address _approvedRegistrar, bool _approved) external onlyOwner {
    approvedRegistrars[_approvedRegistrar] = _approved;
  }

  function setMetadataContract(address _metadata) external onlyOwner {
    IWRLD_Name_Service_Metadata metadataContract = IWRLD_Name_Service_Metadata(_metadata);

    require(metadataContract.supportsInterface(type(IWRLD_Name_Service_Metadata).interfaceId), "Invalid metadata contract");

    metadata = metadataContract;
  }

  function setResolverContract(address _resolver) external onlyOwner {
    IWRLD_Name_Service_Resolver resolverContract = IWRLD_Name_Service_Resolver(_resolver);

    require(resolverContract.supportsInterface(type(IWRLD_Name_Service_Resolver).interfaceId), "Invalid resolver contract");

    resolver = resolverContract;
  }

  function setBridgeContract(address _bridge) external onlyOwner {
    IWRLD_Name_Service_Bridge bridgeContract = IWRLD_Name_Service_Bridge(_bridge);

    require(bridgeContract.supportsInterface(type(IWRLD_Name_Service_Bridge).interfaceId), "Invalid bridge contract");

    bridge = bridgeContract;
  }

  /*************
   * Overrides *
   *************/

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    WRLDName storage wrldName = wrldNames[tokenId];

    wrldName.controller = to;

    resolver.setAddressRecord(wrldName.name, "evm_default", to, 3600);
    emit ResolverAddressRecordUpdated(wrldName.name, wrldName.name, "evm_default", to, 3600, address(resolver));

    if (_hasBridge()) {
      bridge.transfer(from, to, tokenId, wrldName.name);
    }

    super._beforeTokenTransfer(from, to, tokenId);
  }

  /***********
   * Helpers *
   ***********/

  function _hasBridge() private view returns (bool) {
    return address(bridge) != address(0);
  }

  function _generateNameId(string memory _name) private pure returns (uint256) {
    return uint256(uint160(uint256(keccak256(bytes(_name)))));
  }

  /*************
   * Modifiers *
   *************/

  modifier isApprovedRegistrar() {
    require(approvedRegistrars[msg.sender], "msg sender is not registrar");
    _;
  }

  modifier isOwnerOrController(string memory _name) {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");
    _;
  }

  modifier normalizeName(string memory _name) {
    _name = _name.UTS46Normalize();
    _;
  }
}