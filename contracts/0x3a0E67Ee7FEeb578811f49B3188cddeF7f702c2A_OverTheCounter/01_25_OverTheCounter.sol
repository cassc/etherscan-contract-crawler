// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IFeeReducer.sol';
import './interfaces/IWETH.sol';
import './otcYDF.sol';

contract OverTheCounter is IERC721Receiver, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 private constant PERC_DEN = 100000;

  enum AssetType {
    ERC20,
    ERC721,
    ERC1155
  }

  bool public enabled = true;
  uint32 public maxAssetsPerPackage = 10;
  uint256 public createServiceFeeETH = 1 ether / 100; // 0.01 ETH
  uint256 public poolAddFeePerc = (PERC_DEN * 1) / 100; // 1%
  uint256 public buyPackageFeePerc = (PERC_DEN * 1) / 100; // 1%
  uint256 public addOfferFee = 1 ether / 1000; // 0.001 ETH
  address public treasury;
  IFeeReducer public feeReducer;
  IWETH public weth;
  otcYDF public otcNFT;

  // ERC20 token => amount volume
  mapping(address => uint256) public totalVolume;
  // ERC20 token => whether it's valid
  mapping(address => bool) public validOfferERC20;
  address[] _validOfferTokens;
  mapping(address => uint256) _validOfferTokensIdx;

  struct OTC {
    address creator;
    bool isPool;
    Package package;
    Pool pool;
  }

  struct Asset {
    address assetContract; // address(0) means native
    AssetType assetType;
    uint256 amount; // ERC20 or native
    uint256 id; // For ERC721 will be tokenId, for ERC1155 will be asset ID
  }

  struct Package {
    Asset[] assets;
    uint256 creationTime;
    uint256 unlockStart; // if > 0, specified when ERC20/native begins vesting and can begin being withdrawn
    uint256 unlockEnd; // if > 0, ERC20/native will support continuous vesting until this date
    uint256 lastWithdraw;
    // NOTE: if buyItNowAmount > 0, the package can be
    // bought immediately if another user offers this asset/amount combo.
    // Make sure it's an appropriate amount.
    address buyItNowAsset;
    uint256 buyItNowAmount;
    address buyItNowWhitelist; // if present, is the only address that can buy this package instantly
  }

  struct PkgOffer {
    address owner;
    address assetContract; // address(0) == ETH/native
    uint256 amount;
    uint256 timestamp;
    uint256 expiration;
  }

  // One-way OTC ERC20 pool where a creator can deposit token0 and users can
  // purchase token0 at price18 specified by creator w/ no slippage.
  // Users can only purchase token0 by sending token1 and will receive
  // token0 based on price18 provided
  struct Pool {
    address token0; // ERC20
    address token1; // ERC20
    uint256 amount0Deposited;
    uint256 amount0Remaining;
    uint256 amount1Deposited;
    uint256 price18; // amount1 * 10**18 / amount0
  }

  // tokenId => OTC
  mapping(uint256 => OTC) public otcs;
  // tokenId[]
  uint256[] public allOTCs;
  // tokenId => allOTCs index
  mapping(uint256 => uint256) internal _otcsIndexed;
  // tokenId => PkgOffer[]
  mapping(uint256 => PkgOffer[]) public pkgOffers;
  // address => sourceTokenId => targetTokenId
  mapping(address => mapping(uint256 => uint256)) public userOtcTradeWhitelist;

  event CreatePool(
    uint256 indexed tokenId,
    address indexed user,
    address token0,
    address token1,
    uint256 amount0,
    uint256 amount0LessFee,
    uint256 price18
  );
  event UpdatePool(
    uint256 indexed tokenId,
    address indexed owner,
    uint256 newPrice18,
    uint256 amount0Adding,
    bool withdrawToken1
  );
  event RemovePool(uint256 indexed tokenId, address indexed owner);
  event SwapPool(
    uint256 indexed tokenId,
    address indexed swapper,
    address token0,
    uint256 token0Amount,
    address token1,
    uint256 token1Amount
  );
  event CreatePackage(
    uint256 indexed tokenId,
    address indexed user,
    uint256 numberAssets
  );
  event WithdrawFromPackage(uint256 indexed tokenId, address indexed user);
  event AddPackageOffer(
    uint256 indexed tokenId,
    address indexed offerer,
    address offerAsset,
    uint256 offerAmount
  );
  event AcceptPackageOffer(
    uint256 indexed tokenId,
    address indexed pkgOwner,
    uint256 numAssetsInOffer
  );
  event RemovePackageOffer(
    uint256 indexed tokenId,
    address indexed pkgOwner,
    uint256 offerIndex
  );
  event BuyItNow(
    uint256 indexed tokenId,
    address indexed pkgOwner,
    address buyer,
    address buyToken,
    uint256 amount
  );
  event Trade(
    address indexed user1,
    address indexed user2,
    uint256 user1TokenIdSent,
    uint256 user2TokenIdSent
  );

  modifier onlyNFT() {
    require(msg.sender == address(otcNFT), 'ONLYNFT');
    _;
  }

  constructor(IWETH _weth, string memory _baseTokenURI) {
    weth = _weth;
    otcNFT = new otcYDF(_baseTokenURI);
    otcNFT.transferOwnership(msg.sender);
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /* tokenId */
    bytes calldata /* data */
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function getAllValidOfferTokens() external view returns (address[] memory) {
    return _validOfferTokens;
  }

  function getAllActiveOTCTokenIds() external view returns (uint256[] memory) {
    return allOTCs;
  }

  function getAllPackageOffers(uint256 _tokenId)
    external
    view
    returns (PkgOffer[] memory)
  {
    return pkgOffers[_tokenId];
  }

  function getFeeDiscount(address _wallet)
    public
    view
    returns (uint256, uint256)
  {
    return
      address(feeReducer) != address(0)
        ? feeReducer.percentDiscount(_wallet)
        : (0, 0);
  }

  function poolCreate(
    address _token0,
    address _token1,
    uint256 _amount0,
    uint256 _price18
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'POOLCR: enabled');
    require(_amount0 > 0, 'POOLCR: need to provide amount0');
    require(_price18 > 0, 'POOLCR: need valid price');
    // at least one token in the pool needs to be a valid ERC20
    require(
      _token0 != address(0) || _token1 != address(0),
      'POOLCR: invalid pool'
    );
    uint256 _poolFee = (_amount0 * poolAddFeePerc) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenom) = getFeeDiscount(msg.sender);
    if (_percentOff > 0) {
      _poolFee -= (_poolFee * _percentOff) / _percOffDenom;
    }
    uint256 _amount0LessFee = _amount0 - _poolFee;

    _sendETHOrERC20(
      msg.sender,
      address(this),
      _token0,
      _token0 == address(0) ? _amount0 + createServiceFeeETH : _amount0
    );
    require(
      _token1 == address(0) || IERC20(_token1).totalSupply() > 0,
      'POOLCR: token1 validate'
    );

    if (_poolFee > 0) {
      _sendETHOrERC20(address(this), _getTreasury(), _token0, _poolFee);
    }

    if (createServiceFeeETH > 0) {
      require(msg.value >= createServiceFeeETH, 'POOLCR: service fee ETH');
      _sendETHOrERC20(
        address(this),
        _getTreasury(),
        address(0),
        createServiceFeeETH
      );
    }

    uint256 _tokenId = otcNFT.mint(msg.sender);

    OTC storage _otc = otcs[_tokenId];
    Pool storage _newPool = _otc.pool;

    _newPool.token0 = _token0;
    _newPool.token1 = _token1;
    _newPool.amount0Deposited = _amount0LessFee;
    _newPool.amount0Remaining = _amount0LessFee;
    _newPool.price18 = _price18;

    _otc.creator = msg.sender;
    _otc.isPool = true;

    otcNFT.approveOverTheCounter(_tokenId);

    _otcsIndexed[_tokenId] = allOTCs.length;
    allOTCs.push(_tokenId);
    emit CreatePool(
      _tokenId,
      msg.sender,
      _token0,
      _token1,
      _amount0,
      _amount0LessFee,
      _price18
    );
  }

  function poolUpdate(
    uint256 _tokenId,
    uint256 _newPrice18,
    uint256 _amount0ToAdd,
    bool _withdrawToken1
  ) external payable nonReentrant {
    Pool storage _pool = otcs[_tokenId].pool;
    require(msg.sender == otcNFT.ownerOf(_tokenId), 'POOLUPD: owner');

    if (_newPrice18 > 0 && _pool.price18 != _newPrice18) {
      _pool.price18 = _newPrice18;
    }

    if (_amount0ToAdd > 0) {
      uint256 _poolFee = (_amount0ToAdd * poolAddFeePerc) / PERC_DEN;
      (uint256 _percentOff, uint256 _percOffDenom) = getFeeDiscount(msg.sender);
      if (_percentOff > 0) {
        _poolFee -= (_poolFee * _percentOff) / _percOffDenom;
      }
      uint256 _amount0LessFee = _amount0ToAdd - _poolFee;
      _pool.amount0Deposited += _amount0LessFee;
      _pool.amount0Remaining += _amount0LessFee;

      _sendETHOrERC20(msg.sender, address(this), _pool.token0, _amount0ToAdd);

      if (_poolFee > 0) {
        _sendETHOrERC20(address(this), _getTreasury(), _pool.token0, _poolFee);
      }
    }

    if (_withdrawToken1 && _pool.amount1Deposited > 0) {
      uint256 _amount1ToWithdraw = _pool.amount1Deposited;
      _pool.amount1Deposited = 0;
      _sendETHOrERC20(
        address(this),
        msg.sender,
        _pool.token1,
        _amount1ToWithdraw
      );
    }

    emit UpdatePool(
      _tokenId,
      msg.sender,
      _newPrice18,
      _amount0ToAdd,
      _withdrawToken1
    );
  }

  function poolRemove(uint256 _tokenId) external nonReentrant {
    Pool memory _pool = otcs[_tokenId].pool;
    require(msg.sender == otcNFT.ownerOf(_tokenId), 'POOLRM: owner');
    // at least one token in the pool needs to be a valid ERC20
    require(
      _pool.token0 != address(0) || _pool.token1 != address(0),
      'POOLRM: invalid pool'
    );

    _deleteOTC(_tokenId);

    // send remaining token0 to pool owner
    if (_pool.amount0Remaining > 0) {
      _sendETHOrERC20(
        address(this),
        msg.sender,
        _pool.token0,
        _pool.amount0Remaining
      );
    }

    // send remaining token1 to pool owner
    if (_pool.amount1Deposited > 0) {
      _sendETHOrERC20(
        address(this),
        msg.sender,
        _pool.token1,
        _pool.amount1Deposited
      );
    }
    emit RemovePool(_tokenId, msg.sender);
  }

  function swapPool(
    uint256 _tokenId,
    uint256 _amount1Provided,
    uint256 _price18Max
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'POOLSW: enabled');
    Pool storage _pool = otcs[_tokenId].pool;
    require(_pool.price18 <= _price18Max, 'POOLSW: expected swap price');
    require(_pool.amount0Remaining > 0, 'POOLSW: liquidity');

    _pool.amount1Deposited += _amount1Provided;

    // validate enough token0 assets in pool to swap based on _amount1Provided and price
    uint256 _amount0ToSend = (_amount1Provided * 10**(18 * 2)) /
      _pool.price18 /
      10**18;

    // fallback to max liquidity if trying to swap above max available
    if (_amount0ToSend > _pool.amount0Remaining) {
      _pool.amount1Deposited -= _amount1Provided;
      uint256 _origAmount1Provided = _amount1Provided;
      _amount1Provided = (_pool.amount0Remaining * _pool.price18) / 10**18;
      require(_amount1Provided <= _origAmount1Provided, 'POOLSW: backup check');
      _pool.amount1Deposited += _amount1Provided;
      _amount0ToSend = _pool.amount0Remaining;
    }
    _pool.amount0Remaining -= _amount0ToSend;

    // receive token0 from user who is swapping
    _sendETHOrERC20(msg.sender, address(this), _pool.token1, _amount1Provided);

    // send token0 to user who is swapping
    _sendETHOrERC20(address(this), msg.sender, _pool.token0, _amount0ToSend);

    totalVolume[_pool.token0] += _amount0ToSend;
    emit SwapPool(
      _tokenId,
      msg.sender,
      _pool.token0,
      _amount0ToSend,
      _pool.token1,
      _amount1Provided
    );
  }

  function packageCreate(
    // OTC asset(s) info
    Asset[] memory _assets,
    // OTC package info
    uint256 _unlockStart,
    uint256 _unlockEnd,
    address _buyItNowAsset,
    uint256 _buyItNowAmount,
    address _buyItNowWhitelist
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'PKGCR: enabled');
    require(_assets.length <= maxAssetsPerPackage, 'PKGCR: max assets');
    require(
      _buyItNowAsset == address(0) || validOfferERC20[_buyItNowAsset],
      'PKGCR: asset not valid'
    );

    uint256 _tokenId = otcNFT.mint(msg.sender);

    OTC storage _otc = otcs[_tokenId];
    Package storage _newPkg = _otc.package;

    uint256 _nativeCheck;
    for (uint256 _i; _i < _assets.length; _i++) {
      if (_assets[_i].assetContract == address(0)) {
        _nativeCheck += _assets[_i].amount;
      }
      _validateAndSupplyPackageAsset(msg.sender, _assets[_i]);

      Asset memory _newAsset = Asset({
        assetContract: _assets[_i].assetContract,
        assetType: _assets[_i].assetType,
        amount: _assets[_i].amount,
        id: _assets[_i].id
      });
      _newPkg.assets.push(_newAsset);
    }
    require(
      msg.value >= _nativeCheck + createServiceFeeETH,
      'PKGCR: ETH assets plus service'
    );
    if (createServiceFeeETH > 0) {
      _sendETHOrERC20(
        address(this),
        _getTreasury(),
        address(0),
        createServiceFeeETH
      );
    }

    require(
      (_unlockEnd == 0 && _unlockStart == 0) ||
        (_unlockEnd != 0 && _unlockStart != 0 && _unlockEnd > _unlockStart),
      'PKGCR: validate unlock period'
    );

    _newPkg.creationTime = block.timestamp;
    _newPkg.unlockStart = _unlockStart;
    _newPkg.unlockEnd = _unlockEnd;
    _newPkg.buyItNowAsset = _buyItNowAsset;
    _newPkg.buyItNowAmount = _buyItNowAmount;
    _newPkg.buyItNowWhitelist = _buyItNowWhitelist;

    _otc.creator = msg.sender;
    _otc.package = _newPkg;

    otcNFT.approveOverTheCounter(_tokenId);

    _otcsIndexed[_tokenId] = allOTCs.length;
    allOTCs.push(_tokenId);
    emit CreatePackage(_tokenId, msg.sender, _assets.length);
  }

  function packageWithdrawal(uint256 _tokenId) external nonReentrant {
    _packageWithdrawal(msg.sender, _tokenId);
  }

  function addPackageOffer(
    uint256 _tokenId,
    address _offerAsset,
    uint256 _assetAmount,
    uint256 _expiration
  ) external payable {
    require(enabled || msg.sender == owner(), 'PKGOFF: enabled');
    PkgOffer storage _newOffer = pkgOffers[_tokenId].push();
    _newOffer.owner = msg.sender;
    _newOffer.timestamp = block.timestamp;

    address _finalOfferToken;
    uint256 _finalOfferAmount;
    if (_offerAsset == address(0)) {
      require(msg.value > addOfferFee, 'PKGOFF: need ETH');
      require(validOfferERC20[address(weth)], 'PKGOFF: WETH not valid');

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
      require(msg.value == addOfferFee, 'PKGOFF: offer fee');
      require(validOfferERC20[_offerAsset], 'PKGOFF: invalid offer token');
      _finalOfferToken = _offerAsset;
      _finalOfferAmount = _assetAmount;
    }

    if (addOfferFee > 0) {
      _sendETHOrERC20(address(this), _getTreasury(), address(0), addOfferFee);
    }

    IERC20 _offTokenCont = IERC20(_finalOfferToken);
    require(
      _offTokenCont.balanceOf(msg.sender) >= _finalOfferAmount,
      'PKGOFF: bad balance'
    );
    require(
      _offTokenCont.allowance(msg.sender, address(this)) >= _finalOfferAmount,
      'PKGOFF: need allowance'
    );

    _newOffer.assetContract = _finalOfferToken;
    _newOffer.amount = _finalOfferAmount;
    _newOffer.expiration = _expiration;
    emit AddPackageOffer(
      _tokenId,
      msg.sender,
      _finalOfferToken,
      _finalOfferAmount
    );
  }

  function acceptPackageOffer(
    uint256 _tokenId,
    uint256 _offerIndex,
    address _offerAssetCheck,
    uint256 _offerAmountCheck
  ) external nonReentrant {
    require(enabled || msg.sender == owner(), 'ACCEPTOFF: enabled');
    require(otcNFT.ownerOf(_tokenId) == msg.sender, 'ACCEPTOFF: owner');

    PkgOffer memory _offer = pkgOffers[_tokenId][_offerIndex];
    require(_offer.assetContract == _offerAssetCheck, 'ACCEPTOFF: bad asset');
    require(_offer.amount == _offerAmountCheck, 'ACCEPTOFF: bad amount');
    require(
      _offer.expiration == 0 || _offer.expiration > block.timestamp,
      'ACCEPTOFF: expired'
    );

    uint256 _buyFee = (_offer.amount * buyPackageFeePerc) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenom) = getFeeDiscount(msg.sender);
    if (_percentOff > 0) {
      _buyFee -= (_buyFee * _percentOff) / _percOffDenom;
    }
    uint256 _remainingAmount = _offer.amount - _buyFee;

    if (_buyFee > 0) {
      _sendETHOrERC20(
        _offer.owner,
        _getTreasury(),
        _offer.assetContract,
        _buyFee
      );
    }
    _sendETHOrERC20(
      _offer.owner,
      msg.sender,
      _offer.assetContract,
      _remainingAmount
    );
    otcNFT.safeTransferFrom(msg.sender, _offer.owner, _tokenId);
    otcNFT.approveOverTheCounter(_tokenId);
    pkgOffers[_tokenId][_offerIndex] = pkgOffers[_tokenId][
      pkgOffers[_tokenId].length - 1
    ];
    pkgOffers[_tokenId].pop();
    totalVolume[_offer.assetContract] += _offer.amount;
    emit AcceptPackageOffer(_tokenId, msg.sender, _offerIndex);
  }

  function removePackageOffer(uint256 _tokenId, uint256 _offerIndex)
    external
    nonReentrant
  {
    PkgOffer memory _offer = pkgOffers[_tokenId][_offerIndex];
    require(
      otcNFT.ownerOf(_tokenId) == msg.sender || _offer.owner == msg.sender,
      'REJECTOFF: owner'
    );

    pkgOffers[_tokenId][_offerIndex] = pkgOffers[_tokenId][
      pkgOffers[_tokenId].length - 1
    ];
    pkgOffers[_tokenId].pop();
    emit RemovePackageOffer(_tokenId, msg.sender, _offerIndex);
  }

  function buyItNow(
    uint256 _tokenId,
    address _buyItNowToken,
    uint256 _buyItNowAmount,
    bool _unpack
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'BIN: enabled');
    address _owner = otcNFT.ownerOf(_tokenId);
    Package memory _pkg = otcs[_tokenId].package;
    require(_pkg.buyItNowAmount > 0, 'BIN: not configured');
    require(_pkg.buyItNowAsset == _buyItNowToken, 'BIN: bad token');
    require(_pkg.buyItNowAmount == _buyItNowAmount, 'BIN: bad amount');
    if (_pkg.buyItNowWhitelist != address(0)) {
      require(msg.sender == _pkg.buyItNowWhitelist, 'BIN: not whitelisted');
    }

    uint256 _buyFee = (_pkg.buyItNowAmount * buyPackageFeePerc) / PERC_DEN;
    uint256 _remainingAmount = _pkg.buyItNowAmount - _buyFee;
    address _from = msg.sender;
    if (_pkg.buyItNowAsset == address(0)) {
      _from = address(this);
      require(msg.value == _buyItNowAmount, 'BIN: not enough ETH');
    }
    if (_buyFee > 0) {
      _sendETHOrERC20(_from, _getTreasury(), _pkg.buyItNowAsset, _buyFee);
    }
    _sendETHOrERC20(_from, _owner, _pkg.buyItNowAsset, _remainingAmount);

    otcNFT.safeTransferFrom(_owner, msg.sender, _tokenId);
    otcNFT.approveOverTheCounter(_tokenId);
    totalVolume[_pkg.buyItNowAsset] += _pkg.buyItNowAmount;

    // unpack now if buying user would like
    if (_unpack) {
      _packageWithdrawal(msg.sender, _tokenId);
    }

    emit BuyItNow(
      _tokenId,
      _owner,
      msg.sender,
      _buyItNowToken,
      _buyItNowAmount
    );
  }

  function updatePackageInfo(
    uint256 _tokenId,
    uint256 _unlockStart,
    uint256 _unlockEnd,
    address _buyItNowAsset,
    uint256 _buyItNowAmount,
    address _buyItNowWhitelist
  ) external nonReentrant {
    require(otcNFT.ownerOf(_tokenId) == msg.sender, 'UDPATEPKG: owner');
    require(
      _buyItNowAsset == address(0) || validOfferERC20[_buyItNowAsset],
      'UPDATEPKG: asset not valid'
    );
    Package storage _pkg = otcs[_tokenId].package;
    _pkg.buyItNowAsset = _buyItNowAsset;
    _pkg.buyItNowAmount = _buyItNowAmount;
    _pkg.buyItNowWhitelist = _buyItNowWhitelist;

    // can only update unlock info if OTC package creator
    if (msg.sender == otcs[_tokenId].creator) {
      _pkg.unlockStart = _unlockStart;
      _pkg.unlockEnd = _unlockEnd;
    }
  }

  function tradeOTC(uint256 _sourceTokenId, uint256 _desiredTokenId)
    external
    nonReentrant
  {
    require(
      otcNFT.ownerOf(_sourceTokenId) == msg.sender,
      'TRADE: bad source owner'
    );
    // short circuit if the user is just removing the trade flag
    if (_desiredTokenId == 0) {
      delete userOtcTradeWhitelist[msg.sender][_sourceTokenId];
      return;
    }

    userOtcTradeWhitelist[msg.sender][_sourceTokenId] = _desiredTokenId;
    address _desiredOwner = otcNFT.ownerOf(_desiredTokenId);
    if (
      userOtcTradeWhitelist[_desiredOwner][_desiredTokenId] == _sourceTokenId
    ) {
      otcNFT.transferFrom(msg.sender, _desiredOwner, _sourceTokenId);
      otcNFT.transferFrom(_desiredOwner, msg.sender, _desiredTokenId);
      otcNFT.approveOverTheCounter(_sourceTokenId);
      otcNFT.approveOverTheCounter(_desiredTokenId);

      delete userOtcTradeWhitelist[msg.sender][_sourceTokenId];
      delete userOtcTradeWhitelist[_desiredOwner][_desiredTokenId];

      emit Trade(msg.sender, _desiredOwner, _sourceTokenId, _desiredTokenId);
    }
  }

  function _packageWithdrawal(address _authdUser, uint256 _tokenId) internal {
    OTC storage _otc = otcs[_tokenId];
    Package storage _pkg = _otc.package;
    address _user = otcNFT.ownerOf(_tokenId);
    require(_authdUser == _user, 'PKGWITH: owner');
    require(_pkg.assets.length > 0, 'PKGWITH: invalid package');

    for (uint256 _i; _i < _pkg.assets.length; _i++) {
      _withdrawAssetFromPackage(_user, _tokenId, _i);
    }
    _pkg.lastWithdraw = block.timestamp;

    if (
      _otc.creator == _user ||
      _pkg.unlockEnd == 0 ||
      block.timestamp >= _pkg.unlockEnd
    ) {
      _deleteOTC(_tokenId);
    }
    emit WithdrawFromPackage(_tokenId, _user);
  }

  function _validateAndSupplyPackageAsset(address _user, Asset memory _asset)
    internal
  {
    if (_asset.assetType == AssetType.ERC20) {
      // ETH or ERC20
      _sendETHOrERC20(
        _user,
        address(this),
        _asset.assetContract,
        _asset.amount
      );
    } else if (_asset.assetType == AssetType.ERC721) {
      // ERC721
      require(_asset.id > 0, 'VALIDPKG: token ID');
      IERC721(_asset.assetContract).safeTransferFrom(
        _user,
        address(this),
        _asset.id
      );
    } else {
      // ERC1155
      IERC1155(_asset.assetContract).safeTransferFrom(
        _user,
        address(this),
        _asset.id,
        _asset.amount,
        ''
      );
    }
  }

  function _withdrawAssetFromPackage(
    address _withdrawer,
    uint256 _tokenId,
    uint256 _assetIdx
  ) internal {
    Package storage _package = otcs[_tokenId].package;
    Asset storage _asset = _package.assets[_assetIdx];
    uint256 _amountCache = _asset.amount;

    if (
      otcs[_tokenId].creator != _withdrawer &&
      _package.unlockEnd > 0 &&
      block.timestamp < _package.unlockEnd
    ) {
      // if it's NFT, short circuit as it cannot be withdrawn until unlock period is over
      if (_asset.assetType == AssetType.ERC721) {
        return;
      }
      uint256 _fullVestingPeriod = _package.unlockEnd - _package.unlockStart;
      uint256 _lastWithdraw = _package.lastWithdraw > 0
        ? _package.lastWithdraw
        : _package.unlockStart > 0
        ? _package.unlockStart
        : _package.creationTime;
      require(block.timestamp >= _lastWithdraw, 'WITH: last withdraw');
      _amountCache =
        ((block.timestamp - _lastWithdraw) * _amountCache) /
        _fullVestingPeriod;
      // if there is nothing to withdraw for this asset, short circuit
      if (_amountCache == 0) {
        return;
      }

      _asset.amount -= _amountCache;
    } else {
      _asset.amount = 0;
    }

    if (_asset.assetType == AssetType.ERC20) {
      _sendETHOrERC20(
        address(this),
        _withdrawer,
        _asset.assetContract,
        _amountCache
      );
    } else if (_asset.assetType == AssetType.ERC721) {
      IERC721(_asset.assetContract).safeTransferFrom(
        address(this),
        _withdrawer,
        _asset.id
      );
    } else {
      // ERC1155
      IERC1155(_asset.assetContract).safeTransferFrom(
        address(this),
        _withdrawer,
        _asset.id,
        _amountCache,
        ''
      );
    }
  }

  function _sendETHOrERC20(
    address _source,
    address _target,
    address _token,
    uint256 _amount
  ) internal {
    if (_token == address(0)) {
      if (_target == address(this)) {
        require(msg.value >= _amount, 'SEND: not enough ETH');
      } else {
        require(_source == address(this), 'SEND: bad source');
        uint256 _balBefore = address(this).balance;
        (bool _sent, ) = payable(_target).call{ value: _amount }('');
        require(_sent, 'SEND: could not send');
        require(address(this).balance >= _balBefore - _amount, 'SEND: ETH');
      }
    } else {
      // NOTE: tokens w/ taxes on transfer should whitelist this OTC
      // contract as we don't want end users to experience unexpected
      // results by losing tokens as they're moving between here and their wallet
      IERC20 _cont = IERC20(_token);
      uint256 _tokenBalBefore = _cont.balanceOf(_target);
      if (_source == address(this)) {
        _cont.safeTransfer(_target, _amount);
      } else {
        _cont.safeTransferFrom(_source, _target, _amount);
      }
      require(
        _cont.balanceOf(_target) >= _amount + _tokenBalBefore,
        'SEND: ERC20 amount'
      );
    }
  }

  function _deleteOTC(uint256 _tokenId) internal {
    otcNFT.burn(_tokenId);
    uint256 _deletingOTCIndex = _otcsIndexed[_tokenId];
    uint256 _tokenIdMoving = allOTCs[allOTCs.length - 1];
    delete _otcsIndexed[_tokenId];
    _otcsIndexed[_tokenIdMoving] = _deletingOTCIndex;
    allOTCs[_deletingOTCIndex] = _tokenIdMoving;
    allOTCs.pop();
  }

  function _getTreasury() internal view returns (address) {
    return treasury == address(0) ? owner() : treasury;
  }

  function turnOffPackageTrading(uint256 _tokenId) external onlyNFT {
    otcs[_tokenId].package.buyItNowAmount = 0;
  }

  function setFeeReducer(IFeeReducer _reducer) external onlyOwner {
    feeReducer = _reducer;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setMaxAssetsPerPackage(uint8 _max) external onlyOwner {
    maxAssetsPerPackage = _max;
  }

  function setServiceFeeETH(uint256 _wei) external onlyOwner {
    createServiceFeeETH = _wei;
  }

  function setPoolAddFeePerc(uint256 _percent) external onlyOwner {
    require(_percent <= (PERC_DEN * 25) / 100, 'must be less than 25%');
    poolAddFeePerc = _percent;
  }

  function setBuyPackageFeePerc(uint256 _percent) external onlyOwner {
    require(_percent <= (PERC_DEN * 20) / 100, 'must be less than 20%');
    buyPackageFeePerc = _percent;
  }

  function setAddOfferFee(uint256 _wei) external onlyOwner {
    addOfferFee = _wei;
  }

  function setEnabled(bool _enabled) external onlyOwner {
    require(enabled != _enabled, 'SETENABLED: toggle');
    enabled = _enabled;
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

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}