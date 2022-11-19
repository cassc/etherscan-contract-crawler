//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


pragma solidity ^0.8.3;

interface ContractRegistryInterface {
  function get(string memory contractName) external view returns (address);
}


interface NamespaceInterface {
  function checkName(uint256 id, uint256 name, bytes memory constraintsData) external view;
}

contract Domain is ERC1155, AccessControl, Ownable {
  
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  uint256 public tokenSupply;

    /**
   * @dev Require msg.sender to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require msg.sender to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balanceOf(msg.sender, _id) > 0, "ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;
  // Contract base url
  string public _baseURI;
  
  ContractRegistryInterface public immutable _contractRegistry;
  // which namespace does the domain belong to?
  mapping(uint256 => uint256) _domainToNamespace;
  // which domains are suspended?
  // users of the system should disregard suspended domains
  mapping(uint256 => bool) _suspensions;

  // =====
  // ROLES
  // =====

  // can update metadata
  bytes32 public constant ADMIN_AGENT = keccak256("1");

  // can mark domains as suspended.
  bytes32 public constant SUSPENSION_AGENT = keccak256("2");

  // can lease domains that are currently available or within the grace period
  bytes32 public constant LEASING_AGENT = keccak256("3");

  // can transfer domains at any time
  bytes32 public constant REVOCATION_AGENT = keccak256("5");

  event Register(address agent, address indexed registrant, uint256 indexed name);
  event Suspend(address agent, uint256 indexed name, bool suspended);
  event Revoke(address agent, address indexed holder, uint256 indexed name);

  function getRoleForNamespace(bytes32 role, uint256 namespaceId) public pure returns (bytes32) {
    bytes32 _role = keccak256(abi.encodePacked(role, namespaceId));
    return _role;
  }

  function _hasRoleForNamespace(bytes32 role, uint256 namespaceId) internal view returns (bool) {
    return hasRole(getRoleForNamespace(role, namespaceId), msg.sender);
  }

  function _checkNameMatchesNamespace(uint256 _name, uint256 namespaceId) internal view {
    require(_domainToNamespace[_name] == namespaceId, "Domain: Namespace mismatch");
  }

  function getNamespaceId(
    uint256 domainId
  ) external view returns (uint256) {
    return _domainToNamespace[domainId];
  }

  function suspend(
    uint256 namespaceId,
    uint256 _name,
    bool suspended
  ) external {
    require(_hasRoleForNamespace(SUSPENSION_AGENT, namespaceId), "Domain: Invalid permissions");
    _checkNameMatchesNamespace(_name, namespaceId);
    _suspensions[_name] = suspended;
    emit Suspend(msg.sender, _name, suspended);
  }

  function isSuspended(
    uint256 _name
  ) external view returns (bool suspended) {
    return _suspensions[_name];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return (
      ERC1155.supportsInterface(interfaceId)
      || AccessControl.supportsInterface(interfaceId)
    );
  }

  function revoke(
    address from, 
    address to, 
    uint256 namespaceId,
    uint256 _name
  ) external {
    require(
      _hasRoleForNamespace(REVOCATION_AGENT, namespaceId),
      "Domain: Invalid permissions"
    );
    _checkNameMatchesNamespace(_name, namespaceId);
    _safeTransferFrom(from, to, _name, 1, '');
    emit Revoke(msg.sender, to, _name);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) override internal virtual {

    bool invalidTransfer = false;
    for (uint i = 0; i < ids.length; i ++) {
        if (_suspensions[ids[i]]) invalidTransfer = true;
    }
    require(!invalidTransfer, "Domain: Cannot transfer suspended domain");
    super._beforeTokenTransfer(operator,
    from,
    to,
    ids,
    amounts,
    data);
  }

 // used by the leasing agent to register domains
  function register(
    address registrant,
    uint256 namespaceId,
    uint256 _name
  ) external {

    require(
      _hasRoleForNamespace(LEASING_AGENT, namespaceId),
      "Domain: Invalid permissions"
    );

    require(!_suspensions[_name], "Domain: Cannot register suspended domain");

    bool tokenExists = _exists(_name);
    if (tokenExists) {
      _checkNameMatchesNamespace(_name, namespaceId);
    }

    emit Register(msg.sender, registrant, _name);

    // if the domain hasn't been minted already,
    // let's proceed with minting 
    if (!tokenExists) {
      _domainToNamespace[_name] = namespaceId;
      creators[_name] = registrant;
      mint(registrant, _name, 1, "");
    } 
  }

 function setBaseURI(string memory _uri) public onlyOwner {
    _baseURI = _uri;
 }
 
 function tokenURI(uint256 _tokenId) public view returns (string memory) {
  return  string(abi.encodePacked(_baseURI, Strings.toString(_tokenId)));
}
   /**
    * @dev Returns the total quantity for a token ID
    * @return amount of token in existence
    */
  function totalSupply(
  ) public view returns (uint256) {
    return tokenSupply;
  }

  /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) internal {
    _mint(_to, _id, _quantity, _data);
    tokenSupply = tokenSupply + _quantity;
  }

  /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    * @param _data        Data to pass if receiver is contract
    */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) internal {
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      require(creators[_id] == msg.sender, "batchMint: ONLY_CREATOR_ALLOWED");
      uint256 quantity = _quantities[i];
      tokenSupply = tokenSupply + quantity;
    }
    batchMint(_to, _ids, _quantities, _data);
  }
  /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }  

  function exists(
    uint256 _id
  ) public view returns (bool) {
    return _exists(_id);
  }

  constructor(string memory _name, string memory _symbol, string memory uri,  ContractRegistryInterface contractRegistry) ERC1155(uri) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _contractRegistry = contractRegistry;
    name = _name;
    _mint(msg.sender, uint256(0), 100000, "");
    symbol = _symbol;
  }
}