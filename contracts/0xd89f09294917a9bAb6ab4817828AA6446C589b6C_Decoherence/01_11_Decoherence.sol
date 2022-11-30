// SPDX-License-Identifier: MIT
// Contract by Highland, koloz, and Van Arman

/*                                                                             
  ____   _____  _____  _____  _____  _____  _____  _____  _____  _____  _____  
 |    \ |   __||     ||     ||  |  ||   __|| __  ||   __||   | ||     ||   __| 
 |  |  ||   __||   --||  |  ||     ||   __||    -||   __|| | | ||   --||   __| 
 |____/ |_____||_____||_____||__|__||_____||__|__||_____||_|___||_____||_____|                                                                             
                   _           _____              _____                       
                  | |_  _ _   |  |  | ___  ___   |  _  | ___  _____  ___  ___ 
                  | . || | |  |  |  || .'||   |  |     ||  _||     || .'||   |
                  |___||_  |   \___/ |__,||_|_|  |__|__||_|  |_|_|_||__,||_|_|
                       |___|                                                  

*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract Decoherence is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256; 
  using EnumerableSet for EnumerableSet.AddressSet;

  error Unauthorized();
  error CantAddToOFFList();
  error DeadmanTriggerStillActive();

  enum ListType {
    OFF,
    ALLOW,
    DENY
  }

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = 'ipfs://QmUytvA7UnA3ZQ6o2haBvXqg1mYeWMBPF8zuxifhWrD9Eq/';
  string public uriSuffix = '';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public shuffled = false;
  
  /// @notice Returns the ListType currently being used;
  /// @return ListType of the list. Values are: 0 (OFF), 1 (ALLOW), 2 (DENY)
  ListType public listType;
  
  /// @notice The datetime threshold after which the deadman trigger can be called by anyone.
  /// @return uint256 denoting unix epoch time after which the deadman trigger can be activated.
  uint256 public deadmanListTriggerAfterDatetime;

  mapping(ListType => EnumerableSet.AddressSet) private list;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    ListType _listType,
    address[] memory _addresses,
    uint256 _deadmanListTriggerDurationInYears
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    
    listType = _listType;

    deadmanListTriggerAfterDatetime = block.timestamp + _deadmanListTriggerDurationInYears * 365 days;

    if (_listType != ListType.OFF) {
      for (uint256 i = 0; i < _addresses.length; i++) {
        list[_listType].add(_addresses[i]);
      }
    }
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  /*//////////////////////////////////////////////////////////////////////////
                        RoyaltyGuard Functions START
  //////////////////////////////////////////////////////////////////////////*/
  modifier checkList(address _addr) {
    if (listType == ListType.ALLOW) {
      if (!list[ListType.ALLOW].contains(_addr)) revert Unauthorized();
    } else if (listType == ListType.DENY) {
      if (list[ListType.DENY].contains(_addr)) revert Unauthorized();
    }
    _;
  }

  /// @notice Toggles the list type between ALLOW, DENY, or OFF
  /// @dev Only the contract owner can call this function.
  /// @param _newListType to be applied to the list. Options are 0 (OFF), 1 (ALLOW), 2 (DENY)
  function toggleListType(ListType _newListType) external onlyOwner {
    listType = _newListType;
  }

  /// @notice Adds a list of addresses to the specified list.
  /// @dev Only the contract owner can call this function.
  /// @dev Cannot add to the OFF list
  /// @param _listType that addresses are being added to
  /// @param _addrs being added to the designated list
  function batchAddAddressToRoyaltyList(ListType _listType, address[] calldata _addrs) external onlyOwner {
    if (_listType == ListType.OFF) revert CantAddToOFFList();
    for (uint256 i = 0; i < _addrs.length; i++) {
      list[_listType].add(_addrs[i]);
    }
  }

  /// @notice Removes a list of addresses to the specified list.
  /// @dev Only the contract owner can call this function.
  /// @param _listType that addresses are being removed from
  /// @param _addrs being removed from the designated list
  function batchRemoveAddressToRoyaltyList(ListType _listType, address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      list[_listType].remove(_addrs[i]);
    }
  }

  /// @notice Clears an entire list.
  /// @dev Only the contract owner can call this function.
  /// @param _listType of list being cleared.
  function clearList(ListType _listType) external onlyOwner {
    delete list[_listType];
  }

  /// @notice Returns the set of addresses on a list.
  /// @param _listType of list being retrieved.
  /// @return list of addresses on a given list.
  function getList(ListType _listType) external view returns (address[] memory) {
    return list[_listType].values();
  }

  /// @notice Returns the set of addresses on the current in use list.
  /// @return list of addresses on a given list.
  function getInUseList() external view returns (address[] memory) {
    return list[listType].values();
  }

  /// @notice Returns if the supplied operator address in part of the current in use list.
  /// @param _operator address being checked.
  /// @return bool relating to if the operator is on the list.
  function isOperatorInList(address _operator) external view returns (bool) {
    return list[listType].contains(_operator);
  }

  /// @notice Sets the deadman list trigger for the specified number of years from current block timestamp
  /// @dev Only the contract owner can call this function.
  /// @param _numYears to renew the trigger for.
  function setDeadmanListTriggerDatetime(uint256 _numYears) external onlyOwner {
    deadmanListTriggerAfterDatetime = block.timestamp + _numYears * 365 days;
  }

  /// @notice Triggers the deadman switch for the list
  /// @dev Can only be called if deadmanListTriggerAfterDatetime is in the past.
  function activateDeadmanListTrigger() external {
    if (deadmanListTriggerAfterDatetime > block.timestamp) revert DeadmanTriggerStillActive();
    listType = ListType.OFF;
  }
  
  /*//////////////////////////////////////////////////////////////////////////
                        RoyaltyGuard Functions END
  //////////////////////////////////////////////////////////////////////////*/

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function approve(address to, uint256 tokenId) public payable virtual override checkList(to) {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override checkList(operator) {
    super.setApprovalForAll(operator, approved);
  }
}