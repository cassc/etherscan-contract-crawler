// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

// Errors
string constant errorMint = 'MFT: mint data error';
string constant errorMetadataID = 'MFT: invalid metadataID';
string constant errorNoMetadata = 'MFT: no metadata';
string constant errorAlreadyMinted = 'MFT: already minted';

/// @custom:security-contact [email protected]
contract MusicForTraders is ERC1155, ERC2981, Ownable {
  using Strings for uint256;

  // Emitted when Owner freezes the metadata of a token
  event PermanentURI(string _value, uint256 indexed _id);

  // Emitted when Owner sets a new viewer URI
  event Viewer(string viewerURI);

  // Emitted when Owner sets a new viewer URI
  event NewURI(string metadataURI, uint16 metadataID);

  // Mapping of metadataID to metadata URI
  mapping(uint16 => string) private _uriMap;

  // Mapping of metadataID to lock
  mapping(uint16 => bool) private _metadataLock;

  // Mapping of tokenID to metadataID
  mapping(uint256 => uint16) private _metadataMap;

  // Viewer URI
  string public viewerURI = '';

  // OpenSea contract URI
  string public contractURI = '';

  string public constant name = 'Music For Traders';
  string public constant symbol = 'MFT';

  constructor(string memory viewerURI_, string memory contractURI_)
    ERC1155('')
  {
    setViewerURI(viewerURI_);
    setContractURI(contractURI_);
    _setDefaultRoyalty(owner(), 750);
  }

  /**
   *
   * @dev Minting
   *
   */

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint16[] memory metadataIDs,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    require(to != address(0), 'ERC1155: zero address');
    require(
      ids.length == metadataIDs.length && ids.length == amounts.length,
      'MFT: array mismatch'
    );
    for (uint256 i = 0; i < ids.length; i++) {
      require(ids[i] > 0 && metadataIDs[i] > 0, errorMint);
      require(_metadataMap[ids[i]] == 0, errorAlreadyMinted);
      _metadataMap[ids[i]] = metadataIDs[i];
    }
    _mintBatch(to, ids, amounts, data);
  }

  /**
   *
   * @dev Metadata uri
   *
   */

  function setURIFor(uint16 metadataID, string memory metadataURI)
    public
    onlyOwner
  {
    require(metadataID > 0, errorMetadataID);
    _uriMap[metadataID] = metadataURI;
    emit NewURI(metadataURI, metadataID);
  }

  function _validMetadataID(uint16 metadataID)
    private
    view
    returns (bool check)
  {
    require(metadataID > 0, errorMetadataID);
    return
      keccak256(abi.encodePacked(_uriMap[metadataID])) !=
      keccak256(abi.encodePacked(''));
  }

  function uri(uint256 id) public view override returns (string memory) {
    require(
      id > 0 && _metadataMap[id] > 0 && _validMetadataID(_metadataMap[id]),
      errorNoMetadata
    );
    return string(abi.encodePacked(_uriMap[_metadataMap[id]], id.toString()));
  }

  function lockURIFor(uint16 metadataID) public onlyOwner {
    require(_validMetadataID(metadataID), errorNoMetadata);
    _metadataLock[metadataID] = true;
  }

  function lockTokenMetadata(uint256[] memory ids) public onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
      require(
        _metadataMap[ids[i]] > 0 && _validMetadataID(_metadataMap[ids[i]]),
        errorNoMetadata
      );
      if (!_metadataLock[_metadataMap[ids[i]]])
        lockURIFor(_metadataMap[ids[i]]);
      emit PermanentURI(uri(ids[i]), ids[i]);
    }
  }

  /**
   *
   * @dev Viewer uri
   *
   */

  function setViewerURI(string memory newURI) public onlyOwner {
    viewerURI = newURI;
    emit Viewer(viewerURI);
  }

  /**
   *
   * @dev OpenSea support
   *
   */

  function setContractURI(string memory URI) public onlyOwner {
    contractURI = string(abi.encodePacked('ipfs://', URI));
  }

  // Specifically whitelist OpenSea proxy
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    // OpenSea's ERC115 Proxy Address
    if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
      return true;
    }
    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
   *
   * @dev EIP165 Support
   *
   */

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   *
   * @dev Royalties
   *
   */

  function setRoyalties(address newRecipient) public onlyOwner {
    require(newRecipient != address(0), 'Royalties: zero address');
    _setDefaultRoyalty(newRecipient, 750);
  }
}