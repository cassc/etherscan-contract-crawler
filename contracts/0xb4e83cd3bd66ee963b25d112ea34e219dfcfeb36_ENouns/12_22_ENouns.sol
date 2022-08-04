//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC721K } from "./ERC721K.sol";
import { ERC721Storage } from "./ERC721Storage.sol";
import { ENounsRender } from "./ENounsRender.sol";
import { NameEncoder } from "./libraries/NameEncoder.sol";
import { IENSReverseRecords } from "./interfaces/IENSReverseRecords.sol";

/**
 * @title eNouns
 * @author Kames Geraghty
 * @notice Ethereum Noun System;  one Noun for every Primary ENS Name.
 */
contract ENouns is ERC721K {
  using NameEncoder for string;

  /// @notice ENSReverseRecords instance
  address private _ensReverseRecords;

  /// @notice Reverse lookup of a tokenId using the owner address
  mapping(address => uint256) private _userToTokenId;

  /// @notice TokenID mapped to ENS domain node i.e. Nouns seedEntropy
  mapping(uint256 => bytes32) internal _tokenIdToEnsNode;

  /// @notice ENS node mapped to Owner address
  mapping(bytes32 => address) internal _ensReverseRecordsMap;

  event EnsReverseRecordsUpdated(address ensReverseRecords);

  /**
   * @notice ENouns Construction
   * @param name string - Name of ERC721 token
   * @param symbol string - Symbol of ERC721 token
   * @param erc721Storage address - ERC721Storage instance
   * @param ensReverseRecords address - ENSReverseRecords instance
   */
  constructor(
    string memory name,
    string memory symbol,
    address erc721Storage,
    address ensReverseRecords
  ) ERC721K(name, symbol, erc721Storage) {
    _ensReverseRecords = ensReverseRecords;
  }

  receive() external payable {
    _checkAndIssue(_msgSender());
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function getEnsReverseRecords() external view returns (address) {
    return _ensReverseRecords;
  }

  function getId(address user) external view returns (uint256) {
    return _userToTokenId[user];
  }

  function isOwner(address user) external view returns (bool) {
    return _userToTokenId[user] > 0 ? true : false;
  }

  function preview(address user) external view returns (string memory) {
    return ENounsRender(ERC721Storage(_erc721Storage).getSvgRender()).renderUsingAddress(user);
  }

  function previewUsingEnsName(string memory name) external view returns (string memory) {
    return ENounsRender(ERC721Storage(_erc721Storage).getSvgRender()).renderUsingEnsName(name);
  }

  function claim() external payable {
    _checkAndIssue(_msgSender());
  }

  function setEnsReverseRecords(address _ensReverseRecords) external onlyOwner {
    _ensReverseRecords = _ensReverseRecords;
    emit EnsReverseRecordsUpdated(_ensReverseRecords);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    if (from == address(0)) {
      _issue(to, ++_idCounter);
    } else {
      _reissue(from, to, tokenId);
    }
  }

  function withdraw(uint256 amount) external onlyOwner {
    (bool _success, ) = _msgSender().call{ value: amount }("");
    require(_success, "ENouns:uh-oh");
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _checkAndIssue(address _sender) internal {
    if (balanceOf(_sender) == 0) {
      unchecked {
        _issue(_sender, ++_idCounter); /// @dev 🤯
      }
    } else {
      revert("ENouns:prev-issued");
    }
  }

  function _tokenData(uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bytes memory, bytes memory)
  {
    bytes memory ensNode = bytes(abi.encode(_tokenIdToEnsNode[tokenId]));
    bytes memory ownerEncoded_ = bytes(abi.encode(ownerOf(tokenId)));
    return (ensNode, ownerEncoded_);
  }

  function _encodeName(string memory _name) internal pure returns (bytes32) {
    (, bytes32 _node) = _name.dnsEncodeName();
    return _node;
  }

  function _reverseName(address _address) internal view returns (string memory) {
    address[] memory lookup_ = new address[](1);
    lookup_[0] = _address;
    return IENSReverseRecords(_ensReverseRecords).getNames(lookup_)[0];
  }

  function _issue(address _to, uint256 _tokenId) internal returns (uint256) {
    bytes32 node = _encodeName(_reverseName(_to));
    require(node != "", "ENouns:invalid-ens-node");
    require(_ensReverseRecordsMap[node] == address(0), "eNouns:prev-issued");
    _mint(_to, _tokenId);
    _userToTokenId[_to] = _tokenId;
    _tokenIdToEnsNode[_tokenId] = node;
    _ensReverseRecordsMap[node] = _to;
    return _tokenId;
  }

  function _reissue(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal returns (uint256) {
    require(_ensReverseRecordsMap[_encodeName(_reverseName(_to))] == _from, "eNouns:invalid-ens");
    _transfer(_from, _to, _tokenId);
    _userToTokenId[_from] = 0;
    _userToTokenId[_to] = _tokenId;
  }
}