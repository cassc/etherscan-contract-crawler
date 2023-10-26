// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IPunks} from "../interfaces/IPunks.sol";
import {IWrappedPunks} from "../interfaces/IWrappedPunks.sol";
import {IPunkGateway} from "../interfaces/IPunkGateway.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {IDebtMarket} from "../interfaces/IDebtMarket.sol";
import {EmergencyTokenRecoveryUpgradeable} from "./EmergencyTokenRecoveryUpgradeable.sol";

contract PunkGateway is IPunkGateway, ERC721HolderUpgradeable, EmergencyTokenRecoveryUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
  //////////////////////////////////////////////////////////////*/
  ILendPoolAddressesProvider internal _addressProvider;
  IWETHGateway internal _wethGateway;

  IPunks public punks;
  IWrappedPunks public wrappedPunks;
  address public proxy;

  mapping(address => bool) internal _callerWhitelists;

  uint256 private constant _NOT_ENTERED = 0;
  uint256 private constant _ENTERED = 1;
  uint256 private _status;
  /*//////////////////////////////////////////////////////////////
                        MODIFIERS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /*//////////////////////////////////////////////////////////////
                        INITIALIZERS
  //////////////////////////////////////////////////////////////*/
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /**
   * @dev Function is invoked by the proxy contract when the PunkGateway contract is added to the
   * LendPoolAddressesProvider of the market.
   **/
  function initialize(
    address addressProvider,
    address wethGateway,
    address _punks,
    address _wrappedPunks
  ) public initializer {
    __ERC721Holder_init();
    __EmergencyTokenRecovery_init();

    _addressProvider = ILendPoolAddressesProvider(addressProvider);
    _wethGateway = IWETHGateway(wethGateway);

    punks = IPunks(_punks);
    wrappedPunks = IWrappedPunks(_wrappedPunks);
    wrappedPunks.registerProxy();
    proxy = wrappedPunks.proxyInfo(address(this));

    IERC721Upgradeable(address(wrappedPunks)).setApprovalForAll(address(_getLendPool()), true);
    IERC721Upgradeable(address(wrappedPunks)).setApprovalForAll(address(_wethGateway), true);
  }

  /*//////////////////////////////////////////////////////////////
                    Fallback and Receive Functions
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev
   */
  receive() external payable {}

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert("Fallback not allowed");
  }

  /*//////////////////////////////////////////////////////////////
                        MAIN LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Approves the lendpool for given tokens
   * @param tokens the array of tokens
   **/
  function authorizeLendPoolERC20(address[] calldata tokens) external nonReentrant onlyOwner {
    uint256 tokensLength = tokens.length;
    for (uint256 i; i < tokensLength; ) {
      IERC20Upgradeable(tokens[i]).approve(address(_getLendPool()), 0);
      IERC20Upgradeable(tokens[i]).approve(address(_getLendPool()), type(uint256).max);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Authorizes/unauthorizes an array of callers to the whitelist
   * @param callers the array of callers
   * @param callers the authorization status
   **/
  function authorizeCallerWhitelist(address[] calldata callers, bool flag) external nonReentrant onlyOwner {
    uint256 callersLength = callers.length;
    for (uint256 i; i < callersLength; ) {
      _callerWhitelists[callers[i]] = flag;

      unchecked {
        i = i + 1;
      }
    }
  }

  /**
   * @inheritdoc IPunkGateway
   */
  function borrow(
    address reserveAsset,
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();

    _depositPunk(punkIndex);

    cachedPool.borrow(reserveAsset, amount, address(wrappedPunks), punkIndex, onBehalfOf, referralCode);

    IERC20Upgradeable(reserveAsset).transfer(onBehalfOf, amount);
  }

  /**
   * @inheritdoc IPunkGateway
   */
  function borrowETH(
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    _depositPunk(punkIndex);
    _wethGateway.borrowETH(amount, address(wrappedPunks), punkIndex, onBehalfOf, referralCode);
  }

  function _withdrawPunk(uint256 punkIndex, address onBehalfOf) internal {
    address owner = wrappedPunks.ownerOf(punkIndex);
    require(owner == _msgSender(), "PunkGateway: caller is not owner");
    require(owner == onBehalfOf, "PunkGateway: onBehalfOf is not owner");

    wrappedPunks.safeTransferFrom(onBehalfOf, address(this), punkIndex);
    wrappedPunks.burn(punkIndex);
    punks.transferPunk(onBehalfOf, punkIndex);
  }

  /**
   * @inheritdoc IPunkGateway
   */
  function repay(uint256 punkIndex, uint256 amount) external override nonReentrant returns (uint256, bool) {
    return _repay(punkIndex, amount);
  }

  /**
   * @inheritdoc IPunkGateway
   */
  function repayETH(uint256 punkIndex, uint256 amount) external payable override nonReentrant returns (uint256, bool) {
    (uint256 paybackAmount, bool burn) = _repayETH(punkIndex, amount, 0);

    // refund remaining dust eth
    if (msg.value > paybackAmount) {
      _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    return (paybackAmount, burn);
  }

  function buyDebtPunk(uint256 punkIndex, address onBehalfOf, uint256 amount) external override nonReentrant {
    bytes32 DEBT_MARKET = keccak256("DEBT_MARKET");

    IDebtMarket debtMarketAddress = IDebtMarket(_addressProvider.getAddress(DEBT_MARKET));
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();
    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    (, , address reserve, ) = cachedPoolLoan.getLoanCollateralAndReserve(loanId);

    IERC20Upgradeable(reserve).safeTransferFrom(msg.sender, address(this), amount);
    IERC20Upgradeable(reserve).approve(address(debtMarketAddress), amount);

    debtMarketAddress.buy(address(wrappedPunks), punkIndex, onBehalfOf, amount);
  }

  function buyDebtPunkETH(uint256 punkIndex, address onBehalfOf) external payable override nonReentrant {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();
    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    _wethGateway.buyDebtETH{value: msg.value}(address(wrappedPunks), punkIndex, onBehalfOf);
  }

  function auction(uint256 punkIndex, uint256 bidPrice, address onBehalfOf) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    (, , address reserve, ) = cachedPoolLoan.getLoanCollateralAndReserve(loanId);

    IERC20Upgradeable(reserve).safeTransferFrom(msg.sender, address(this), bidPrice);

    cachedPool.auction(address(wrappedPunks), punkIndex, bidPrice, onBehalfOf);
  }

  function auctionETH(uint256 punkIndex, address onBehalfOf) external payable override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    _wethGateway.auctionETH{value: msg.value}(address(wrappedPunks), punkIndex, onBehalfOf);
  }

  function redeem(uint256 punkIndex, uint256 amount, uint256 bidFine) external override nonReentrant returns (uint256) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);

    IERC20Upgradeable(loan.reserveAsset).safeTransferFrom(msg.sender, address(this), (amount + bidFine));

    uint256 paybackAmount = cachedPool.redeem(address(wrappedPunks), punkIndex, amount, bidFine);

    if ((amount + bidFine) > paybackAmount) {
      IERC20Upgradeable(loan.reserveAsset).safeTransfer(msg.sender, ((amount + bidFine) - paybackAmount));
    }

    return paybackAmount;
  }

  function redeemETH(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external payable override nonReentrant returns (uint256) {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    //DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);

    uint256 paybackAmount = _wethGateway.redeemETH{value: msg.value}(address(wrappedPunks), punkIndex, amount, bidFine);

    // refund remaining dust eth
    if (msg.value > paybackAmount) {
      _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    return paybackAmount;
  }

  function liquidate(uint256 punkIndex, uint256 amount) external override nonReentrant returns (uint256) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.bidderAddress == _msgSender(), "PunkGateway: caller is not bidder");

    if (amount > 0) {
      IERC20Upgradeable(loan.reserveAsset).safeTransferFrom(msg.sender, address(this), amount);
    }

    uint256 extraRetAmount = cachedPool.liquidate(address(wrappedPunks), punkIndex, amount);

    _withdrawPunk(punkIndex, loan.bidderAddress);

    if (amount > extraRetAmount) {
      IERC20Upgradeable(loan.reserveAsset).safeTransfer(msg.sender, (amount - extraRetAmount));
    }

    return (extraRetAmount);
  }

  function liquidateETH(uint256 punkIndex) external payable override nonReentrant returns (uint256) {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.bidderAddress == _msgSender(), "PunkGateway: caller is not bidder");

    uint256 extraAmount = _wethGateway.liquidateETH{value: msg.value}(address(wrappedPunks), punkIndex);

    _withdrawPunk(punkIndex, loan.bidderAddress);

    // refund remaining dust eth
    if (msg.value > extraAmount) {
      _safeTransferETH(msg.sender, msg.value - extraAmount);
    }

    return extraAmount;
  }

  function buyout(uint256 punkIndex, uint256 amount, address onBehalfOf) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    (, , address reserve, ) = cachedPoolLoan.getLoanCollateralAndReserve(loanId);

    IERC20Upgradeable(reserve).safeTransferFrom(msg.sender, address(this), amount);

    cachedPool.buyout(address(wrappedPunks), punkIndex, onBehalfOf);

    _withdrawPunk(punkIndex, onBehalfOf);
  }

  function buyoutETH(uint256 punkIndex, address onBehalfOf) external payable override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    _wethGateway.buyoutETH{value: msg.value}(address(wrappedPunks), punkIndex, onBehalfOf);

    _withdrawPunk(punkIndex, onBehalfOf);
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNALS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Repays a borrowed `amount` on a specific punk, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param punkIndex The index of the CryptoPunk used as collateral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function _repay(uint256 punkIndex, uint256 amount) internal returns (uint256, bool) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");
    (, , address reserve, ) = cachedPoolLoan.getLoanCollateralAndReserve(loanId);
    (, uint256 debt) = cachedPoolLoan.getLoanReserveBorrowAmount(loanId);
    address borrower = cachedPoolLoan.borrowerOf(loanId);

    if (amount > debt) {
      amount = debt;
    }

    IERC20Upgradeable(reserve).safeTransferFrom(msg.sender, address(this), amount);

    (uint256 paybackAmount, bool burn) = cachedPool.repay(address(wrappedPunks), punkIndex, amount);

    if (burn) {
      require(borrower == _msgSender(), "PunkGateway: caller is not borrower");
      _withdrawPunk(punkIndex, borrower);
    }

    return (paybackAmount, burn);
  }

  /**
   * @notice Repays a borrowed `amount` on a specific punk with native ETH
   * - E.g. User repays 100 ETH, burning loan and receives collateral asset
   * @param punkIndex The index of the CryptoPunk to repay
   * @param amount The amount to repay
   * @param accAmount The accumulated amount
   * @return The final amount repaid, loan is burned or not
   **/
  function _repayETH(uint256 punkIndex, uint256 amount, uint256 accAmount) internal returns (uint256, bool) {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    address borrower = cachedPoolLoan.borrowerOf(loanId);
    require(borrower == _msgSender(), "PunkGateway: caller is not borrower");

    (, uint256 repayDebtAmount) = cachedPoolLoan.getLoanReserveBorrowAmount(loanId);
    if (amount < repayDebtAmount) {
      repayDebtAmount = amount;
    }

    require(msg.value >= (accAmount + repayDebtAmount), "msg.value is less than repay amount");

    (uint256 paybackAmount, bool burn) = _wethGateway.repayETH{value: repayDebtAmount}(
      address(wrappedPunks),
      punkIndex,
      amount
    );

    if (burn) {
      _withdrawPunk(punkIndex, borrower);
    }

    return (paybackAmount, burn);
  }

  /**
   * @notice Deposits a punk given its index
   * - E.g. User deposit NFT Punk and receives the wrapped asset
   * @param punkIndex The index of the CryptoPunk to deposit
   **/
  function _depositPunk(uint256 punkIndex) internal {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    if (loanId != 0) {
      return;
    }

    address owner = punks.punkIndexToAddress(punkIndex);
    require(owner == _msgSender(), "PunkGateway: not owner of punkIndex");

    punks.buyPunk(punkIndex);
    punks.transferPunk(proxy, punkIndex);
    wrappedPunks.mint(punkIndex);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }

  /**
   * @notice Returns the LendPool address
   **/
  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  /**
   * @notice Returns the LendPoolLoan address
   **/
  function _getLendPoolLoan() internal view returns (ILendPoolLoan) {
    return ILendPoolLoan(_addressProvider.getLendPoolLoan());
  }

  /**
   * @notice Checks the onBehalfOf address is valid for a given callet
   * @param onBehalfOf the allowed address
   **/
  function _checkValidCallerAndOnBehalfOf(address onBehalfOf) internal view {
    require(
      (onBehalfOf == _msgSender()) || (_callerWhitelists[_msgSender()] == true),
      Errors.CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST
    );
  }

  /*//////////////////////////////////////////////////////////////
                      GETTERS & SETTERS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Checks if caller is whitelisted
   * @param caller caller address
   **/
  function isCallerInWhitelist(address caller) external view returns (bool) {
    return _callerWhitelists[caller];
  }
}