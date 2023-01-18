pragma solidity >=0.8.10;

import './ComptrollerInterface.sol';
import './InterestRateModel.sol';

interface VTokenInterface {
  /**
   * @notice Indicator that this is a VToken contract (for inspection)
   */
  // bool public constant isVToken = true;
  function isVToken() external returns (bool);

  function transfer(address dst, uint amount) external returns (bool);

  function transferFrom(address src, address dst, uint amount) external returns (bool);

  function approve(address spender, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function balanceOfUnderlying(address owner) external returns (uint);

  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

  function borrowRatePerBlock() external view returns (uint);

  function supplyRatePerBlock() external view returns (uint);

  function totalBorrowsCurrent() external returns (uint);

  function borrowBalanceCurrent(address account) external returns (uint);

  function borrowBalanceStored(address account) external view returns (uint);

  function exchangeRateCurrent() external returns (uint);

  function exchangeRateStored() external view returns (uint);

  function getCash() external view returns (uint);

  function accrueInterest() external returns (uint);

  function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

  /*** Admin Functions ***/

  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);

  function _acceptAdmin() external returns (uint);

  function _setComptroller(ComptrollerInterface newComptroller) external returns (uint);

  function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);

  function _reduceReserves(uint reduceAmount) external returns (uint);

  function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint);
}

interface VBep20Interface is VTokenInterface {
  /**
   * @notice Underlying asset for this VToken
   */
  function underlying() external returns (address);

  /*** User Interface ***/

  function mint(uint mintAmount) external returns (uint);

  function mintBehalf(address receiver, uint mintAmount) external returns (uint);

  function redeem(uint redeemTokens) external returns (uint);

  function redeemUnderlying(uint redeemAmount) external returns (uint);

  function borrow(uint borrowAmount) external returns (uint);

  function repayBorrow(uint repayAmount) external returns (uint);

  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

  function liquidateBorrow(
    address borrower,
    uint repayAmount,
    VTokenInterface vTokenCollateral
  ) external returns (uint);

  /*** Admin Functions ***/

  function _addReserves(uint addAmount) external returns (uint);
}

interface VDelegatorInterface {
  /**
   * @notice Implementation address for this contract
   */
  function implementation() external returns (address);

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) external;

  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @dev Should revert if any issues arise which make it unfit for delegation
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) external;

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() external;
}