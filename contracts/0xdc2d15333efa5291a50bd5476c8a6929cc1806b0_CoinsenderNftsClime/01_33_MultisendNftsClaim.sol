// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";


import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";


contract CoinsenderNftsClime is
  UUPSUpgradeable,
  OwnableUpgradeable,
  ERC2771ContextUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable,
  AccessControlEnumerableUpgradeable
{
  using SafeMathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  enum TokenType { ERC721, ERC1155 }

  string public constant name = "CoinsenderNftsClime";
  string public constant version = "1";

  struct NftTransfer {
    uint256 transferId;
    TokenType tokenType;
    address assetContract;
    uint256 tokenId;
    uint256 quantity;
    address sender;
    address recipient;
    bool claimed;
  }

  /// @dev transferId => Transfer
  mapping(uint256 => NftTransfer) private transfers;

  /// @dev id counter for transfers
  CountersUpgradeable.Counter private transferIdCounter;

  /// @dev Declare the maps
  mapping(address => EnumerableSetUpgradeable.UintSet) private senderTransfers;
  mapping(address => EnumerableSetUpgradeable.UintSet) private recipientTransfers;

  address public bank;
  uint256 public minFee;

  /**
  * @notice Emitted when ERC721 tokens are sent to multiple recipients.
  * @param sender - Address of the sender
  * @param token - Address of the ERC721 token contract
  * @param tokenIds - List of ERC721 token IDs that were sent
  * @param recipients - List of recipient addresses
  * @param fee - The fee paid for the transaction
  */
  event ERC721TokensSent(
    address indexed sender,
    address indexed token,
    uint256[] tokenIds,
    address[] recipients,
    uint256 fee
  );

  /**
  * @notice Emitted when ERC1155 tokens are sent to multiple recipients.
  * @param sender - Address of the sender
  * @param token - Address of the ERC1155 token contract
  * @param tokenIds - List of ERC1155 token IDs that were sent
  * @param amounts - List of ERC1155 token amounts that were sent
  * @param recipients - List of recipient addresses
  * @param fee - The fee paid for the transaction
  */
  event ERC1155TokensSent(
    address indexed sender,
    address indexed token,
    uint256[] tokenIds,
    uint256[] amounts,
    address[] recipients,
    uint256 fee
  );

  /**
   * @dev Emitted when a batch of ERC1155 tokens is sent to multiple recipients.
   * @param sender The address that initiated the sending of the tokens.
   * @param token The address of the ERC1155 token contract.
   * @param tokenIds The list of ERC1155 token IDs that were sent.
   * @param amounts The list of ERC1155 token amounts that were sent.
   * @param recipients The list of recipient addresses that received the tokens.
   * @param fee - The fee paid for the transaction
   */
  event ERC1155TokensBatchSent(
    address indexed sender,
    address indexed token,
    uint256[][] tokenIds,
    uint256[][] amounts,
    address[] recipients,
    uint256 fee
  );

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function initialize(address _owner, uint256 _minFee) public initializer {
    require(_owner != address(0), 'Owner address is not set');

    __Ownable_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();

    transferOwnership(_owner);

    bank = _owner;
    minFee = _minFee;
  }

  /**
   * @dev Modifier to check that an array is not empty.
   * @param array The array to check.
   */
  modifier nonEmpty(address[] memory array) {
    require(array.length > 0, "Array cannot be empty");
    _;
  }

  /**
   * @notice Changes the minFee amount for sending tokens.
   * @param _minFee - new minFee amount
   */
  function changeMinFee(uint256 _minFee) public onlyOwner {
    minFee = _minFee;
  }

  /**
   * @notice Changes the address of the bank where the fees are sent to.
   * @param _bank - new bank address
   */
  function changeBankAddress(address _bank) public onlyOwner {
    require(_bank != address(0), "Bank not zero");
    bank = _bank;
  }

  /**
  * @notice This function sends ERC721 or ERC1155 tokens to multiple recipients.
  * @param _assetContract - ERC721 or ERC1155 token contract address
  * @param _tokenIds - List of ERC721 or ERC1155 token IDs to be sent
  * @param _recipients - List of recipient addresses
  * @param _quantity - Quantity of tokens to be sent
  * @param _fee - Fee for the transaction
  */
  function sendTokens(
    address _assetContract,
    uint256[] memory _tokenIds,
    address[] memory _recipients,
    uint256[] memory _quantity,
    uint256 _fee
  ) public payable nonReentrant nonEmpty(_recipients) {
    require(_tokenIds.length == _recipients.length, "TokenIds and recipients array lengths must be equal");

    _processFee(_fee);

    TokenType tokenType = getTokenType(_assetContract);

    for (uint256 i = 0; i < _recipients.length; i++) {
      _sendNft(
        tokenType,
        _assetContract,
        _tokenIds[i],
        _quantity[i],
        _msgSender(),
        _recipients[i]
      );
    }

    if (tokenType == TokenType.ERC1155) {
        emit ERC1155TokensSent(_msgSender(), _assetContract, _tokenIds, _quantity, _recipients, _fee);
    } else {
        emit ERC721TokensSent(_msgSender(), _assetContract, _tokenIds, _recipients, _fee);
    }
  }

  /**
  * @notice This function sends batches of ERC1155 tokens to multiple recipients.
  * @param _recipients - List of recipient addresses
  * @param _tokenIds - List of lists of ERC1155 token IDs to be sent
  * @param _amounts - List of lists of ERC1155 token amounts to be sent
  * @param _token - ERC1155 token contract address
  * @param _fee - Fee for the transaction
  */
  function sendBatchERC1155(
    address[] memory _recipients,
    uint256[][] memory _tokenIds,
    uint256[][] memory _amounts,
    address _token,
    uint256 _fee
  ) external payable nonReentrant nonEmpty(_recipients) {

    uint256 recipientsLength = _recipients.length;
    require(
      recipientsLength == _amounts.length && recipientsLength == _tokenIds.length,
      "Input arrays must have the same length"
    );

    _processFee(_fee);

    for (uint256 i = 0; i < recipientsLength; i++) {
      require(_tokenIds[i].length > 0, "Empty batch");
      for (uint256 j = 0; j < _tokenIds[i].length; j++) {
        _sendNft(
          TokenType.ERC1155,
          _token,
          _tokenIds[i][j],
          _amounts[i][j],
          _msgSender(),
          _recipients[i]
        );
      }
    }

    emit ERC1155TokensBatchSent(_msgSender(), _token, _tokenIds, _amounts, _recipients, _fee);
  }


  function claim(uint256[] calldata _transferIds, uint256 _fee) external payable nonReentrant {
    require(_transferIds.length > 0, "Empty transfer ids");
    _processFee(_fee);
    _processTransfer(_transferIds, false);
  }

  function cancelTransfer(uint256[] calldata _transferIds) external nonReentrant {
    require(_transferIds.length > 0, "Empty transfer ids");
    _processTransfer(_transferIds, true);
  }

  function _processTransfer(uint256[] calldata _transferIds, bool isCancel) internal {
    NftTransfer memory nftTransfer;

    for(uint i = 0; i < _transferIds.length; i++) {
      nftTransfer = transfers[_transferIds[i]];

      require(senderTransfers[nftTransfer.sender].contains(_transferIds[i]) &&
        recipientTransfers[nftTransfer.recipient].contains(_transferIds[i]),
        "The requestor did not initiate this transfer"
      );

      require(!nftTransfer.claimed, "Already claimed");
      require(
        (isCancel && nftTransfer.sender == _msgSender()) ||
        (!isCancel && nftTransfer.recipient == _msgSender()),
        "Permission denied"
      );

      transfers[_transferIds[i]].claimed = true;

      address transferTo = isCancel ? nftTransfer.sender : nftTransfer.recipient;

      transferTokens(
        address(this),
        transferTo,
        nftTransfer
      );

      _removeTransferId(nftTransfer.sender, nftTransfer.recipient, nftTransfer.transferId);
    }
  }

  function _sendNft(
    TokenType _tokenType,
    address _assetContract,
    uint256 _tokenId,
    uint256 _quantity,
    address _sender,
    address _recipient
  ) internal {

    validateOwnershipAndApproval(
      _sender,
      _assetContract,
      _tokenId,
      _quantity,
      _tokenType
    );

    uint256 _transferId = transferIdCounter.current();

    transfers[_transferId] = NftTransfer({
      transferId: _transferId,
      tokenType: _tokenType,
      assetContract: _assetContract,
      tokenId: _tokenId,
      quantity: _quantity,
      sender: _sender,
      recipient: _recipient,
      claimed: false
    });

    transferTokens(_sender, address(this), transfers[_transferId]);

    _addTransferId(_sender, _recipient, _transferId);
    transferIdCounter.increment();
  }

  function transferTokens(
    address _from,
    address _to,
    NftTransfer memory _transfer
  ) internal {
    if (_transfer.tokenType == TokenType.ERC1155) {
      IERC1155Upgradeable(_transfer.assetContract).safeTransferFrom(_from, _to, _transfer.tokenId, _transfer.quantity, "");
    } else if (_transfer.tokenType == TokenType.ERC721) {
      IERC721Upgradeable(_transfer.assetContract).safeTransferFrom(_from, _to, _transfer.tokenId, "");
    }
  }

  /// @dev Returns the interface supported by a contract.
  function getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
    if (IERC165Upgradeable(_assetContract).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {
      tokenType = TokenType.ERC1155;
    } else if (IERC165Upgradeable(_assetContract).supportsInterface(type(IERC721Upgradeable).interfaceId)) {
      tokenType = TokenType.ERC721;
    } else {
      revert("token must be ERC1155 or ERC721.");
    }
  }

  function validateOwnershipAndApproval(
    address _tokenOwner,
    address _assetContract,
    uint256 _tokenId,
    uint256 _quantity,
    TokenType _tokenType
  ) internal view {
    address market = address(this);
    bool isValid;

    if (_tokenType == TokenType.ERC1155) {
      isValid =
        IERC1155Upgradeable(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity &&
        IERC1155Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, market);
    } else if (_tokenType == TokenType.ERC721) {
      isValid =
        IERC721Upgradeable(_assetContract).ownerOf(_tokenId) == _tokenOwner &&
        (IERC721Upgradeable(_assetContract).getApproved(_tokenId) == market ||
        IERC721Upgradeable(_assetContract).isApprovedForAll(_tokenOwner, market));
    }

    require(isValid, "!BALNFT");
  }

  // Add a transferId to a sender and a recipient
  function _addTransferId(address _sender, address _recipient, uint256 _transferId) private {
    senderTransfers[_sender].add(_transferId);
    recipientTransfers[_recipient].add(_transferId);
  }

  // Remove a transferId from a sender and a recipient
  function _removeTransferId(address _sender, address _recipient, uint256 _transferId) private {
    senderTransfers[_sender].remove(_transferId);
    recipientTransfers[_recipient].remove(_transferId);
  }

  /**
  @notice Returns any excess ether sent to the contract back to the sender.
  @dev If the amount sent is greater than the total fee, the difference is returned to the sender.
  @param _fee - the total fee amount paid by the sender
  */
  function _processFee(uint256 _fee) private {
    require(msg.value >= _fee && _fee >= minFee, "Insufficient fee amount");

    if (_fee > 0) {
      payable(bank).transfer(_fee);
    }

    uint256 excess = msg.value.sub(_fee);
    if (excess > 0) {
      payable(_msgSender()).transfer(excess);
    }
  }

  function getTransfer(uint256 _transferId) public view returns (NftTransfer memory) {
    return transfers[_transferId];
  }

  function getSenderTransfers(address _sender) public view returns (NftTransfer[] memory) {
    return _getTransfers(senderTransfers[_sender]);
  }

  function getRecipientTransfers(address _recipient) public view returns (NftTransfer[] memory) {
    return _getTransfers(recipientTransfers[_recipient]);
  }

  function _getTransfers(EnumerableSetUpgradeable.UintSet storage set) private view returns (NftTransfer[] memory) {
    NftTransfer[] memory result = new NftTransfer[](set.length());

    for (uint256 i = 0; i < set.length(); i++) {
        result[i] = transfers[set.at(i)];
    }

    return result;
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

  /**
  * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC1155ReceiverUpgradeable, AccessControlEnumerableUpgradeable)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint256[99] private __gap;

}