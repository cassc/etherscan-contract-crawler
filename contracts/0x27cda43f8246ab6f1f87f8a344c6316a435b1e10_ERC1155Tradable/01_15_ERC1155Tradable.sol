// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/utils/Strings.sol";

import './IERC1155Tradable.sol';
import './ERC1155.sol';
import './ERC1155Metadata.sol';
import './ERC1155MintBurn.sol';
import "../Ownable.sol";
 
contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is IERC1155Tradable, ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
  using Strings for uint256;

  address proxyRegistryAddress;
  uint256 private _currentTokenID;
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;

  mapping(address => bool) public isAllowedToCreate;
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  /**
   * @dev Require_msgSender() to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] ==_msgSender() && isAllowedToCreate[_msgSender()], "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require_msgSender() to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balances[msg.sender][_id] > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _metadataURI,
    address _proxyRegistryAddress,
    address owner
  ) Ownable(owner) {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
    isAllowedToCreate[owner] = true;
    _setBaseMetadataURI(_metadataURI);
  }

  function uri(
    uint256 _id
  ) public view override returns (string memory) {
    require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
    return bytes(baseMetadataURI).length > 0 ? string(abi.encodePacked(baseMetadataURI, _id.toString())) : "";
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

  /**
  * @dev Sets address allowed to create 
  * @param _account account to allow/disallow
  * @param _allow true to allow, false to remove
  */
  function setAllowToCreate(address _account, bool _allow) public onlyOwner {
    isAllowedToCreate[_account] = _allow;
  }

  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @return The newly created token ID
    */
  function create(
    address _initialOwner,
    uint256 _initialSupply
  ) external override returns (uint256) {
    require(isAllowedToCreate[_msgSender()], "Not allowed");

    uint256 _id = getNextTokenID(); 
    _incrementTokenTypeId();
    creators[_id] =_msgSender();

    _mint(_initialOwner, _id, _initialSupply, "");
    tokenSupply[_id] = _initialSupply;
    return _id;
  }

  /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    */
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity
  ) public override creatorOnly(_id) {
    _mint(_to, _id, _quantity, "");
    tokenSupply[_id] += _quantity;
  }

  /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities
  ) public override {
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      require(creators[_id] ==_msgSender(), "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED");
      uint256 quantity = _quantities[i];
      tokenSupply[_id] += quantity;
    }
    _batchMint(_to, _ids, _quantities, "");
  }

  /**
    * @dev Change the creator address for given tokens
    * @param _to   Address of the new creator
    * @param _ids  Array of Token IDs to change creator
    */
  function setCreator(
    address _to,
    uint256[] memory _ids
  ) public override {
    require(_to != address(0), "ERC1155Tradable#setCreator: INVALID_ADDRESS.");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      _setCreator(_to, id);
    }
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public override(ERC1155, IERC1155) view returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    * @dev Change the creator address for given token
    * @param _to   Address of the new creator
    * @param _id  Token IDs to change creator of
    */
  function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
  {
      creators[_id] = _to;
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

  /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
  function getNextTokenID() public view returns (uint256) {
    return _currentTokenID + 1;
  }

  /**
    * @dev increments the value of _currentTokenID
    */
  function _incrementTokenTypeId() private  {
    _currentTokenID++;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC1155, ERC1155Metadata) virtual view returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId || _interfaceID == type(IERC1155Tradable).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
  
}