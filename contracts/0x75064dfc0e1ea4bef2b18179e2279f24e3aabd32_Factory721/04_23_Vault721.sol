// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '../wraps/Wrap721.sol';
import {IMarket, IMarketOwner} from '../interfaces/IMarket.sol';
import {IWrap721} from '../interfaces/IWrap.sol';
import '../libraries/RentaFiSVG.sol';

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

//ERROR FUNCTIONS
error MustBeSameLength();
error InvalidTokens();

contract Vault721 is ERC721, Pausable {
  address public wrapContract;
  address public originalCollection;
  address public marketContract;
  address public collectionOwner;
  uint256 public minDuration;
  uint256 public maxDuration;
  uint256 public collectionOwnerFeeRatio;
  string public originalName;
  string public originalSymbol;
  mapping(uint256 => uint256) private tokenIdAllowed;
  mapping(address => uint256) public minPrices;
  address[] public paymentTokens;
  uint256 public allTokenIdAllowed;
  address public payoutAddress;

  constructor(
    string memory _name,
    string memory _symbol,
    address _collection,
    address _collectionOwner,
    address _marketContract,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _collectionOwnerFeeRatio,
    uint256[] memory _minPrices,
    address[] memory _paymentTokens,
    uint256[] memory _allowedTokenIds
  )
    ERC721(
      string(abi.encodePacked('RentaFi Ownership NFT ', _name)),
      string(abi.encodePacked('RentaFi-ON-', _symbol))
    )
  {
    marketContract = _marketContract;
    originalCollection = _collection;
    collectionOwner = _collectionOwner; // Who deploys this Vault contract from Factory contract
    originalName = _name;
    originalSymbol = _symbol;
    payoutAddress = _collectionOwner;

    _setDuration(_minDuration, _maxDuration);
    _setCollectionOwnerFeeRatio(_collectionOwnerFeeRatio);
    _setMinPrices(_minPrices, _paymentTokens);

    if (_allowedTokenIds.length > 0) {
      unchecked {
        for (uint256 i = 0; i < _allowedTokenIds.length; i++) {
          tokenIdAllowed[_allowedTokenIds[i]] = 1;
        }
      }
    } else {
      allTokenIdAllowed = 1;
    }

    _deployWrap();
  }

  /**************
   *  MODIFIER  *
   **************/
  modifier onlyProtocolAdmin() {
    require(IMarketOwner(marketContract).owner() == msg.sender, 'onlyProtocolAdmin');
    _;
  }

  modifier onlyCollectionOwner() {
    require(msg.sender == collectionOwner, 'onlyCollectionOwner');
    _;
  }

  modifier onlyMarket() {
    require(msg.sender == marketContract, 'onlyMarket');
    _;
  }

  modifier onlyONftOwner(uint256 _lockId) {
    require(ownerOf(_lockId) == msg.sender, 'onlyONftOwner');
    _;
  }

  /**********************
   * EXTERNAL FUNCTIONS *
   **********************/
  function redeem(uint256 _lockId) external virtual onlyMarket whenNotPaused {
    _redeem(_lockId);
  }

  function mintONft(uint256 _lockId) external onlyMarket whenNotPaused {
    address _lender = IMarket(marketContract).getLendRent(_lockId).lend.lender;
    _mint(_lender, _lockId);
  }

  function mintWNft(
    address _renter,
    uint256 _starts,
    uint256 _expires,
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount
  ) public virtual onlyMarket {
    _expires;
    _amount;
    // If it starts later, only book and return.
    if (_starts > block.timestamp) return;
    _mintWNft(_renter, _lockId, _tokenId, _amount);
  }

  function activate(
    uint256 _rentId,
    uint256 _lockId,
    address _renter,
    uint256 _amount
  ) external virtual onlyMarket whenNotPaused {
    _amount;
    uint256 _now = block.timestamp;
    IMarket.Rent[] memory _rents = IMarket(marketContract).getLendRent(_lockId).rent;
    IMarket.Rent memory _rent;
    unchecked {
      for (uint256 i = 0; i < _rents.length; i++) {
        if (_rents[i].rentId == _rentId) {
          _rent = _rents[i];
          break;
        }
      }
    }
    require(_rent.rentId == _rentId, 'RentNotFound');
    require(_rent.renterAddress == _renter, 'onlyRenter');
    require(_rent.rentalStartTime < _now && _rent.rentalExpireTime > _now, 'OutsideTheTerm');
    _mintWNft(_renter, _lockId, IMarket(marketContract).getLendRent(_lockId).lend.tokenId, _amount);
  }

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  ) external pure returns (bytes4) {
    _operator;
    _from;
    _tokenId;
    _data;
    return 0x150b7a02;
  }

  /** GETTER FUNCTIONS */
  function getPaymentTokens() external view returns (address[] memory) {
    return paymentTokens;
  }

  function getTokenIdAllowed(uint256 _tokenId) external view returns (uint256) {
    if (allTokenIdAllowed > 0) return 1;
    return tokenIdAllowed[_tokenId];
  }

  function tokenURI(uint256 _lockId) public view override returns (string memory) {
    require(_exists(_lockId), 'ERC721Metadata: URI query for nonexistent token');

    // CHANGE STATE
    IMarket.Lend memory _lend = IMarket(marketContract).getLendRent(_lockId).lend;
    bytes memory json = RentaFiSVG.getOwnershipSVG(
      _lockId,
      _lend.tokenId,
      _lend.amount,
      _lend.lockStartTime,
      _lend.lockExpireTime,
      originalCollection,
      IERC721Metadata(originalCollection).name()
    );
    string memory _tokenURI = string(
      abi.encodePacked('data:application/json;base64,', Base64.encode(json))
    );

    return _tokenURI;
  }

  /** TX FUNCTIONS */
  function transferCollectionOwner(address _newOwner) external onlyCollectionOwner {
    collectionOwner = _newOwner;
  }

  function emergencyWithdraw(uint256 _lockId) external whenPaused onlyONftOwner(_lockId) {
    _redeem(_lockId);
  }

  /** SETTER FUNCTIONS */
  function setPayoutAddress(address _newAddress) external onlyCollectionOwner {
    payoutAddress = _newAddress;
  }

  function setTokenIdAllowed(uint256[] calldata _tokenIds, uint256[] calldata _allowed)
    external
    onlyCollectionOwner
  {
    if (_tokenIds.length != _allowed.length) revert MustBeSameLength();
    uint256 _allowedLength = _allowed.length;
    unchecked {
      for (uint256 i = 0; i < _allowedLength; i++) {
        if (_allowed[i] > 0) {
          tokenIdAllowed[_tokenIds[i]] = 1;
        } else {
          // Deleting a non-existent key does not result in an error.
          delete tokenIdAllowed[_tokenIds[i]];
        }
      }
    }
    allTokenIdAllowed = 0;
  }

  function setAllTokenIdAllowed(uint256 _bool) external onlyCollectionOwner {
    allTokenIdAllowed = _bool;
  }

  function setMinPrices(uint256[] memory _minPrices, address[] memory _paymentTokens)
    external
    onlyCollectionOwner
  {
    _setMinPrices(_minPrices, _paymentTokens);
  }

  function setCollectionOwnerFeeRatio(uint256 _collectionOwnerFeeRatio)
    external
    onlyCollectionOwner
  {
    _setCollectionOwnerFeeRatio(_collectionOwnerFeeRatio);
  }

  function setDuration(uint256 _minDuration, uint256 _maxDuration) external onlyCollectionOwner {
    _setDuration(_minDuration, _maxDuration);
  }

  /** PROTOCOL ADMIN FUNCTIONS */
  function pause() external onlyProtocolAdmin {
    paused() ? _unpause() : _pause();
  }

  /*********************
   * PRIVATE FUNCTIONS *
   *********************/
  function _setCollectionOwnerFeeRatio(uint256 _collectionOwnerFeeRatio) private {
    require(_collectionOwnerFeeRatio <= 90 * 1000, 'FeeRatio>90%');
    collectionOwnerFeeRatio = _collectionOwnerFeeRatio;
  }

  function _setDuration(uint256 _minDuration, uint256 _maxDuration) private {
    require(minDuration <= maxDuration, 'minDur>maxDur');
    minDuration = _minDuration;
    maxDuration = _maxDuration;
  }

  // priceが0は非許可を意味する
  function _setMinPrices(uint256[] memory _minPrices, address[] memory _paymentTokens) private {
    require(_minPrices.length > 0, 'EmptyNotAllowed');
    if (_minPrices.length != _paymentTokens.length) revert MustBeSameLength();
    uint256 _paymentTokensLength = _paymentTokens.length;
    unchecked {
      for (uint256 i = 0; i < _paymentTokensLength; i++) {
        if (IMarket(marketContract).paymentTokenWhiteList(_paymentTokens[i]) >= 1) {
          minPrices[_paymentTokens[i]] = _minPrices[i];
        } else revert InvalidTokens(); // 配列の中に1つでもinvalidなトークンが含まれていたらrevertする
      }
    }
    paymentTokens = _paymentTokens;
  }

  /**********************
   * INTERNAL FUNCTIONS *
   **********************/
  function _deployWrap() internal virtual {
    wrapContract = address(
      new Wrap721(
        string(abi.encodePacked('Wrapped ', IERC721Metadata(originalCollection).name())),
        string(abi.encodePacked('W', IERC721Metadata(originalCollection).symbol())),
        marketContract
      )
    );
  }

  function _redeem(uint256 _lockId) internal virtual {
    IMarket.Lend memory _lend = IMarket(marketContract).getLendRent(_lockId).lend;
    // Send tokens back from Vault contract to the user's wallet
    IERC721(originalCollection).transferFrom(address(this), ownerOf(_lockId), _lend.tokenId);
    _burn(_lockId);
  }

  function _mintWNft(
    address _renter,
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount
  ) internal virtual {
    _amount;
    IWrap721(wrapContract).emitTransfer(address(this), _renter, _tokenId, _lockId);
  }
}