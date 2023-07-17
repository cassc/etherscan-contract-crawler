// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {ILendPoolAddressesProvider} from "../../../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../../../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../../../interfaces/ILendPoolLoan.sol";
import {IUToken} from "../../../interfaces/IUToken.sol";
import {IDebtMarket} from "../../../interfaces/IDebtMarket.sol";

import {DataTypes} from "../../../libraries/types/DataTypes.sol";
import {NftConfiguration} from "../../../libraries/configuration/NftConfiguration.sol";

abstract contract BaseAdapter is Initializable {
  using NftConfiguration for DataTypes.NftConfigurationMap;
  using SafeERC20 for IERC20;

  /*//////////////////////////////////////////////////////////////
                          ERRORS
  //////////////////////////////////////////////////////////////*/
  error InvalidZeroAddress();
  error CallerNotPoolAdmin();
  error ReentrantCall();
  error NftNotUsedAsCollateral();
  error InvalidLoanState();
  error InvalidUNftAddress();
  error InactiveNft();
  error InvalidUTokenAddress();
  error InactiveReserve();
  error InactiveUToken();
  error LoanIsHealthy();
  error InsufficientTreasuryBalance();

  /*//////////////////////////////////////////////////////////////
                          CONSTANTS
  //////////////////////////////////////////////////////////////*/
  uint256 internal constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;
  uint256 internal constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  /*//////////////////////////////////////////////////////////////
                          STORAGE
  //////////////////////////////////////////////////////////////*/
  ILendPoolAddressesProvider internal _addressesProvider;

  ILendPool internal _lendPool;

  ILendPoolLoan internal _lendPoolLoan;

  uint256 private _status;

  // Gap for upgradeability
  uint256[20] private __gap;

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
    if (_status == _ENTERED) _revert(ReentrantCall.selector);
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Only poolAdmin can call functions restricted by this modifier.
   */
  modifier onlyPoolAdmin() {
    if (msg.sender != _addressesProvider.getPoolAdmin()) _revert(CallerNotPoolAdmin.selector);
    _;
  }

  /*//////////////////////////////////////////////////////////////
                          INITIALIZATION
  //////////////////////////////////////////////////////////////*/
  /// @custom:oz -upgrades -unsafe -allow constructor
  constructor() initializer {}

  /**
   * @notice Initialize a new Adapter.
   * @param provider The address of the LendPoolAddressesProvider.
   */
  function __BaseAdapter_init(ILendPoolAddressesProvider provider) internal onlyInitializing {
    if (address(provider) == address(0)) revert InvalidZeroAddress();
    _addressesProvider = provider;
    _lendPool = ILendPool(provider.getLendPool());
    _lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    _status = _NOT_ENTERED;
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNALS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Checks the state of the loan, ensuring basic loan data is correct
   * @param nftAsset The address of the NFT to be liquidated
   * @param tokenId The tokenId of the NFT to be liquidated
   **/
  function _performLoanChecks(
    address nftAsset,
    uint256 tokenId
  )
    internal
    view
    returns (
      uint256 loanId,
      DataTypes.LoanData memory loanData,
      address uNftAddress,
      DataTypes.NftConfigurationMap memory nftConfigByTokenId,
      DataTypes.ReserveData memory reserveData
    )
  {
    ILendPool cachedPool = _lendPool;
    ILendPoolLoan cachedPoolLoan = _lendPoolLoan;

    // Ensure loan exists
    loanId = cachedPoolLoan.getCollateralLoanId(nftAsset, tokenId);
    if (loanId == 0) _revert(NftNotUsedAsCollateral.selector);

    // Loan checks
    loanData = cachedPoolLoan.getLoan(loanId);

    if (loanData.state != DataTypes.LoanState.Active && loanData.state != DataTypes.LoanState.Auction)
      _revert(InvalidLoanState.selector);

    // Additional check for individual asset
    nftConfigByTokenId = cachedPool.getNftConfigByTokenId(nftAsset, tokenId);

    if ((nftConfigByTokenId.data & ~ACTIVE_MASK) == 0) _revert(InactiveNft.selector);

    // Reserve data checks
    reserveData = cachedPool.getReserveData(loanData.reserveAsset);

    if ((reserveData.configuration.data & ~ACTIVE_MASK) == 0) _revert(InactiveReserve.selector);

    // Return NFT data
    uNftAddress = cachedPool.getNftData(nftAsset).uNftAddress;
  }

  /**
   * @dev Updates the reserve state calling the lendpool's `updateReserveState`
   **/
  function _updateReserveState(address reserveAsset) internal {
    _lendPool.updateReserveState(reserveAsset);
  }

  /**
   * @dev Updates the reserve interest rates via the lendpool's `updateReserveInterestRates`
   **/
  function _updateReserveInterestRates(address reserveAsset) internal {
    _lendPool.updateReserveInterestRates(reserveAsset);
  }

  /**
   * @dev Ensures the loan to be liquidated is unhealthy
   * @param nftAsset The address of the NFT to be liquidated
   * @param tokenId The tokenId of the NFT to be liquidated
   **/
  function _validateLoanHealthFactor(address nftAsset, uint256 tokenId) internal view {
    (, , , , , uint256 healthFactor) = _lendPool.getNftDebtData(nftAsset, tokenId);

    // Loan must be unhealthy
    if (healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD) _revert(LoanIsHealthy.selector);
  }

  /**
   * @dev Calling `liquidateLoanMarket`, updates the loan state to liquidated and transfers the NFT from the lendpool loan to the adapter
   * @param loanId The ID of the loan
   * @param uNftAddress The uNFT address
   * @param borrowIndex The reserve borrow index
   **/
  function _updateLoanStateAndTransferUnderlying(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowIndex
  ) internal returns (uint256) {
    ILendPoolLoan cachedPoolLoan = _lendPoolLoan;
    (, uint256 borrowAmount) = cachedPoolLoan.getLoanReserveBorrowAmount(loanId);

    cachedPoolLoan.liquidateLoanMarket(loanId, uNftAddress, borrowAmount, borrowIndex);
    return borrowAmount;
  }

  /**
   * @dev Performs the transfers of value to the corresponding recipients
   * @param loanData The data from the specific loan
   * @param borrowAmount The amount borrowed in the loan
   * @param extraDebtAmount The amount generated when liquidation amount cannot cover borrow amount
   * @param remainAmount Difference between the liquidation amount and the borrow amount
   * @param bidFine The loan bid fine
   **/
  function _settleLiquidation(
    DataTypes.LoanData memory loanData,
    address uToken,
    uint256 borrowAmount,
    uint256 extraDebtAmount,
    uint256 remainAmount,
    uint256 bidFine
  ) internal {
    if (extraDebtAmount != 0) {
      // Debt not recovered. Pay extra debt to utoken
      address treasury = IUToken(uToken).RESERVE_TREASURY_ADDRESS();
      if (IERC20(loanData.reserveAsset).balanceOf(treasury) < extraDebtAmount)
        _revert(InsufficientTreasuryBalance.selector);

      IERC20(loanData.reserveAsset).safeTransferFrom(treasury, uToken, extraDebtAmount);
    } else {
      // Debt recovered by liquidation.
      // Transfer borrow amount from adapter to uToken, repay debt
      IERC20(loanData.reserveAsset).safeTransfer(uToken, borrowAmount);
    }

    if (loanData.bidderAddress != address(0)) {
      // Transfer bid amount to the loan bidder
      _lendPool.transferBidAmount(loanData.reserveAsset, loanData.bidderAddress, loanData.bidPrice);
    }

    if (remainAmount > bidFine) {
      // already considering  case where remaining amount is 0
      // Remain amount can cover bid fine.
      // Transfer bid fine to first bidder
      IERC20(loanData.reserveAsset).safeTransfer(loanData.firstBidderAddress, bidFine);
      unchecked {
        remainAmount -= bidFine;
      }
      // Transfer remaining amount to borrower
      IERC20(loanData.reserveAsset).safeTransfer(loanData.borrower, remainAmount);
    } else {
      // Remain amount can not cover bid fine. Transfer the remaining amount to first bidder
      IERC20(loanData.reserveAsset).safeTransfer(loanData.firstBidderAddress, remainAmount);
    }
  }

  /**
   * @dev Cancels the debt listing if exist
   * @param nftAsset The address of the NFT to be liquidated
   * @param tokenId The tokenId of the NFT to be liquidated
   **/
  function _cancelDebtListing(address nftAsset, uint256 tokenId) internal {
    // Cancel debt listing if exist
    address debtMarket = _addressesProvider.getAddress(keccak256("DEBT_MARKET"));
    if (IDebtMarket(debtMarket).getDebtId(nftAsset, tokenId) != 0) {
      IDebtMarket(debtMarket).cancelDebtListing(nftAsset, tokenId);
    }
  }

  /**
   * @dev Perform more efficient reverts
   */
  function _revert(bytes4 errorSelector) internal pure {
    //solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(0x00, errorSelector)
      revert(0x00, 0x04)
    }
  }

  /*//////////////////////////////////////////////////////////////
                  ERC721RECEIVER FUNCTION
  //////////////////////////////////////////////////////////////*/

  function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}