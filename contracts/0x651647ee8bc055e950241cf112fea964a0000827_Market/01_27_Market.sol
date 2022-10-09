// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import './libraries/Detector.sol';
import './libraries/RentaFiSVG.sol';
import './libraries/Calculator.sol';
import './interfaces/IMarket.sol';
import './interfaces/IVault.sol';
import './interfaces/IERC20Detailed.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/*******************************************************************************************
 *  ERROR
 *******************************************************************************************/
error AlreadyReserved();
error overLimits();
error NotAvailable();

contract Market is ERC721, ERC721Burnable, Ownable, ReentrancyGuard, Pausable, IMarket {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;
  using Detector for address;

  constructor() ERC721('RentaFi Yield NFT', 'RentaFi-YN') {}

  /*******************************************************************************************
   *  STORAGE
   *******************************************************************************************/
  uint256 private constant E5 = 1e5;
  Counters.Counter private totalLended;
  Counters.Counter private totalRented;

  uint256 public protocolAdminFeeRatio = 10 * 1000;
  uint256 public reservationLimits = 10 days;

  // whitelisted vault list
  address[] internal vaults;

  // lockId => LendRent
  mapping(uint256 => LendRent) public lendRent;
  // vaultAddress => allowed
  mapping(address => uint256) public vaultWhiteList;
  // lockId => paymentToken =>lenderBenefit
  mapping(uint256 => mapping(address => uint256)) public lenderBenefit; //TODO ユーザーがそれぞれのトークンでいくら収益を持っているかを取得する
  // vaultAddress => paymentToken =>collectionOwnerBenefit
  mapping(address => mapping(address => uint256)) public collectionOwnerBenefit;
  // paymentToken => protocolAdminBenefit
  mapping(address => uint256) public protocolAdminBenefit;
  // paymentToken => uint256 as a bool
  mapping(address => uint256) public paymentTokenWhiteList; //NOTE: paymentTokenの配列を削除しました

  /*******************************************************************************************
   *  MODIFIER
   *******************************************************************************************/
  modifier onlyLender(uint256 _lockId) {
    require(lendRent[_lockId].lend.lender == msg.sender, 'OnlyLender');
    _;
  }

  modifier onlyPayoutAddress(address _vaultAddress) {
    require(msg.sender == IVault(_vaultAddress).payoutAddress(), 'onlyPayoutAddress');
    _;
  }

  modifier onlyProtocolAdmin() {
    require(owner() == msg.sender, 'onlyProtocolAdmin');
    _;
  }

  modifier onlyONftOwner(uint256 _lockId) {
    require(IVault(lendRent[_lockId].lend.vault).ownerOf(_lockId) == msg.sender, 'onlyONftOwner');
    _;
  }

  modifier onlyYNftOwner(uint256 _lockId) {
    require(ownerOf(_lockId) == msg.sender, 'onlyYNftOwner');
    _;
  }

  modifier onlyBeforeLock(uint256 _lockId) {
    require(
      lendRent[_lockId].rent.length == 0 ||
        lendRent[_lockId].lend.lockStartTime == lendRent[_lockId].lend.lockExpireTime,
      'onlyBeforeLock'
    );
    _;
  }

  modifier onlyAfterLockExpired(uint256 _lockId) {
    require(block.timestamp > lendRent[_lockId].lend.lockExpireTime, 'onlyAfterLockExpired');
    _;
  }

  modifier onlyNotRentaled(uint256 _lockId) {
    Rent[] storage _rents = lendRent[_lockId].rent;
    /*unchecked {
      for (uint256 i; i < _rents.length; i++)
        _deleteLockId(renterLockIds, _rents[i].renterAddress, _lockId);
    }*/
    _deleteExpiredRent(_rents);
    require(_rents.length == 0, 'onlyNotRentaled');
    _;
  }

  /*******************************************************************************************
   *  EXTERNAL FUNCTIONS
   *******************************************************************************************/

  /***
   * @title mintAndCreateList
   * @notice Deposit the NFT into an escrow contract.
   * @param _tokenId ID of the NFT you wish to loan out
   * @param _lockDuration duration by days. if 0 is entered, NFT will no lock, but if it non-zero NFT will lock and mint yNFT
   * @param _minRentalDuration minimum consecutive duration by days. (ex) 0~
   * @param _maxRentalDuration maximum consecutive duration by day.
   * @param _amount token amount (only in the case of ERC1155)
   * @param _dailyRentalPrice price per daily unit.
   * @param _privateAddress Lend Nft for specific address. If you set 0x00..., lend will not to be reserved.
   * @param _vaultAddress The Vault address corresponding to the collection you wish to loan out
   * @param _paymentToken you can set specific payment token. (ex) 0x00 => Native token, 0xEXAMPLE => ERC20 token
   * @param _paymentMethod 0:Onetime payment, 1~3: WIP
   */
  function mintAndCreateList(
    uint256 _tokenId,
    uint256 _lockDuration,
    uint256 _minRentalDuration,
    uint256 _maxRentalDuration,
    uint256 _amount,
    uint256 _dailyRentalPrice,
    address _privateAddress,
    address _vaultAddress,
    address _paymentToken,
    PaymentMethod _paymentMethod
  ) external whenNotPaused {
    require(_amount > 0, 'NotZero');
    require(_lockDuration == 0 || _lockDuration >= _minRentalDuration, 'lockDur<minRentalDur');
    require(_lockDuration == 0 || _maxRentalDuration <= _lockDuration, 'maxRentDur>lockDur');
    require(_minRentalDuration <= _maxRentalDuration, 'minRentalDur>maxRentalDur');
    require(vaultWhiteList[_vaultAddress] >= 1, 'Notwhitelisted');
    require(IVault(_vaultAddress).getTokenIdAllowed(_tokenId), 'NotAllowedId');
    require(
      IVault(_vaultAddress).minPrices(_paymentToken) <= _dailyRentalPrice,
      'dailyRentPrice<min'
    );
    require(
      IVault(_vaultAddress).minDuration() <= _minRentalDuration * 1 days,
      'minRentDur<minDur'
    );
    require(
      IVault(_vaultAddress).maxDuration() >= _maxRentalDuration * 1 days,
      'maxRentDur>maxDur'
    );
    require(_isPaymentTokenAllowed(_vaultAddress, _paymentToken) >= 1, 'NotAllowedToken'); //NOTE: この内部関数をいじってます

    totalLended.increment();
    uint256 _lockId = totalLended.current();

    _createList(
      _lockId,
      _tokenId,
      _lockDuration,
      _minRentalDuration,
      _maxRentalDuration,
      _amount,
      _dailyRentalPrice,
      _privateAddress,
      _vaultAddress,
      _paymentToken,
      _paymentMethod
    );

    // To avoid error below, mint NFTs after creating the list
    // CompilerError: Stack too deep, try removing local variables.
    _mintNft(_lockId, _lockDuration);
  }

  /***
   * @title rent
   * @notice Lending process: On the vault side, process whether to send originalNFT or wrapNFT as mint.
   * @param _lockId increment number of listed created by executing mintAndCreateList Fx.
   * @param _rentalStartTimestamp rental start at this time. If zero, rent now.
   * @param _rentalDurationByDay how many days want to rent
   * @param _amount if you rent type of ERC1155, enter amount. if 721, just enter 1.
   */
  function rent(
    uint256 _lockId,
    uint256 _rentalStartTimestamp, // If zero, rent now
    uint256 _rentalDurationByDay,
    uint256 _amount
  ) external payable whenNotPaused nonReentrant {
    if (_rentalStartTimestamp > (block.timestamp + reservationLimits)) revert overLimits();

    Lend memory _lend = lendRent[_lockId].lend;

    {
      address _privateAddress = _lend.privateAddress;
      if (!(_privateAddress == address(0) || msg.sender == _privateAddress))
        revert AlreadyReserved();
    }

    _calcFee(
      _lockId,
      _lend.dailyRentalPrice,
      _lend.lockStartTime,
      _lend.lockExpireTime,
      _lend.lender,
      _rentalDurationByDay,
      _amount,
      _lend.vault,
      _lend.paymentToken
    );

    (uint256 _rentalStartTime, uint256 _rentalExpireTime) = Calculator.duration(
      _rentalStartTimestamp,
      _rentalDurationByDay,
      _lend.lockStartTime,
      _lend.lockExpireTime,
      _lend.maxRentalDuration,
      _lend.minRentalDuration
    );

    totalRented.increment();
    uint256 _rentId = totalRented.current();

    Rent memory _rent = Rent({
      renterAddress: msg.sender,
      rentId: _rentId,
      rentalStartTime: _rentalStartTime,
      rentalExpireTime: _rentalExpireTime,
      amount: _amount
    });

    _updateRent(_lend.vault, _lockId, _lend, _rent);

    // Pseudo Transfer WrappedNFT (if it starts later, only booking)
    IVault(_lend.vault).mintWNft(
      msg.sender,
      _rentalStartTime,
      _rentalExpireTime,
      _lockId,
      _lend.tokenId,
      _amount
    );

    emit Rented(_rentId, msg.sender, _lockId, _rent);
  }

  /***
   * @title activate
   * @notice if Non-zero is entered for rentalStartTimestamp, renter has to activate at RentalStartTime
   * @param _lockId Reserved LockId
   * @param _rentId Reserved rentId
   */
  function activate(uint256 _lockId, uint256 _rentId) external {
    require(_rentId > 0, 'InvalidRentId');
    Rent[] memory _rents = lendRent[_lockId].rent;
    uint256 _rentsLength = _rents.length;
    for (uint256 i; i < _rentsLength; ) {
      if (_rents[i].rentId == _rentId)
        IVault(lendRent[_lockId].lend.vault).activate(
          _rentId,
          _lockId,
          msg.sender,
          _rents[i].amount
        );
      unchecked {
        i++;
      }
    }
  }

  /***
   * @title cancel
   * @notice if you locked your nft, Can be cancelled if there are no renters.
   * @param _lockId your ownershipNFT's (and yieldNFT's) tokenId equals lockId
   */
  function cancel(uint256 _lockId)
    external
    onlyLender(_lockId)
    onlyBeforeLock(_lockId)
    onlyNotRentaled(_lockId)
  {
    if (lendRent[_lockId].lend.lockStartTime != lendRent[_lockId].lend.lockExpireTime)
      burn(_lockId); // burn yNFT
    _redeemNFT(_lockId); // burn oNFT and redeem original token
    emit Canceled(_lockId);
  }

  /***
   * @title claimNFT
   * @notice Burn oNFT to execute an internal function that redeems the original NFT
   * @param _lockId the ownershipNFT's tokenId what you want to burn and return original nft
   */
  function claimNFT(uint256 _lockId)
    external
    onlyONftOwner(_lockId)
    onlyAfterLockExpired(_lockId)
    onlyNotRentaled(_lockId)
  {
    _redeemNFT(_lockId);
  }

  /***
   * @title claimFee
   * @notice Burn yNFT to execute an internal function that redeems the Rental Revenue
   * @param _lockId the yieldNFT's tokenId what you want to burn and claim revenue
   */
  function claimFee(uint256 _lockId) external onlyYNftOwner(_lockId) onlyAfterLockExpired(_lockId) {
    _claimFee(_lockId);
  }

  /***
   * @title claimRoyalty
   * @notice Collection owner claim own revenue
   * @param _vaultAddress vault address paired collection
   */
  function claimRoyalty(address _vaultAddress) external onlyPayoutAddress(_vaultAddress) {
    address[] memory _allowedPaymentTokens = IVault(_vaultAddress).getPaymentTokens();
    uint256 _allowedPaymentTokensLength = _allowedPaymentTokens.length;
    for (uint256 i; i < _allowedPaymentTokensLength; ) {
      uint256 _sendAmount = collectionOwnerBenefit[_vaultAddress][_allowedPaymentTokens[i]];
      if (_allowedPaymentTokens[i] == address(0)) {
        payable(msg.sender).transfer(_sendAmount);
      } else {
        IERC20(_allowedPaymentTokens[i]).safeTransfer(msg.sender, _sendAmount);
      }
      delete collectionOwnerBenefit[_vaultAddress][_allowedPaymentTokens[i]];
      unchecked {
        i++;
      }
    }
    emit ClaimedRoyalty(IVault(_vaultAddress).originalCollection());
  }

  /***
   * @title claimProtocolFee
   * @notice Protocol owners extract revenue
   * @param _paymentTokens array of paymentToken
   * @dev Manually pass token addresses in batches
   */
  function claimProtocolFee(address[] calldata _paymentTokens) external onlyProtocolAdmin {
    uint256 _paymentTokensLength = _paymentTokens.length; //トレージから呼び出しではなく引数で渡すようにした
    for (uint256 i; i < _paymentTokensLength; ) {
      uint256 _sendAmount = protocolAdminBenefit[_paymentTokens[i]];
      if (_paymentTokens[i] == address(0)) {
        payable(msg.sender).transfer(_sendAmount);
      } else {
        IERC20(_paymentTokens[i]).safeTransfer(msg.sender, _sendAmount);
      }
      delete protocolAdminBenefit[_paymentTokens[i]];
      unchecked {
        i++;
      }
    }
  }

  /***
   * @title emergencyWithdraw
   * @notice Functions for withdrawing assets in an emergency
   * @param _lockId See o,yNFT
   * @dev this can be executed when protocol would be paused
   */
  function emergencyWithdraw(uint256 _lockId) external whenPaused onlyYNftOwner(_lockId) {
    _claimFee(_lockId);
  }

  /*******************************************************************************************
   *  GETTER FUNCTIONS
   *******************************************************************************************/

  /***
   * @title checkAvailability
   * @notice Find out how many rentals are left available
   * @param _lockId what you want to check
   * @return uint256 return amount. 0 as false
   */
  function checkAvailability(uint256 _lockId) external view returns (uint256) {
    uint256 _now = block.timestamp;
    return
      Detector.availability(
        IVault(lendRent[_lockId].lend.vault).originalCollection(),
        lendRent[_lockId].rent,
        lendRent[_lockId].lend,
        _now,
        _now
      );
  }

  /***
   * @title getLendRent
   * @notice Getters that are set automatically do not return arrays in the structure, so this must be specified explicitly
   * @param _lockId what you want to check
   * @return LendRent return structure
   */
  function getLendRent(uint256 _lockId) external view returns (LendRent memory) {
    return lendRent[_lockId];
  }

  /** @dev see {ERC721} */
  function tokenURI(uint256 _lockId) public view override returns (string memory) {
    require(_exists(_lockId), 'ERC721Metadata: URI query for nonexistent token');

    Lend memory _lend = lendRent[_lockId].lend;

    // TODO: This must be changed by deploying chain
    string memory _tokenSymbol = 'ETH';
    if (_lend.paymentToken != address(0))
      _tokenSymbol = IERC20Detailed(_lend.paymentToken).symbol();
    string memory _name = IVault(IVault(_lend.vault).originalCollection()).name();

    bytes memory json = RentaFiSVG.getYieldSVG(
      _lockId,
      _lend.tokenId,
      _lend.amount,
      lenderBenefit[_lockId][_lend.paymentToken],
      _lend.lockStartTime,
      _lend.lockExpireTime,
      IVault(_lend.vault).originalCollection(),
      _name,
      _tokenSymbol
    );
    string memory _tokenURI = string(
      abi.encodePacked('data:application/json;base64,', Base64.encode(json))
    );
    return _tokenURI;
  }

  /*******************************************************************************************
   *  GETTER FUNCTIONS
   *******************************************************************************************/

  /***
   * @title setProtocolAdminFeeRatio
   * @notice
   * @param _protocolAdminFeeRatio
   */
  function setProtocolAdminFeeRatio(uint256 _protocolAdminFeeRatio) external onlyProtocolAdmin {
    if (_protocolAdminFeeRatio > 10 * 1000) revert overLimits();
    protocolAdminFeeRatio = _protocolAdminFeeRatio;
  }

  /***
   * @title setReservationLimit
   * @notice
   * @param _days
   */
  function setReservationLimit(uint256 _days) public onlyProtocolAdmin {
    reservationLimits = _days * 1 days;
  }

  /***
   * @title setVaultWhiteList
   * @notice
   * @param _vaultAddress
   * @param _allowed
   */
  function setVaultWhiteList(address _vaultAddress, uint256 _allowed) external onlyProtocolAdmin {
    if (_allowed >= 1) {
      vaultWhiteList[_vaultAddress] = _allowed;
    } else {
      delete vaultWhiteList[_vaultAddress];
    }
    uint256 _exists;
    address[] memory local_vaults = vaults;
    uint256 local_vaultsLength = local_vaults.length;
    for (uint256 i; i < local_vaultsLength; ) {
      if (local_vaults[i] == _vaultAddress) {
        _exists = 1;
        break;
      }
      unchecked {
        i++;
      }
    }
    if (_exists < 1) vaults.push(_vaultAddress);
    emit WhiteListed(IVault(_vaultAddress).originalCollection(), _vaultAddress);
  }

  /***
   * @title setPaymentTokenWhiteList
   * @notice
   * @param _token
   * @param _bool as Uint256. 0 is false, non-zero is true
   */
  function setPaymentTokenWhiteList(address _token, uint256 _bool) external onlyProtocolAdmin {
    paymentTokenWhiteList[_token] = _bool;
  }

  /** @dev see {Pausable} */
  function pause() external onlyProtocolAdmin {
    paused() ? _unpause() : _pause();
  }

  /*******************************************************************************************
   *  PRIVATE FUNCTIONS
   *******************************************************************************************/
  function _deleteExpiredRent(Rent[] storage _rents) private {
    uint256 _now = block.timestamp;
    for (uint256 i = 1; i <= _rents.length; ) {
      if (_rents[i - 1].rentalExpireTime < _now) {
        if (_rents[_rents.length - 1].rentalExpireTime >= _now) {
          _rents[i - 1] = _rents[_rents.length - 1];
        } else {
          i--;
        }
        _rents.pop();
      }
      unchecked {
        i++;
      }
    }
  }

  function _isPaymentTokenAllowed(address _vaultAddress, address _paymentToken)
    private
    view
    returns (uint256 _allowed)
  {
    _allowed = IVault(_vaultAddress).minPrices(_paymentToken);
  }

  function _claimFee(uint256 _lockId) private {
    address[] memory _allowedPaymentTokens = IVault(lendRent[_lockId].lend.vault)
      .getPaymentTokens();
    uint256 _allowedPaymentTokensLength = _allowedPaymentTokens.length;
    for (uint256 i; i < _allowedPaymentTokensLength; ) {
      uint256 _sendAmount = lenderBenefit[_lockId][_allowedPaymentTokens[i]];
      delete lenderBenefit[_lockId][_allowedPaymentTokens[i]];
      if (_allowedPaymentTokens[i] == address(0)) {
        payable(msg.sender).transfer(_sendAmount);
      } else {
        IERC20(_allowedPaymentTokens[i]).safeTransfer(msg.sender, _sendAmount);
      }
      unchecked {
        i++;
      }
    }
    if (lendRent[_lockId].lend.lockStartTime != lendRent[_lockId].lend.lockExpireTime)
      burn(_lockId); // burn yNFT
    emit Claimed(_lockId);
  }

  function _calcFee(
    uint256 _lockId,
    uint256 _dailyRentalPrice,
    uint64 _lockStartTime,
    uint64 _lockExpireTime,
    address _lender,
    uint256 _rentalDurationByDay,
    uint256 _amount,
    address _vault,
    address _paymentToken
  ) private {
    (
      uint256 _lenderBenefit,
      uint256 _collectionOwnerBenefit,
      uint256 _protocolAdminBenefit
    ) = Calculator.fee(
        _dailyRentalPrice,
        _lockStartTime,
        _lockExpireTime,
        _lender,
        _paymentToken,
        protocolAdminFeeRatio,
        _rentalDurationByDay,
        _amount,
        IVault(_vault).collectionOwnerFeeRatio()
      );

    lenderBenefit[_lockId][_paymentToken] = lenderBenefit[_lockId][_paymentToken] + _lenderBenefit;
    collectionOwnerBenefit[_vault][_paymentToken] =
      collectionOwnerBenefit[_vault][_paymentToken] +
      _collectionOwnerBenefit;
    protocolAdminBenefit[_paymentToken] =
      protocolAdminBenefit[_paymentToken] +
      _protocolAdminBenefit;
  }

  function _updateRent(
    address _vaultAddress,
    uint256 _lockId,
    Lend memory _lend,
    Rent memory _rent
  ) private {
    _deleteExpiredRent(lendRent[_lockId].rent);

    if (
      !(Detector.availability(
        IVault(_vaultAddress).originalCollection(),
        lendRent[_lockId].rent,
        _lend,
        _rent.rentalStartTime,
        _rent.rentalExpireTime
      ) >= 1)
    ) revert NotAvailable();

    // Push new rent
    lendRent[_lockId].rent.push(_rent);
  }

  function _mintNft(uint256 _lockId, uint256 _lockDuration) private {
    _mintONft(_lockId);
    // Mint the yNFT to match the mint of the oNFT
    if (_lockDuration != 0) _mintYNft(_lockId);
  }

  // Deposit the original NFT to the Vault
  // Receive oNFT minted instead
  function _mintONft(uint256 _lockId) private {
    (address _vaultAddress, uint256 _tokenId, uint256 _amount) = (
      lendRent[_lockId].lend.vault,
      lendRent[_lockId].lend.tokenId,
      lendRent[_lockId].lend.amount
    );
    // Process the NFT to deposit it in the vault
    // Send and mint the NFT after confirming that the owner of the NFT is executing
    // Get the address of the original NFT
    // NFT sent to vault (= locked)
    _safeTransferBundle(
      IVault(_vaultAddress).originalCollection(),
      msg.sender,
      _vaultAddress,
      _tokenId,
      _amount
    );
    // Minting oNft from Vault.
    IVault(_vaultAddress).mintONft(_lockId);
  }

  // Mint the yNFT instead of listing it on the market
  function _mintYNft(uint256 _lockId) private {
    _mint(msg.sender, _lockId);
  }

  // The part that actually creates the lending board
  function _createList(
    uint256 _lockId, // Unique number for each loan
    uint256 _tokenId,
    uint256 _lockDuration,
    uint256 _minRentalDuration,
    uint256 _maxRentalDuration,
    uint256 _amount,
    uint256 _dailyRentalPrice,
    address _privateAddress,
    address _vaultAddress,
    address _paymentToken,
    PaymentMethod _paymentMethod
  ) private {
    uint256 _now = block.timestamp;
    // By the time you get here, the deposit process has been completed and the o/yNFT has been issued.
    LendRent storage _lendRent = lendRent[_lockId];

    _lendRent.lend = Lend({
      minRentalDuration: uint64(_minRentalDuration),
      maxRentalDuration: uint64(_maxRentalDuration),
      lockStartTime: uint64(_now),
      lockExpireTime: uint64(_now + (_lockDuration * 1 days)),
      dailyRentalPrice: _dailyRentalPrice,
      tokenId: _tokenId,
      amount: _amount,
      vault: _vaultAddress,
      lender: msg.sender,
      paymentToken: _paymentToken,
      privateAddress: _privateAddress,
      paymentMethod: _paymentMethod
    });

    emit Listed(_lockId, msg.sender, _lendRent.lend);
  }

  // Redeem NFTs deposited in the Vault by Burning oNFTs
  function _redeemNFT(uint256 _lockId) private {
    // Redeem NFTs deposited in the vault. wrapped NFTs are released on the vault side.
    IVault(lendRent[_lockId].lend.vault).redeem(_lockId);
    delete lendRent[_lockId];
    emit Withdrawn(_lockId);
  }

  function _safeTransferBundle(
    address _originalNftAddress,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount
  ) private {
    if (_originalNftAddress.is1155()) {
      IERC1155(_originalNftAddress).safeTransferFrom(_from, _to, _tokenId, _amount, '');
    } else if (_originalNftAddress.is721()) {
      IERC721(_originalNftAddress).safeTransferFrom(_from, _to, _tokenId);
    } else {
      IVault(_originalNftAddress).transferFrom(_from, _to, _tokenId);
    }
  }
}