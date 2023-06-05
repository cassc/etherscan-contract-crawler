//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


// Error message codes
//E1155001 : Not authorized
//E1155002 : Transfer is currently not allowed
//E1155003 : Must be > 0
//E1155004 : Unable to mint, over limits for token based maxAmount
//E1155005 : Need to provide proper ETH value
//E1155006 : Unable to set metadata for the single token as sameMetadataForAll is enabled
//E1155007 : Count of Tokens and metadata has to be same
//E1155008 : Not allowed to mint
//E1155009 : Both TokenIDs and metadata should be provided
//E1155010 : TokenID must be provided
//E1155011 : Can't be 0
//E1155012 : Unable to mint, over limits for default set maxAmount
//E1155013 : Unable to mint, over limits for maxPerUser
//E1155014 : Token does not exist
//E1155015 : Zero address error

library EnumerableSet {
  struct UintSet {
    uint256[] _values;
    mapping(uint256 => uint256) _indexes;
  }

  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    if (contains(set, value)) {
      return false;
    }
    set._values.push(value);
    set._indexes[value] = set._values.length;
    return true;
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      unchecked {
        uint256 last = set._values[set._values.length - 1];
        set._values[valueIndex - 1] = last;
        set._indexes[last] = valueIndex;
      }

      set._values.pop();
      delete set._indexes[value];
      return true;
    } else {
      return false;
    }
  }
}

abstract contract ContextMixin {
  function msgSender() internal view returns (address payable sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = payable(msg.sender);
    }
    return sender;
  }
}

contract ERC1155NFT is ERC1155Supply, ContextMixin, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;
  using Strings for uint256;

  struct split_payment {
   address nftOwner;
   address itemMaker;
   uint256 nftOwnerPercentage;
   uint256 itemMakerPercentage;
   uint256 value;
   bool sold; 
   bool splitted;
  }

  string public name;
  string public symbol;
  string private baseURI;
  string private preRevealURI;
  bool private sameMetadataForAll;
  bool private selfMint;
  bool private pauseTransfer;

  uint256 private maxPerUser = 0;
  uint256 private defaultPrice = 0;
  uint256 private defaultMaxAmount = 0;
  address private owner;
  address private admin;

  mapping(uint256 => uint256) maxAmount;
  mapping(uint256 => uint256) price;

  mapping(uint256 => string) tokenURIs;

  mapping(uint256 => split_payment) paymentsDetails;

  /**
   * @dev Emitted when the metadata for token `_tokenId` gets updated to `_metadata` by the address `from`.
   */
  event MetadataUpdated(uint256 _tokenId, string _metadata, address from);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    string memory _preRevealURI,
    address _owner,
    address _admin
  ) ERC1155(_uri) {
    name = _name;
    symbol = _symbol;
    owner = _owner;
    admin = _admin;
    baseURI = _uri;
    preRevealURI = _preRevealURI;
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function _beforeTokenTransfer(
    address operator,
    address _from,
    address _to,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) internal whenNotPaused {
    super._beforeTokenTransfer(operator, _from, _to, _tokenIds, _amounts, '');
  }

  /**
   * @notice function to check if the sender is admin
   */
  function isAdmin(address account) public view returns (bool) {
    if (account == admin) return true;
    return false;
  }

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(isAdmin(_msgSender()), 'E1155001');
    _;
  }

  /**
   * @dev Throws if called when the transfer is paused by the admin.
   */
  modifier isTransferable() {
    require(!pauseTransfer || isAdmin(_msgSender()), 'E1155002');
    _;
  }

  /**
   * @notice function to check if the sender is the token owner or the admin.
   */
  function isOwnerOrAdmin(uint256 _tokenId) private view returns (bool) {
    return balanceOf(_msgSender(), _tokenId) > 0 || isAdmin(_msgSender());
  }

  /**
   * @notice function to change the owner of the contract
   */
  function changeOwner(address account) public virtual onlyAdmin {
    require(account != address(0), 'E1155015');
    owner = account;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory _uri) external onlyAdmin {
    baseURI = _uri;
  }

  /**
   * @notice function to enable self-minting so the user can connect to the smart contract and buy with cryptos
   * and requires the token price to be set
   */
  function enableSelfMint(bool _value) external onlyAdmin {
    selfMint = _value;
  }

  /**
   * @notice function to update the default nft price
   *
   * @param _tokenPrice default price for tokens
   */
  function setDefaultPrice(uint256 _tokenPrice) external onlyAdmin {
    require(_tokenPrice > 0, 'E1155003');
    defaultPrice = _tokenPrice;
  }

  /**
   * @notice function to update the nft price
   *
   * @param _tokenId token whose price is to be updated
   * @param _tokenPrice new token price
   */
  function updateTokenPrice(uint256 _tokenId, uint256 _tokenPrice)
    external
    onlyAdmin
  {
    require(_tokenId > 0, 'E1155010');
    require(_tokenPrice > 0, 'E1155003');
    price[_tokenId] = _tokenPrice;
  }

  /**
   * @notice function to set default maximum nfts which can be minted within the contract
   * @dev kind of total supply of the contract and act as a fallback when token specific limit is not set
   *
   * @param _maxAmount maximum mintable NFT by default
   */
  function setDefaultMaxAmount(uint256 _maxAmount) external onlyAdmin {
    require(_maxAmount > 0, 'E1155011');
    defaultMaxAmount = _maxAmount;
  }

  /**
   * @notice function to update maximum nfts which can be minted within the contract
   * @dev kind of total supply of the contract
   *
   * @param _tokenId token whose max amount is to be updated
   * @param _newMaxAmount maximum mintable NFT
   */
  function updateMaxAmount(uint256 _tokenId, uint256 _newMaxAmount)
    external
    onlyAdmin
  {
    require(_tokenId > 0, 'E1155010');
    require(_newMaxAmount > 0, 'E1155011');
    maxAmount[_tokenId] = _newMaxAmount;
  }

  /**
   * @notice function to update amount of NFT a user can receive/self mint
   *
   * @param _newMaxPerUser maximum nft a user can hold on to
   */
  function updateMaxPerUser(uint256 _newMaxPerUser) external onlyAdmin {
    require(_newMaxPerUser > 0, 'E1155011');
    maxPerUser = _newMaxPerUser;
  }

  /**
   * @notice function to pause the transfer of tokens
   * @dev kind of a security measure in case a fraudulent entity gets hold of a token
   */
  function pauseNFTTransfer(bool _value) external onlyAdmin {
    pauseTransfer = _value;
  }

  /**
   * @notice function to mint a token
   *
   * @param _to wallet to which the token will be minted
   * @param _tokenId id associated to the token to be minted
   * @param _amount number of tokens to be minted
   * @param _metadata metadata for the token
   */
  function mint(
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    string memory _metadata,
    address _itemMaker,
    uint256 _nftOwnerPercentage,
    uint256 _itemMakerPercentage
  ) external onlyAdmin whenNotPaused {
    _mint(_to, _tokenId, _amount, '');
    if (bytes(_metadata).length > 0 && sameMetadataForAll == false)
      _setTokenMetadata(_tokenId, _metadata);
    split_payment memory details;
    details.nftOwner = owner;
    details.itemMaker = _itemMaker;
    details.nftOwnerPercentage = _nftOwnerPercentage;
    details.itemMakerPercentage = _itemMakerPercentage;
    details.sold = false;
    details.splitted = false;
    paymentsDetails[_tokenId] = details;
  }

  /**
   * @notice function to buy a token by the user with the prerequisite of selfMint and price be set
   *
   * @param _tokenId id associated to the token to be minted
   * @param _amount number of tokens to be minted
   */
  function buy(uint256 _tokenId, uint256 _amount) public payable whenNotPaused {
    require(paymentsDetails[_tokenId].sold == false, "Token already sold");
    require(paymentsDetails[_tokenId].splitted == false, "Token payment already splitted");
    require(
      (maxPerUser > 0 &&
        balanceOf(msg.sender, _tokenId) + _amount <= maxPerUser) ||
        maxPerUser == 0,
      'E1155013'
    );
    uint256 currentTokenSupply = super.totalSupply(_tokenId);
    if (maxAmount[_tokenId] > 0) {
      require(currentTokenSupply + _amount <= maxAmount[_tokenId], 'E1155004');
    } else {
      require(
        (defaultMaxAmount > 0 &&
          currentTokenSupply + _amount <= defaultMaxAmount) ||
          defaultMaxAmount == 0,
        'E1155012'
      );
    }
    require(msg.value > 0, 'E1155005');
    if (price[_tokenId] > 0) {
      require(
        msg.value >= price[_tokenId] * _amount,
        string(
          abi.encodePacked(
            'Requires to have a price of at least, ',
            (price[_tokenId] * _amount).toString()
          )
        )
      );
    } else {
      require(
        defaultPrice > 0 && msg.value >= defaultPrice * _amount,
        string(
          abi.encodePacked(
            'Requires to have a price of at least, ',
            (defaultPrice * _amount).toString()
          )
        )
      );
    }
     _safeTransferFrom(admin, msg.sender, _tokenId, _amount, '');
    paymentsDetails[_tokenId].sold = true;
    splitPayments(_tokenId, msg.value);
  }

  /**
   * @notice function to be used within _mint and setTokenMetadata
   *
   * @param _tokenId id whose metadata will be set
   * @param _metadata the metadata
   */
  function _setTokenMetadata(uint256 _tokenId, string memory _metadata)
    private
  {
    require(exists(_tokenId), 'E1155014');
    require(
      sameMetadataForAll == false && bytes(_metadata).length > 0,
      'E1155006'
    );
    tokenURIs[_tokenId] = _metadata;
    emit MetadataUpdated(_tokenId, _metadata, msg.sender);
  }

  /**
   * @notice function to update metadata for a token
   *
   * @param _tokenId id whose metadata will be updated
   * @param _metadata which will be assigned to the token
   */
  function setTokenMetadata(uint256 _tokenId, string memory _metadata)
    public
    whenNotPaused
  {
    require(
      balanceOf(msg.sender, _tokenId) == totalSupply(_tokenId) ||
        isAdmin(_msgSender()),
      'E1155001'
    );
    _setTokenMetadata(_tokenId, _metadata);
  }

  /**
   * @notice function to set the preRevealURI for the contract
   */
  function setPreRevealURI(string memory _uri) public onlyAdmin {
    require(bytes(_uri).length > 0, 'E1155011');
    preRevealURI = _uri;
  }

  /**
   * @notice function to set sameMetadataForAll
   * @dev used to enable/disable pre-reveal
   */
  function setTokenMetadataForAll(bool value) public onlyAdmin {
    sameMetadataForAll = value;
  }



  /**
   * @notice function to transfer a single token
   *
   * @param _from wallet from which tokens will be transferred/debited
   * @param _to wallet to which token will be credited
   * @param _tokenId id which will be transferred
   * @param _amount number of tokens which will be transfered
   */
  function transfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount
  ) public whenNotPaused isTransferable {
    require(
      _from == _msgSender() ||
        _from == msg.sender ||
        isApprovedForAll(msg.sender, _msgSender()),
      'E1155001'
    );
    safeTransferFrom(_from, _to, _tokenId, _amount, '');
  }


  /**
   * @notice function to check if operator is opensea proxy
   */
  function isOpenSeaProxy(address _operator) internal view returns (bool) {
    // is polygon mainnet
    if (137 == block.chainid) {
      return (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101));
    }
    // is polygon testnet
    if (80001 == block.chainid) {
      return (_operator == address(0x53d791f18155C211FF8b58671d0f7E9b50E596ad));
    }

    return false;
  }

  /**
   * @notice function to override the isApprovedForAll from ERC721
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    whenNotPaused
    returns (bool isOperator)
  {
    if (isAdmin(_operator)) {
      return true;
    }
    return
      ERC1155.isApprovedForAll(_owner, _operator) || isOpenSeaProxy(_operator);
  }

  function _msgSender() internal view override(Context) returns (address ret) {
    return ContextMixin.msgSender();
  }

  function _baseURI() internal view returns (string memory) {
    return baseURI;
  }

  /**
   * @notice function to burn a single token
   *
   * @param _tokenId id which will be burned
   * @param _tokenId id which will be burned
   * @param _tokenId id which will be burned
   */
  function burn(
    address _account,
    uint256 _tokenId,
    uint256 _amount
  ) public whenNotPaused {
    require(_account == msg.sender || _account == _msgSender(), 'E1155001');
    _burn(_account, _tokenId, _amount);
  }

  /**
   * @notice function to burn tokens in batches
   *
   * @param _account array of id's which will be burned
   * @param _tokenIds array of id's which will be burned
   * @param _amounts array of id's which will be burned
   */
  function batchBurn(
    address _account,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) public virtual whenNotPaused {
    require(_account == msg.sender || _account == _msgSender(), 'E1155001');
    _burnBatch(_account, _tokenIds, _amounts);
  }

  /**
   * @notice function to return the metadata uri associated with a token id
   */
  function uri(uint256 _tokenId)
    public
    view
    override
    whenNotPaused
    returns (string memory)
  {
    if (sameMetadataForAll == true) {
      return preRevealURI;
    } else {
      string memory _tokenURI = tokenURIs[_tokenId];
      if (bytes(_tokenURI).length > 0) {
        return _tokenURI;
      } else {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
      }
    }
  }

  /**
   * @notice function to transfer the total ether currently held by the contract to the owner
   */
  function withdrawFunds() external {
    require(msg.sender == owner, 'E1155001');
    payable(msg.sender).transfer(address(this).balance);
  }

  /**
   * @notice function to transfer the total ether currently held by the contract to the owner
   */
  function splitPayments(uint256 tokenId, uint256 value) internal {
    require(paymentsDetails[tokenId].sold == true, "Token is not yet selled");
    require(paymentsDetails[tokenId].splitted == false, "Payment is already splitted for this Token");

    address nftOwner = paymentsDetails[tokenId].nftOwner;
    address itemMaker = paymentsDetails[tokenId].itemMaker;

    uint256 nftSellerToBePaid = value * paymentsDetails[tokenId].nftOwnerPercentage / 10000;
    uint256 nftMakerToBePaid = value * paymentsDetails[tokenId].itemMakerPercentage / 10000;

    payable(nftOwner).transfer(nftSellerToBePaid);
    payable(itemMaker).transfer(nftMakerToBePaid);

    paymentsDetails[tokenId].splitted = true;
    
  }
}