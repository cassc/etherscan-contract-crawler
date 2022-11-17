// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './ERC1155.sol';
import './ERC1155Metadata.sol';
import './ERC1155Mint.sol';

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155Mint, ERC1155Metadata, Ownable {
  using Strings for uint256;

  
  uint8 private _currentTokenID;

  mapping (uint256 => uint256) public tokenSupply;

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _metadataURI
  ) {
    name = _name;
    symbol = _symbol;
    _setBaseMetadataURI(_metadataURI);
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return uri(tokenId);
  }

  function uri(
    uint256 _id
  ) public view override returns (string memory) {
    require(_exists(_id), "ERC1155Tradeable#uri: NONEXISTENT_TOKEN");
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
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @return The newly created token ID
    */
  function _create(
    address _initialOwner,
    uint256 _initialSupply
  ) internal returns (uint8) {

    uint8 _id = getNextTokenID(); 
    _incrementTokenTypeId();

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
  function _mint(
    address _to,
    uint8 _id,
    uint256 _quantity
  ) internal {
    _mint(_to, _id, _quantity, "");
    tokenSupply[_id] += _quantity;
  }

  /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    */
  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities
  ) internal {
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      uint256 quantity = _quantities[i];
      tokenSupply[uint8(_id)] += uint16(quantity);
    }
    _batchMint(_to, _ids, _quantities, "");
  }

  /**
    * @dev Returns whether the specified token exists by checking the token supply
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return tokenSupply[_id] > 0;
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
  function getNextTokenID() public view returns (uint8) {
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
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
  
}