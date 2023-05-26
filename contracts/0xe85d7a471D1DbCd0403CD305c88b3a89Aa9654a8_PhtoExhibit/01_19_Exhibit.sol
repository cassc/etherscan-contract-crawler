// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./SaleStatus.sol";
import "./Collection.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title Phto Exhibit - fine art photography (phto.io)
contract PhtoExhibit is ERC1155, ReentrancyGuard, Ownable, PaymentSplitter, IERC2981 {
  /** Collections (drops) */
  Collection[] private collections_;
  /** Edition sizes */
  uint256[] private editions_;
  /** Name of collection */
  string public constant name = "Phto.";
  /** Symbol of collection */
  string public constant symbol = "PHTO";
  /** URI for the contract metadata */
  string public contractURI;
  /** Signer */
  address public signer;

  /** Mint pass utilization - collectionId -> address -> used */
  mapping(uint256 => mapping(address => bool)) public passes;

  /** For URI conversions */
  using Strings for uint256;

  /** Notify on sale state change */
  event SaleStateChanged(SaleStatus val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 val);
  /** Notify when a new collection is created */
  event CollectionCreated(uint256 val);

  constructor(
    string memory _uri, 
    address[] memory shareholders, 
    uint256[] memory shares
  ) ERC1155(_uri) PaymentSplitter(shareholders, shares) {}

  /// @notice Helper to return editions array
  function editions() external view returns (uint256[] memory) {
    return editions_;
  }

  /// @notice Helper to return collections array
  function collections() external view returns (Collection[] memory) {
    return collections_;
  }

  /// @notice Sets public sale state
  /// @param _val The new value
  function setSaleStatus(SaleStatus _val) external onlyOwner {
    collections_[currentCollectionId()].status = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets the authorized signer
  /// @param _val New signer
  function setSigner(address _val) external onlyOwner {
    signer = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setCollectionURI(string memory _val) external onlyOwner {
    collections_[currentCollectionId()].uri = _val;
  }

  /// @notice Sets the contract metadata URI
  /// @param _val The new URI
  function setContractURI(string memory _val) external onlyOwner {
    contractURI = _val;
  }

  /// @notice Returns the amount of tokens sold
  /// @return supply The number of tokens sold
  function totalSupply() public view returns (uint256 supply) {
    for (uint256 i = 0; i < collections_.length; i++) {
      supply += collections_[i].supply;
    }
  }

  /// @notice Current collection ID getter
  /// @return Currently active collection ID
  function currentCollectionId() public view returns (uint256) {
    require(collections_.length > 0, "No collections created.");
    return collections_.length - 1;
  }

  /// @notice Current collection getter
  /// @dev External usage to view current config
  /// @return Collection
  function currentCollection() external view returns (Collection memory) {
    return collections_[currentCollectionId()];
  }

  /// @notice Notify other contracts of supported interfaces
  /// @param interfaceId Magic bits
  /// @return Yes/no
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /// @notice Returns the URI for a given token ID
  /// @param _id The ID to return URI for
  /// @return Token URI
  function uri(uint256 _id) public view override returns (string memory) {
    (uint256 _collection, uint256 _identifier) = unshift(_id);
    return string(abi.encodePacked(collections_[_collection - 1].uri, _identifier.toString()));
  }

  /// @notice Get the royalty info for a given ID
  /// @param _tokenId NFT ID to check
  /// @param _salePrice Price sold for
  /// @return receiver The address receiving the royalty
  /// @return royaltyAmount The royalty amount to be received
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    (uint256 collection,) = unshift(_tokenId);
    Collection memory _coll = collections_[collection];
    receiver = _coll.royaltyReceiver;
    royaltyAmount = _coll.royaltyPercentage / 100 * _salePrice;
  }

  /// @notice Verify a signed message
  /// @param _ids IDs from api
  /// @param _amount amount from api
  /// @param _sig API signature
  function isValidData(address _receiver, uint256[] memory _ids, uint256 _amount, bytes memory _sig) public view returns(bool) {
    bytes32 _message = keccak256(abi.encodePacked(_receiver, _ids, _amount));
    return (recoverSigner(_message, _sig) == signer);
  }

  /// @notice Attempts to recover signer address
  /// @param _message Data
  /// @param _sig API signature
  /// @return address Signer address
  function recoverSigner(bytes32 _message, bytes memory _sig) public pure returns (address) {
    uint8 v;
    bytes32 r;
    bytes32 s;
    (v, r, s) = splitSignature(_sig);
    return ecrecover(_message, v, r, s);
  }

  /// @notice Attempts to split sig to VRS
  /// @param _sig API signature
  function splitSignature(bytes memory _sig) public pure returns (uint8, bytes32, bytes32) {
    require(_sig.length == 65);
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  /// @notice Pack collection ID and NFT ID into an int
  /// @param _coll Collection ID
  /// @param _id NFT ID
  /// @return Packed ID
  function shift(uint256 _coll, uint256 _id) public pure returns (uint256) {
    return (_coll << 128) | _id;
  }

  /// @notice Unpack collection ID and NFT ID from an int
  /// @param _id Packed ID
  /// @return collection Collection ID
  /// @return identifier NFT ID
  function unshift(uint256 _id) public pure returns (uint256 collection, uint256 identifier) {
    collection = _id >> 128;
    identifier = _id & ~uint128(0);
  }

  /// @notice Creates a new collection
  /// @param _maxTx Maximum mintable per tx
  /// @param _maxSupply Maximum tokens in collection
  /// @param _royaltyPercentage Percentage to be given from secondaries
  /// @param _cost Cost per token
  /// @param _royaltyReceiver Receiving address of royalties
  /// @param _uri Base URI
  function createCollection(
    uint128 _maxTx,
    uint128 _maxSupply,
    uint128 _royaltyPercentage,
    uint256 _cost,
    address _royaltyReceiver,
    string memory _uri,
    uint256[] calldata _sizes
  ) external onlyOwner {
    editions_ = _sizes;
    collections_.push(
      Collection(_maxTx, _maxSupply, _royaltyPercentage, 0, _cost, _royaltyReceiver, _uri, SaleStatus.Inactive)
    );

    emit CollectionCreated(currentCollectionId());
  }

  /// @notice Reserves NFTs for team/giveaways/etc
  /// @param _ids Potential IDs to be minted
  /// @param _amount Amount to be minted
  function reserve(uint256[] memory _ids, uint256 _amount) external onlyOwner {
    uint256 _collId = currentCollectionId();
    Collection storage _coll = collections_[_collId];
    _coll.supply += uint128(_amount);
    mintHelper(_collId, _ids, _amount);
    emit TotalSupplyChanged(_coll.supply);
  }

  /// @notice Internal mint helper
  /// @param _ids Potential IDs to be minted
  /// @param _amount Amount to be minted
  /// @dev Called by mint/preMint
  function mintHelper(uint256 _collId, uint256[] memory _ids, uint256 _amount) private {
    uint256 _counter = 0;
    for (uint256 i = 0; i < _ids.length; i++) {
      if (editions_[_ids[i]] == 0) { continue; }

      editions_[_ids[i]]--;
      _counter++;
      _mint(msg.sender, shift(_collId + 1, _ids[i]), 1, "0x0000");

      if (_amount == _counter) { break; }
      if (_ids.length - 1 == i) { i = 0; }
    }

    require(_amount == _counter, "Ran out of IDs.  Please retry.");
  }

  /// @notice Mints a new token in private (pre) sale
  /// @param _ids Potential IDs to be minted
  /// @param _amount Amount to be minted
  /// @param _sig Authorized wallet signature
  /// @dev No charge
  function preMint(uint256[] calldata _ids, uint256 _amount, bytes memory _sig) external payable nonReentrant {
    uint256 _collId = currentCollectionId();
    Collection storage _coll = collections_[_collId];
    require(_coll.status == SaleStatus.Presale, "Presale is not yet active.");
    require(isValidData(msg.sender, _ids, _amount, _sig), "Invalid signature");
    require(passes[_collId][msg.sender] == false, "Already redeemed.");
    passes[_collId][msg.sender] = true;
    _coll.supply += uint128(_amount);
    mintHelper(_collId, _ids, _amount);
    emit TotalSupplyChanged(_coll.supply);
  }

  /// @notice Mints a new token in public sale
  /// @param _ids Potential IDs to be minted
  /// @param _amount Amount to be minted
  /// @param _sig Authorized wallet signature
  /// @dev Must send COST * amt in ETH
  function mint(uint256[] calldata _ids, uint256 _amount, bytes memory _sig) external payable nonReentrant {
    uint256 _collId = currentCollectionId();
    Collection storage _coll = collections_[_collId];
    uint256 _currentSupply = _coll.supply;
    require(isValidData(msg.sender, _ids, _amount, _sig), "Invalid signature");
    require(_coll.status == SaleStatus.Public, "Sale is not yet active.");
    require(_coll.cost * _amount == msg.value, "ETH sent is not correct");
    require(_currentSupply + _amount <= _coll.maxSupply, "Amount exceeds supply.");
    _coll.supply += uint128(_amount);
    mintHelper(_collId, _ids, _amount);
    emit TotalSupplyChanged(_coll.supply);
  }

  /// @notice Burns a token
  /// @param _account Current token holder
  /// @param _id ID to burn
  /// @param _value Amount of ID to burn
  function burn(
    address _account,
    uint256 _id, 
    uint256 _value
  ) external nonReentrant {
    require(_account == _msgSender() || isApprovedForAll(_account, _msgSender()), "ERC1155: caller is not owner nor approved");
    (uint256 _collId,) = unshift(_id);
    Collection storage _coll = collections_[_collId - 1];
    _coll.supply -= uint128(_value);
    _burn(_account, _id, _value);
  }
}