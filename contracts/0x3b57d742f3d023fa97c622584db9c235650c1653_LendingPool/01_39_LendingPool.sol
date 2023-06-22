// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@chainlink/contracts/src/v0.7/KeeperCompatible.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import './LoanToken.sol';
import './LendingPoolTokenCustodian.sol';
import './LendingRewards.sol';
import './interfaces/IHyperbolicProtocol.sol';
import './interfaces/ITwapUtils.sol';

contract LendingPool is Ownable, KeeperCompatibleInterface {
  using SafeERC20 for ERC20;

  uint32 constant DENOMENATOR = 10000;
  address immutable _WETH;

  bool public enabled;
  uint32 public maxLiquidationsPerUpkeep = 50;

  LendingPoolTokenCustodian public custodian;
  LoanToken public loanNFT;
  IHyperbolicProtocol _hype;
  LendingRewards _lendingRewards;
  ITwapUtils _twapUtils;

  mapping(address => bool) public whitelistPools;
  address[] _allWhitelistedPools;
  mapping(address => uint256) _allWhitelistPoolsInd;

  uint32 public borrowInitFee = (DENOMENATOR * 3) / 100; // 3%
  uint32 public borrowAPRMin = (DENOMENATOR * 2) / 100; // 2%
  uint32 public borrowAPRMax = (DENOMENATOR * 15) / 100; // 15%
  uint32 public liquidationLTV = (DENOMENATOR * 95) / 100; // 95%
  uint32 public maxLTVOverall = (DENOMENATOR * 50) / 100; // 50%
  // pool => LTV override
  mapping(address => uint32) public maxLTVOverride;

  struct Loan {
    uint256 created; // when the loan was first created
    address createdBy; // original wallet who created loan for lending rewards
    uint256 aprStart; // the starting timestamp we should evaluate APR fees from
    address collateralPool; // Uniswap V3 Pool of collateral token and ETH (WETH)
    uint256 amountDeposited; // amount of collateral token from collateralPool deposited
    uint256 amountETHBorrowed; // amount ETH borrowed, this and collateral deposited is used to determine LTV
  }
  // tokenId => Loan
  mapping(uint256 => Loan) public loans;

  event Deposit(
    address indexed wallet,
    uint256 indexed tokenId,
    uint256 amountCollateral
  );
  event Withdraw(
    address indexed wallet,
    uint256 indexed tokenId,
    uint256 amountCollateral
  );
  event Borrow(
    address indexed wallet,
    uint256 indexed tokenId,
    uint256 amountETH
  );
  event PayBackLoan(
    address indexed wallet,
    uint256 indexed tokenId,
    uint256 amountDesired,
    uint256 amountFees
  );
  event DeleteLoan(uint256 indexed tokenId);

  constructor(
    string memory _baseTokenURI,
    IHyperbolicProtocol __hype,
    ITwapUtils __twapUtils,
    LendingRewards __lendingRewards,
    address __WETH
  ) {
    _hype = __hype;
    _twapUtils = __twapUtils;
    _lendingRewards = __lendingRewards;
    _WETH = __WETH;

    custodian = new LendingPoolTokenCustodian(address(_hype));
    loanNFT = new LoanToken(_baseTokenURI);
    loanNFT.setRoyaltyAddress(msg.sender);
    loanNFT.transferOwnership(msg.sender);
  }

  function getLTVX96(
    uint256 _tokenId
  )
    public
    view
    returns (
      uint256 ltvX96,
      uint256 ltvWithFeesX96,
      uint256 amountETHDepositedX96,
      uint256 amountETHBorrowedX96
    )
  {
    require(loanNFT.doesTokenExist(_tokenId), 'GETLTV: loan must exist');
    Loan memory _loan = loans[_tokenId];
    uint256 _fees = calculateAPRFees(_loan.amountETHBorrowed, _loan.aprStart);
    if (_loan.amountDeposited == 0 && _loan.amountETHBorrowed == 0) {
      return (0, 0, 0, 0);
    }
    uint160 _sqrtPriceX96 = _twapUtils.getSqrtPriceX96FromPoolAndInterval(
      _loan.collateralPool
    );
    uint256 _priceX96 = _twapUtils.getPriceX96FromSqrtPriceX96(_sqrtPriceX96);
    address _token0 = IUniswapV3Pool(_loan.collateralPool).token0();
    uint256 _amountETHDepositedX96 = _token0 == _WETH
      ? _loan.amountDeposited * (2 ** (96 * 2) / _priceX96)
      : _priceX96 * _loan.amountDeposited;
    uint256 _amountETHBorrowedX96 = _loan.amountETHBorrowed * FixedPoint96.Q96;
    uint256 _amountETHBorrWithFeesX96 = (_loan.amountETHBorrowed + _fees) *
      FixedPoint96.Q96;
    return (
      (_amountETHBorrowedX96 * FixedPoint96.Q96) / _amountETHDepositedX96,
      (_amountETHBorrWithFeesX96 * FixedPoint96.Q96) / _amountETHDepositedX96,
      _amountETHDepositedX96,
      _amountETHBorrowedX96
    );
  }

  function getAllWhitelistedPools() external view returns (address[] memory) {
    return _allWhitelistedPools;
  }

  function getETHBalance(address _wallet) external view returns (uint256) {
    return address(_wallet).balance;
  }

  function depositAndBorrow(
    uint256 _tokenId,
    address _pool,
    uint256 _amountDepositing,
    uint256 _amountETHBorrowing
  ) external {
    _tokenId = _deposit(msg.sender, _tokenId, _pool, _amountDepositing);
    _borrow(msg.sender, _tokenId, _amountETHBorrowing);
  }

  function deposit(uint256 _tokenId, address _pool, uint256 _amount) external {
    _deposit(msg.sender, _tokenId, _pool, _amount);
  }

  function borrow(uint256 _tokenId, uint256 _amountETHBorrowing) external {
    _borrow(msg.sender, _tokenId, _amountETHBorrowing);
  }

  function withdraw(uint256 _tokenId, uint256 _amount) external {
    _withdraw(msg.sender, _tokenId, _amount);
  }

  function payBackLoan(uint256 _tokenId) external payable {
    _payBackLoan(msg.sender, _tokenId, msg.value);
  }

  function payBackLoanAndClose(uint256 _tokenId) external payable {
    _payBackLoan(msg.sender, _tokenId, msg.value);
    _withdraw(msg.sender, _tokenId, loans[_tokenId].amountDeposited);
  }

  function _deposit(
    address _wallet,
    uint256 _tokenId,
    address _pool,
    uint256 _amount
  ) internal returns (uint256) {
    require(enabled, 'DEPOSIT: not enabled');
    (uint256 __tokenId, ) = _getOrCreateLoan(_wallet, _tokenId);
    _tokenId = __tokenId;
    Loan storage _loan = loans[_tokenId];

    IUniswapV3Pool _uniPool;
    if (_loan.collateralPool == address(0)) {
      require(whitelistPools[_pool], 'DEPOSIT: bad pool0');
      _loan.created = block.timestamp;
      _loan.createdBy = _wallet;
      _loan.aprStart = block.timestamp;
      _loan.collateralPool = _pool;
      _uniPool = IUniswapV3Pool(_pool);
    } else {
      require(whitelistPools[_loan.collateralPool], 'DEPOSIT: bad pool1');
      _uniPool = IUniswapV3Pool(_loan.collateralPool);
    }
    _loan.amountDeposited += _amount;
    address _token0 = _uniPool.token0();
    if (_token0 == _WETH) {
      ERC20 _t1 = ERC20(_uniPool.token1());
      _t1.safeTransferFrom(_wallet, address(this), _amount);
      _t1.approve(address(custodian), _amount);
      custodian.process(_t1, _loan.createdBy, _amount, false);
    } else {
      ERC20 _t0 = ERC20(_token0);
      _t0.safeTransferFrom(_wallet, address(this), _amount);
      _t0.approve(address(custodian), _amount);
      custodian.process(_t0, _loan.createdBy, _amount, false);
    }
    emit Deposit(_wallet, _tokenId, _amount);
    return _tokenId;
  }

  function _withdraw(
    address _wallet,
    uint256 _tokenId,
    uint256 _amount
  ) internal {
    require(_amount > 0, 'WITHDRAW: must withdraw from loan');
    _validateLoanOwner(_wallet, _tokenId);

    Loan storage _loan = loans[_tokenId];
    require(_amount <= _loan.amountDeposited, 'WITHDRAW: too much');
    _loan.amountDeposited -= _amount;

    // get LTV info after we've removed _amount to withdraw from loan
    (, uint256 _ltvAndFeesX96, , ) = getLTVX96(_tokenId);
    if (maxLTVOverride[_loan.collateralPool] > 0) {
      require(
        _ltvAndFeesX96 <=
          (FixedPoint96.Q96 * maxLTVOverride[_loan.collateralPool]) /
            DENOMENATOR,
        'WITHDRAW: exceeds max LTV'
      );
    } else {
      require(
        _ltvAndFeesX96 <= (FixedPoint96.Q96 * maxLTVOverall) / DENOMENATOR,
        'WITHDRAW: exceeds max LTV'
      );
    }
    IUniswapV3Pool _uniPool = IUniswapV3Pool(_loan.collateralPool);
    address _token0 = _uniPool.token0();
    if (_token0 == _WETH) {
      ERC20 _t1 = ERC20(_uniPool.token1());
      custodian.process(_t1, _loan.createdBy, _amount, true);
      _t1.safeTransfer(_wallet, _amount);
    } else {
      ERC20 _t0 = ERC20(_token0);
      custodian.process(_t0, _loan.createdBy, _amount, true);
      _t0.safeTransfer(_wallet, _amount);
    }
    if (_loan.amountDeposited == 0) {
      _deleteLoan(_tokenId);
    }
    emit Withdraw(_wallet, _tokenId, _amount);
  }

  function _borrow(
    address _wallet,
    uint256 _tokenId,
    uint256 _amountETH
  ) internal returns (uint256) {
    require(enabled, 'BORROW: not enabled');
    _validateLoanOwner(_wallet, _tokenId);

    Loan storage _loan = loans[_tokenId];
    require(whitelistPools[_loan.collateralPool], 'BORROW: bad pool');

    // take out current APR fees from amount borrowing
    uint256 _amountAPRFees = calculateAPRFees(
      _loan.amountETHBorrowed,
      _loan.aprStart
    );
    _loan.aprStart = block.timestamp;
    (, , uint256 ethDepositedX96, uint256 ethBorrowedX96) = getLTVX96(_tokenId);
    uint256 ethDeposited = ethDepositedX96 / FixedPoint96.Q96;
    uint256 ethBorrowed = ethBorrowedX96 / FixedPoint96.Q96;

    uint256 _maxLoanETH = maxLTVOverride[_loan.collateralPool] > 0
      ? (ethDeposited * maxLTVOverride[_loan.collateralPool]) / DENOMENATOR
      : (ethDeposited * maxLTVOverall) / DENOMENATOR;
    require(ethBorrowed < _maxLoanETH, 'BORROW: cannot borrow');
    if (ethBorrowed + _amountETH > _maxLoanETH) {
      _amountETH = _maxLoanETH - ethBorrowed;
    }
    require(address(this).balance >= _amountETH, 'BORROW: not enough funds');

    _loan.amountETHBorrowed += _amountETH;
    uint256 _amountFees = _amountAPRFees +
      ((_amountETH * borrowInitFee) / DENOMENATOR);
    require(_amountETH > _amountFees, 'BORROW: fees more than borrow amount');

    uint256 _amountToBorrower = _amountETH - _amountFees;
    _lendingRewards.depositRewards{ value: _amountFees }();
    (bool success, ) = payable(_wallet).call{ value: _amountToBorrower }('');
    require(success, 'BORROW: ETH not delivered');

    emit Borrow(_wallet, _tokenId, _amountETH);
    return _tokenId;
  }

  function _payBackLoan(
    address _wallet,
    uint256 _tokenId,
    uint256 _amount
  ) internal {
    require(_amount > 0, 'PAYBACK: no ETH to pay back');
    _validateLoanOwner(_wallet, _tokenId);

    Loan storage _loan = loans[_tokenId];
    // take out current APR fees from amount borrowing
    uint256 _amountAPRFees = calculateAPRFees(
      _loan.amountETHBorrowed,
      _loan.aprStart
    );
    _loan.aprStart = block.timestamp;
    require(_amount > _amountAPRFees, 'PAYBACK: must pay back above fees');
    uint256 _amountBorrowedPlusFees = _loan.amountETHBorrowed + _amountAPRFees;

    uint256 _refund;
    if (_amount > _amountBorrowedPlusFees) {
      _refund = _amount - _amountBorrowedPlusFees;
    }

    // remove amount minus fees from the amount borrowed
    if ((_amount - _amountAPRFees) > _loan.amountETHBorrowed) {
      _loan.amountETHBorrowed = 0;
    } else {
      _loan.amountETHBorrowed -= (_amount - _amountAPRFees);
    }
    if (_amountAPRFees > 0) {
      _lendingRewards.depositRewards{ value: _amountAPRFees }();
    }
    if (_refund > 0) {
      (bool wasRefunded, ) = payable(_wallet).call{ value: _refund }('');
      require(wasRefunded, 'PAYBACK: refund unsuccessful');
    }
    emit PayBackLoan(_wallet, _tokenId, _amount, _amountAPRFees);
  }

  function _getOrCreateLoan(
    address _wallet,
    uint256 _tokenId
  ) internal returns (uint256 tokenId, bool isNewLoan) {
    if (_tokenId == 0) {
      tokenId = loanNFT.mint(_wallet);
      return (tokenId, true);
    }
    _validateLoanOwner(_wallet, _tokenId);
    tokenId = _tokenId;
    return (tokenId, false);
  }

  function _deleteLoan(uint256 _tokenId) internal {
    delete loans[_tokenId];
    loanNFT.burn(_tokenId);
    emit DeleteLoan(_tokenId);
  }

  function calculateAPRFees(
    uint256 _amountETHBorrowed,
    uint256 _aprStart
  ) public view returns (uint256) {
    return
      ((block.timestamp - _aprStart) *
        calculateBorrowAPR() *
        _amountETHBorrowed) /
      DENOMENATOR /
      365 days;
  }

  function calculateBorrowAPR() public view returns (uint256) {
    (uint256 _poolBalETH, uint256 _mcETH) = _hype.poolBalToMarketCapRatio();
    uint256 _targetPoolBal = (_mcETH * _hype.poolToMarketCapTarget()) /
      DENOMENATOR;
    if (_poolBalETH < _targetPoolBal) {
      uint256 _aprLessMax = ((borrowAPRMax - borrowAPRMin) * _poolBalETH) /
        _targetPoolBal;
      return borrowAPRMax - _aprLessMax;
    }
    return borrowAPRMin;
  }

  function shouldLiquidateLoan(uint256 _tokenId) external view returns (bool) {
    return _shouldLiquidateLoan(_tokenId);
  }

  function _shouldLiquidateLoan(uint256 _tokenId) internal view returns (bool) {
    if (!loanNFT.doesTokenExist(_tokenId)) {
      return false;
    }
    (, uint256 _ltvWithFeesX96, , ) = getLTVX96(_tokenId);
    return _ltvWithFeesX96 >= (FixedPoint96.Q96 * liquidationLTV) / DENOMENATOR;
  }

  function _toggleWhitelistCollateralPool(address _pool) internal {
    if (whitelistPools[_pool]) {
      uint256 _ind = _allWhitelistPoolsInd[_pool];
      address _poolMoving = _allWhitelistedPools[
        _allWhitelistedPools.length - 1
      ];
      _allWhitelistedPools[_ind] = _poolMoving;
      _allWhitelistPoolsInd[_poolMoving] = _ind;
      delete whitelistPools[_pool];
      _allWhitelistedPools.pop();
    } else {
      // add
      whitelistPools[_pool] = true;
      _allWhitelistPoolsInd[_pool] = _allWhitelistedPools.length;
      _allWhitelistedPools.push(_pool);
    }
  }

  function checkUpkeep(
    bytes calldata
  )
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    uint256[] memory _openedLoans = loanNFT.getAllOpenedLoans();
    uint256[] memory _upkeepLoans = new uint256[](maxLiquidationsPerUpkeep);
    uint32 _numUpkeeps = 0;
    for (uint256 _i = 0; _i < _openedLoans.length; _i++) {
      if (_numUpkeeps >= maxLiquidationsPerUpkeep) {
        break;
      }
      uint256 _tokenId = _openedLoans[_i];
      if (_shouldLiquidateLoan(_tokenId)) {
        upkeepNeeded = true;
        _upkeepLoans[_numUpkeeps] = _tokenId;
        _numUpkeeps++;
      }
    }

    if (upkeepNeeded) {
      performData = abi.encode(_upkeepLoans);
    }
  }

  function performUpkeep(bytes calldata performData) external override {
    uint256[] memory _upkeepLoans = abi.decode(performData, (uint256[]));
    for (uint256 _i = 0; _i < _upkeepLoans.length; _i++) {
      uint256 _tokenId = _upkeepLoans[_i];
      if (_tokenId == 0) {
        break;
      }
      if (_shouldLiquidateLoan(_tokenId)) {
        Loan memory _loan = loans[_tokenId];
        uint256 _amountDeposited = _loan.amountDeposited;
        IUniswapV3Pool _pool = IUniswapV3Pool(_loan.collateralPool);
        address _token0 = _pool.token0();
        if (_token0 == _WETH) {
          ERC20 _t1 = ERC20(_pool.token1());
          custodian.process(_t1, _loan.createdBy, _amountDeposited, true);
          _t1.safeTransfer(owner(), _amountDeposited);
        } else {
          ERC20 _t0 = ERC20(_token0);
          custodian.process(_t0, _loan.createdBy, _amountDeposited, true);
          _t0.safeTransfer(owner(), _amountDeposited);
        }
        _deleteLoan(_tokenId);
      }
    }
  }

  function _validateLoanOwner(address _wallet, uint256 _tokenId) internal view {
    require(_wallet == loanNFT.ownerOf(_tokenId), 'VALIDATEOWNER');
  }

  function setBorrowInitFee(uint32 _fee) external onlyOwner {
    require(_fee <= (DENOMENATOR * 30) / 100, 'SETBFEE: lte 30%');
    borrowInitFee = _fee;
  }

  function setBorrowAPRMin(uint32 _apr) external onlyOwner {
    require(_apr <= (DENOMENATOR * 10) / 100, 'SETBAPRMIN: lte 10%');
    borrowAPRMin = _apr;
  }

  function setBorrowAPRMax(uint32 _apr) external onlyOwner {
    require(_apr <= DENOMENATOR, 'SETBAPRMAX: lte 100%');
    borrowAPRMax = _apr;
  }

  function setMaxLTVOverall(uint32 _ltv) external onlyOwner {
    require(_ltv <= DENOMENATOR, 'SETLTVMAX: lte 100%');
    maxLTVOverall = _ltv;
  }

  function setMaxLTVOverride(address _pool, uint32 _ltv) external onlyOwner {
    require(_ltv <= DENOMENATOR, 'SETLTVMAX: lte 100%');
    maxLTVOverride[_pool] = _ltv;
  }

  function setLiquidationLTV(uint32 _ltv) external onlyOwner {
    require(_ltv <= DENOMENATOR, 'SETLPLTV: lte 100%');
    liquidationLTV = _ltv;
  }

  function setMaxLiquidationsPerUpkeep(uint32 _max) external onlyOwner {
    maxLiquidationsPerUpkeep = _max;
  }

  function setEnabled(bool _enabled) external onlyOwner {
    require(enabled != _enabled, 'SETENABLED: must toggle');
    enabled = _enabled;
  }

  function toggleWhitelistCollateralPool(address _pool) external onlyOwner {
    IUniswapV3Pool _uniPool = IUniswapV3Pool(_pool);
    address _token0 = _uniPool.token0();
    address _token1 = _uniPool.token1();
    require(_token0 == _WETH || _token1 == _WETH, 'TOGGLECOLL: no ETH');

    uint32[] memory secondsAgo = new uint32[](2);
    secondsAgo[0] = 5 minutes;
    secondsAgo[1] = 0;
    _uniPool.observe(secondsAgo);

    _toggleWhitelistCollateralPool(_pool);
  }

  receive() external payable {}
}