/******************************************************************************************************
Yieldification NFT Marketplace

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IERC721Royalty.sol';
import './interfaces/IWETH.sol';

contract NFTMarketplace is Ownable {
  using SafeERC20 for IERC20;

  uint256 constant DENOMENATOR = 10000;

  bool public marketplaceEnabled = true;
  address public treasury;
  IWETH public weth;
  uint256 public addOfferFee = 1 ether / 1000; // 0.001 ETH
  uint256 public serviceFeePercent = (DENOMENATOR * 1) / 100; // 1%

  // ERC20 token => amount volume
  mapping(address => uint256) public totalVolume;
  // ERC20 token => whether it's valid
  mapping(address => bool) public validOfferERC20;
  address[] _validOfferTokens;
  mapping(address => uint256) _validOfferTokensIdx;

  struct BuyItNowConfig {
    address creator;
    address nftContract;
    uint256 tokenId;
    address erc20;
    uint256 amount;
  }
  mapping(bytes32 => BuyItNowConfig) _buyItNowConfigs;

  struct Offer {
    address owner; // person who created offer
    address nftContract;
    uint256 tokenId;
    address offerERC20;
    uint256 amount;
    uint256 timestamp;
    uint256 expiration;
  }
  // NFT ID => Offer
  mapping(bytes32 => Offer[]) _offers;

  event AddBuyItNowConfig(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    address buyItNowToken,
    uint256 buyItNowAmount
  );
  event RemoveBuyItNowConfig(
    address indexed owner,
    address nftContract,
    uint256 tokenId
  );
  event AddOffer(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    address offerToken,
    uint256 offerAmount
  );
  event RemoveOffer(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    uint256 offerIdx
  );
  event EditOffer(
    address indexed owner,
    address nftContract,
    uint256 tokenId,
    uint256 offerIdx,
    uint256 offerAmount,
    uint256 expiration
  );
  event ProcessTransaction(
    address indexed nftContract,
    uint256 tokenId,
    address oldOwner,
    address newOwner,
    address paymentToken,
    uint256 price
  );

  constructor(IWETH _weth) {
    weth = _weth;
  }

  function getAllNFTOffers(address _nftContract, uint256 _tokenId)
    public
    view
    returns (Offer[] memory)
  {
    return _offers[_getUniqueNFTID(_nftContract, _tokenId)];
  }

  function getAllOffersMultiple(
    address _nftContract,
    uint256[] memory _tokenIds
  ) external view returns (Offer[][] memory) {
    Offer[][] memory _allOffers;
    for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
      _allOffers[_i] = getAllNFTOffers(_nftContract, _tokenIds[_i]);
    }
    return _allOffers;
  }

  function getAllValidOfferTokens() external view returns (address[] memory) {
    return _validOfferTokens;
  }

  function getBuyItNowConfig(address _nftContract, uint256 _tokenId)
    external
    view
    returns (BuyItNowConfig memory)
  {
    return _buyItNowConfigs[_getUniqueNFTID(_nftContract, _tokenId)];
  }

  function addBuyItNowConfig(
    address _nftContract,
    uint256 _tokenId,
    address _buyItNowToken,
    uint256 _buyItNowAmount
  ) external {
    require(
      _buyItNowToken == address(0) || validOfferERC20[_buyItNowToken],
      'invalid buy it now token'
    );

    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_nft.ownerOf(_tokenId) == msg.sender, 'must be NFT owner');
    _buyItNowConfigs[_getUniqueNFTID(_nftContract, _tokenId)] = BuyItNowConfig({
      creator: msg.sender,
      nftContract: _nftContract,
      tokenId: _tokenId,
      erc20: _buyItNowToken,
      amount: _buyItNowAmount
    });

    emit AddBuyItNowConfig(
      msg.sender,
      _nftContract,
      _tokenId,
      _buyItNowToken,
      _buyItNowAmount
    );
  }

  function removeBuyItNowConfig(address _nftContract, uint256 _tokenId)
    external
  {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_nft.ownerOf(_tokenId) == msg.sender, 'must be NFT owner');
    delete _buyItNowConfigs[_getUniqueNFTID(_nftContract, _tokenId)];

    emit RemoveBuyItNowConfig(msg.sender, _nftContract, _tokenId);
  }

  function buyItNow(
    address _nftContract,
    uint256 _tokenId,
    address _buyItNowToken,
    uint256 _buyItNowAmount
  ) external payable {
    require(marketplaceEnabled, 'not enabled');

    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    BuyItNowConfig memory _binConf = _buyItNowConfigs[_nftId];
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_binConf.creator == _nft.ownerOf(_tokenId), 'BIN1: bad owner');
    require(_binConf.erc20 == _buyItNowToken, 'BIN2: bad token');
    require(_binConf.amount == _buyItNowAmount, 'BIN3: bad amount');

    (address _royaltyAddress, uint256 _royaltyAmount) = _getRoyaltyInfo(
      _nftContract,
      _binConf.amount
    );
    _processPayment(
      _binConf.erc20,
      _binConf.amount,
      msg.sender,
      _binConf.creator,
      _royaltyAddress,
      _royaltyAmount
    );
    _transferNFT(_nftContract, _tokenId, _binConf.creator, msg.sender);

    emit ProcessTransaction(
      _nftContract,
      _tokenId,
      _binConf.creator,
      msg.sender,
      _binConf.erc20,
      _binConf.amount
    );
  }

  function acceptOffer(
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx,
    address _offerToken,
    uint256 _offerAmount
  ) external {
    require(marketplaceEnabled, 'not enabled');

    Offer memory _offer = _offers[_getUniqueNFTID(_nftContract, _tokenId)][
      _offerIdx
    ];
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(msg.sender == _nft.ownerOf(_tokenId), 'ACCOFF1: must be owner');
    require(_offer.offerERC20 == _offerToken, 'ACCOFF2: bad token');
    require(_offer.amount == _offerAmount, 'ACCOFF3: bad amount');
    require(
      _offer.expiration == 0 || _offer.expiration > block.timestamp,
      'ACCOFF4: expired'
    );

    (address _royaltyAddress, uint256 _royaltyAmount) = _getRoyaltyInfo(
      _nftContract,
      _offer.amount
    );
    _processPayment(
      _offer.offerERC20,
      _offer.amount,
      _offer.owner,
      msg.sender,
      _royaltyAddress,
      _royaltyAmount
    );
    _transferNFT(_nftContract, _tokenId, msg.sender, _offer.owner);
    _removeOffer(_offer.owner, _nftContract, _tokenId, _offerIdx);

    emit ProcessTransaction(
      _nftContract,
      _tokenId,
      msg.sender,
      _offer.owner,
      _offer.offerERC20,
      _offer.amount
    );
  }

  function addOffer(
    address _nftContract,
    uint256 _tokenId,
    address _offerToken,
    uint256 _offerAmount,
    uint256 expiration
  ) external payable {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    address _finalOfferToken;
    uint256 _finalOfferAmount;

    require(_nft.ownerOf(_tokenId) != msg.sender, 'ADDOFF1: not owner');

    if (_offerToken == address(0)) {
      require(msg.value > addOfferFee, 'ADDOFF2: need ETH');
      require(validOfferERC20[address(weth)], 'ADDOFF3: WETH not valid');

      uint256 _ethOfferAmount = msg.value - addOfferFee;
      IERC20 _wethIERC20 = IERC20(address(weth));
      uint256 _wethBalBefore = _wethIERC20.balanceOf(address(this));
      weth.deposit{ value: _ethOfferAmount }();
      _wethIERC20.transfer(
        msg.sender,
        _wethIERC20.balanceOf(address(this)) - _wethBalBefore
      );

      _finalOfferToken = address(weth);
      _finalOfferAmount = (_ethOfferAmount * 10**weth.decimals()) / 10**18;
    } else {
      require(msg.value == addOfferFee, 'ADDOFF4: offer fee');
      require(validOfferERC20[_offerToken], 'ADDOFF5: invalid offer token');
      _finalOfferToken = _offerToken;
      _finalOfferAmount = _offerAmount;
    }

    if (addOfferFee > 0) {
      (bool _success, ) = payable(_getTreasury()).call{ value: addOfferFee }(
        ''
      );
      require(_success, 'ADDOFF6: add offer fee');
    }

    IERC20 _offTokenCont = IERC20(_finalOfferToken);
    require(
      _offTokenCont.balanceOf(msg.sender) >= _finalOfferAmount,
      'ADDOFF7: bad balance'
    );
    require(
      _offTokenCont.allowance(msg.sender, address(this)) >= _finalOfferAmount,
      'ADDOFF8: need allowance'
    );
    require(expiration == 0 || expiration > block.timestamp, 'bad expiration');

    _offers[_getUniqueNFTID(_nftContract, _tokenId)].push(
      Offer({
        owner: msg.sender,
        nftContract: _nftContract,
        tokenId: _tokenId,
        offerERC20: _finalOfferToken,
        amount: _finalOfferAmount,
        timestamp: block.timestamp,
        expiration: expiration
      })
    );
    emit AddOffer(
      msg.sender,
      _nftContract,
      _tokenId,
      _finalOfferToken,
      _finalOfferAmount
    );
  }

  function editOffer(
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx,
    uint256 _offerAmount,
    uint256 _expiration
  ) external {
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    Offer storage _offer = _offers[_nftId][_offerIdx];
    require(_offer.owner == msg.sender, 'must own offer to edit');

    if (_offerAmount > 0) {
      _offer.amount = _offerAmount;
    }
    if (_expiration > 0) {
      _offer.expiration = _expiration;
    }

    emit EditOffer(
      _offer.owner,
      _nftContract,
      _tokenId,
      _offerIdx,
      _offerAmount,
      _expiration
    );
  }

  function removeOffer(
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx
  ) external {
    _removeOffer(msg.sender, _nftContract, _tokenId, _offerIdx);
  }

  function _removeOffer(
    address _caller,
    address _nftContract,
    uint256 _tokenId,
    uint256 _offerIdx
  ) internal {
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    Offer memory _offer = _offers[_nftId][_offerIdx];
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_offer.owner != address(0), 'offer does not exist');
    require(
      _caller == _offer.owner || _caller == _nft.ownerOf(_tokenId),
      'must be offer or NFT owner to remove'
    );
    _offers[_nftId][_offerIdx] = _offers[_nftId][_offers[_nftId].length - 1];
    _offers[_nftId].pop();

    emit RemoveOffer(_offer.owner, _nftContract, _tokenId, _offerIdx);
  }

  function _getUniqueNFTID(address _nftContract, uint256 _tokenId)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_nftContract, _tokenId));
  }

  function _processPayment(
    address _paymentToken,
    uint256 _amount,
    address _payor,
    address _receiver,
    address _royaltyReceiver,
    uint256 _royaltyAmount
  ) internal {
    uint256 _amountAfterRoyalty = _amount;
    if (_royaltyReceiver != address(0)) {
      _amountAfterRoyalty -= _royaltyAmount;
    }
    uint256 _treasuryAmount = (_amountAfterRoyalty * serviceFeePercent) /
      DENOMENATOR;
    uint256 _receiverAmount = _amountAfterRoyalty - _treasuryAmount;
    if (_paymentToken == address(0)) {
      require(msg.value >= _amount, 'not enough ETH to pay for NFT');
      uint256 _before = address(this).balance;
      // process royalty payment
      if (_royaltyAmount > 0) {
        (bool _royaltySuccess, ) = payable(_royaltyReceiver).call{
          value: _royaltyAmount
        }('');
        require(_royaltySuccess, 'royalty payment was not processed');
      }
      // process treasury payment
      if (_treasuryAmount > 0) {
        (bool _treasSuccess, ) = payable(_getTreasury()).call{
          value: _treasuryAmount
        }('');
        require(_treasSuccess, 'treasury payment was not processed');
      }
      (bool _success, ) = payable(_receiver).call{ value: _receiverAmount }('');
      require(_success, 'main payment was not processed');
      require(address(this).balance >= _before - _amount);
    } else {
      IERC20 _paymentTokenCont = IERC20(_paymentToken);
      // process royalty payment
      if (_royaltyAmount > 0) {
        _paymentTokenCont.safeTransferFrom(
          _payor,
          _royaltyReceiver,
          _royaltyAmount
        );
      }
      if (_treasuryAmount > 0) {
        _paymentTokenCont.safeTransferFrom(
          _payor,
          _getTreasury(),
          _treasuryAmount
        );
      }
      _paymentTokenCont.safeTransferFrom(_payor, _receiver, _receiverAmount);
    }
    totalVolume[_paymentToken] += _amount;
  }

  function _transferNFT(
    address _nftContract,
    uint256 _tokenId,
    address _oldOwner,
    address _newOwner
  ) internal {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    require(_nft.ownerOf(_tokenId) == _oldOwner, 'current owner invalid');
    _nft.safeTransferFrom(_oldOwner, _newOwner, _tokenId);

    // clean up any existing buy it now config
    bytes32 _nftId = _getUniqueNFTID(_nftContract, _tokenId);
    delete _buyItNowConfigs[_nftId];
  }

  function _getRoyaltyInfo(address _nftContract, uint256 _saleAmount)
    internal
    view
    returns (address, uint256)
  {
    IERC721Royalty _nft = IERC721Royalty(_nftContract);
    try _nft.royaltyInfo(0, _saleAmount) returns (
      address _royaltyAddress,
      uint256 _royaltyAmount
    ) {
      return (_royaltyAddress, _royaltyAmount);
    } catch {
      return (address(0), 0);
    }
  }

  function _getTreasury() internal view returns (address) {
    return treasury == address(0) ? owner() : treasury;
  }

  function updateValidOfferToken(address _token, bool _isValid)
    external
    onlyOwner
  {
    require(validOfferERC20[_token] != _isValid, 'must toggle');
    validOfferERC20[_token] = _isValid;
    if (_isValid) {
      _validOfferTokensIdx[_token] = _validOfferTokens.length;
      _validOfferTokens.push(_token);
    } else {
      uint256 _idx = _validOfferTokensIdx[_token];
      delete _validOfferTokensIdx[_token];
      _validOfferTokens[_idx] = _validOfferTokens[_validOfferTokens.length - 1];
      _validOfferTokens.pop();
    }
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setServiceFeePercent(uint256 _percent) external onlyOwner {
    require(_percent <= (DENOMENATOR * 10) / 100, 'must be <= 10%');
    serviceFeePercent = _percent;
  }

  function setAddOfferFee(uint256 _wei) external onlyOwner {
    addOfferFee = _wei;
  }

  function setWETH(IWETH _weth) external onlyOwner {
    weth = _weth;
  }

  function setMarketplaceEnabled(bool _isEnabled) external onlyOwner {
    require(marketplaceEnabled != _isEnabled, 'must toggle enabled');
    marketplaceEnabled = _isEnabled;
  }

  function withdrawERC20(address _tokenAddress, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _contract = IERC20(_tokenAddress);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.safeTransfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}