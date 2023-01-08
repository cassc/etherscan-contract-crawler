// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { DiamondExtension } from "../midas/DiamondExtension.sol";
import { ComptrollerErrorReporter } from "../compound/ErrorReporter.sol";
import { CTokenInterface, CErc20Interface } from "./CTokenInterfaces.sol";
import { ComptrollerV3Storage } from "./ComptrollerStorage.sol";

contract ComptrollerFirstExtension is DiamondExtension, ComptrollerV3Storage, ComptrollerErrorReporter {
  /// @notice Emitted when supply cap for a cToken is changed
  event NewSupplyCap(CTokenInterface indexed cToken, uint256 newSupplyCap);

  /// @notice Emitted when borrow cap for a cToken is changed
  event NewBorrowCap(CTokenInterface indexed cToken, uint256 newBorrowCap);

  /// @notice Emitted when borrow cap guardian is changed
  event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

  /// @notice Emitted when pause guardian is changed
  event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

  /// @notice Emitted when an action is paused globally
  event ActionPaused(string action, bool pauseState);

  /// @notice Emitted when an action is paused on a market
  event MarketActionPaused(CTokenInterface cToken, string action, bool pauseState);

  /// @notice Emitted when an admin unsupports a market
  event MarketUnlisted(CTokenInterface cToken);

  /**
   * @notice Returns true if the accruing flyhwheel was found and replaced
   * @dev Adds a flywheel to the non-accruing list and if already in the accruing, removes it from that list
   * @param flywheelAddress The address of the flywheel to add to the non-accruing
   */
  function addNonAccruingFlywheel(address flywheelAddress) external returns (bool) {
    require(hasAdminRights(), "!admin");
    require(flywheelAddress != address(0), "!flywheel");

    for (uint256 i = 0; i < nonAccruingRewardsDistributors.length; i++) {
      require(flywheelAddress != nonAccruingRewardsDistributors[i], "!alreadyadded");
    }

    // add it to the non-accruing
    nonAccruingRewardsDistributors.push(flywheelAddress);

    // remove it from the accruing
    for (uint256 i = 0; i < rewardsDistributors.length; i++) {
      if (flywheelAddress == rewardsDistributors[i]) {
        rewardsDistributors[i] = rewardsDistributors[rewardsDistributors.length - 1];
        rewardsDistributors.pop();
        return true;
      }
    }

    return false;
  }

  /**
   * @notice Set the given supply caps for the given cToken markets. Supplying that brings total underlying supply to or above supply cap will revert.
   * @dev Admin or borrowCapGuardian function to set the supply caps. A supply cap of 0 corresponds to unlimited supplying.
   * @param cTokens The addresses of the markets (tokens) to change the supply caps for
   * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited supplying.
   */
  function _setMarketSupplyCaps(CTokenInterface[] calldata cTokens, uint256[] calldata newSupplyCaps) external {
    require(msg.sender == admin || msg.sender == borrowCapGuardian, "!admin");

    uint256 numMarkets = cTokens.length;
    uint256 numSupplyCaps = newSupplyCaps.length;

    require(numMarkets != 0 && numMarkets == numSupplyCaps, "!input");

    for (uint256 i = 0; i < numMarkets; i++) {
      supplyCaps[address(cTokens[i])] = newSupplyCaps[i];
      emit NewSupplyCap(cTokens[i], newSupplyCaps[i]);
    }
  }

  /**
   * @notice Set the given borrow caps for the given cToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
   * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
   * @param cTokens The addresses of the markets (tokens) to change the borrow caps for
   * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
   */
  function _setMarketBorrowCaps(CTokenInterface[] calldata cTokens, uint256[] calldata newBorrowCaps) external {
    require(msg.sender == admin || msg.sender == borrowCapGuardian, "!admin");

    uint256 numMarkets = cTokens.length;
    uint256 numBorrowCaps = newBorrowCaps.length;

    require(numMarkets != 0 && numMarkets == numBorrowCaps, "!input");

    for (uint256 i = 0; i < numMarkets; i++) {
      borrowCaps[address(cTokens[i])] = newBorrowCaps[i];
      emit NewBorrowCap(cTokens[i], newBorrowCaps[i]);
    }
  }

  /**
   * @notice Admin function to change the Borrow Cap Guardian
   * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
   */
  function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
    require(msg.sender == admin, "!admin");

    // Save current value for inclusion in log
    address oldBorrowCapGuardian = borrowCapGuardian;

    // Store borrowCapGuardian with value newBorrowCapGuardian
    borrowCapGuardian = newBorrowCapGuardian;

    // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
    emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
  }

  /**
   * @notice Admin function to change the Pause Guardian
   * @param newPauseGuardian The address of the new Pause Guardian
   * @return uint 0=success, otherwise a failure. (See enum Error for details)
   */
  function _setPauseGuardian(address newPauseGuardian) public returns (uint256) {
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
    }

    // Save current value for inclusion in log
    address oldPauseGuardian = pauseGuardian;

    // Store pauseGuardian with value newPauseGuardian
    pauseGuardian = newPauseGuardian;

    // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
    emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

    return uint256(Error.NO_ERROR);
  }

  function _setMintPaused(CTokenInterface cToken, bool state) public returns (bool) {
    require(markets[address(cToken)].isListed, "!market");
    require(msg.sender == pauseGuardian || hasAdminRights(), "!gaurdian");
    require(hasAdminRights() || state == true, "!admin");

    mintGuardianPaused[address(cToken)] = state;
    emit MarketActionPaused(cToken, "Mint", state);
    return state;
  }

  function _setBorrowPaused(CTokenInterface cToken, bool state) public returns (bool) {
    require(markets[address(cToken)].isListed, "!market");
    require(msg.sender == pauseGuardian || hasAdminRights(), "!guardian");
    require(hasAdminRights() || state == true, "!admin");

    borrowGuardianPaused[address(cToken)] = state;
    emit MarketActionPaused(cToken, "Borrow", state);
    return state;
  }

  function _setTransferPaused(bool state) public returns (bool) {
    require(msg.sender == pauseGuardian || hasAdminRights(), "!guardian");
    require(hasAdminRights() || state == true, "!admin");

    transferGuardianPaused = state;
    emit ActionPaused("Transfer", state);
    return state;
  }

  function _setSeizePaused(bool state) public returns (bool) {
    require(msg.sender == pauseGuardian || hasAdminRights(), "!guardian");
    require(hasAdminRights() || state == true, "!admin");

    seizeGuardianPaused = state;
    emit ActionPaused("Seize", state);
    return state;
  }

  /**
   * @notice Removed a market from the markets mapping and sets it as unlisted
   * @dev Admin function unset isListed and collateralFactorMantissa and unadd support for the market
   * @param cToken The address of the market (token) to unlist
   * @return uint 0=success, otherwise a failure. (See enum Error for details)
   */
  function _unsupportMarket(CTokenInterface cToken) external returns (uint256) {
    // Check admin rights
    if (!hasAdminRights()) return fail(Error.UNAUTHORIZED, FailureInfo.UNSUPPORT_MARKET_OWNER_CHECK);

    // Check if market is already unlisted
    if (!markets[address(cToken)].isListed)
      return fail(Error.MARKET_NOT_LISTED, FailureInfo.UNSUPPORT_MARKET_DOES_NOT_EXIST);

    // Check if market is in use
    if (cToken.totalSupply() > 0) return fail(Error.NONZERO_TOTAL_SUPPLY, FailureInfo.UNSUPPORT_MARKET_IN_USE);

    // Unlist market
    delete markets[address(cToken)];

    /* Delete cToken from allMarkets */
    // load into memory for faster iteration
    CTokenInterface[] memory _allMarkets = allMarkets;
    uint256 len = _allMarkets.length;
    uint256 assetIndex = len;
    for (uint256 i = 0; i < len; i++) {
      if (_allMarkets[i] == cToken) {
        assetIndex = i;
        break;
      }
    }

    // We *must* have found the asset in the list or our redundant data structure is broken
    assert(assetIndex < len);

    // copy last item in list to location of item to be removed, reduce length by 1
    allMarkets[assetIndex] = allMarkets[allMarkets.length - 1];
    allMarkets.pop();

    cTokensByUnderlying[CErc20Interface(address(cToken)).underlying()] = CTokenInterface(address(0));
    emit MarketUnlisted(cToken);

    return uint256(Error.NO_ERROR);
  }

  function _setBorrowCapForAssetForCollateral(
    address cTokenBorrow,
    address cTokenCollateral,
    uint256 borrowCap
  ) public {
    require(hasAdminRights(), "!admin");
    borrowCapForAssetForCollateral[cTokenBorrow][cTokenCollateral] = borrowCap;
  }

  function _blacklistBorrowingAgainstCollateral(
    address cTokenBorrow,
    address cTokenCollateral,
    bool blacklisted
  ) public {
    require(hasAdminRights(), "!admin");
    borrowingAgainstCollateralBlacklist[cTokenBorrow][cTokenCollateral] = blacklisted;
    borrowCapForAssetForCollateral[cTokenBorrow][cTokenCollateral] = 0;
  }

  function _getExtensionFunctions() external view virtual override returns (bytes4[] memory) {
    uint8 fnsCount = 19;
    bytes4[] memory functionSelectors = new bytes4[](fnsCount);
    functionSelectors[--fnsCount] = this.addNonAccruingFlywheel.selector;
    functionSelectors[--fnsCount] = this._setMarketSupplyCaps.selector;
    functionSelectors[--fnsCount] = this._setMarketBorrowCaps.selector;
    functionSelectors[--fnsCount] = this._setBorrowCapGuardian.selector;
    functionSelectors[--fnsCount] = this._setPauseGuardian.selector;
    functionSelectors[--fnsCount] = this._setMintPaused.selector;
    functionSelectors[--fnsCount] = this._setBorrowPaused.selector;
    functionSelectors[--fnsCount] = this._setTransferPaused.selector;
    functionSelectors[--fnsCount] = this._setSeizePaused.selector;
    functionSelectors[--fnsCount] = this._unsupportMarket.selector;
    functionSelectors[--fnsCount] = this.getAllMarkets.selector;
    functionSelectors[--fnsCount] = this.getAllBorrowers.selector;
    functionSelectors[--fnsCount] = this.getWhitelist.selector;
    functionSelectors[--fnsCount] = this.getRewardsDistributors.selector;
    functionSelectors[--fnsCount] = this.isUserOfPool.selector;
    functionSelectors[--fnsCount] = this.getAccruingFlywheels.selector;
    functionSelectors[--fnsCount] = this._removeFlywheel.selector;
    functionSelectors[--fnsCount] = this._setBorrowCapForAssetForCollateral.selector;
    functionSelectors[--fnsCount] = this._blacklistBorrowingAgainstCollateral.selector;
    require(fnsCount == 0, "use the correct array length");
    return functionSelectors;
  }

  /**
   * @notice Return all of the markets
   * @dev The automatic getter may be used to access an individual market.
   * @return The list of market addresses
   */
  function getAllMarkets() public view returns (CTokenInterface[] memory) {
    return allMarkets;
  }

  /**
   * @notice Return all of the borrowers
   * @dev The automatic getter may be used to access an individual borrower.
   * @return The list of borrower account addresses
   */
  function getAllBorrowers() public view returns (address[] memory) {
    return allBorrowers;
  }

  /**
   * @notice Return all of the whitelist
   * @dev The automatic getter may be used to access an individual whitelist status.
   * @return The list of borrower account addresses
   */
  function getWhitelist() external view returns (address[] memory) {
    return whitelistArray;
  }

  /**
   * @notice Returns an array of all accruing and non-accruing flywheels
   */
  function getRewardsDistributors() external view returns (address[] memory) {
    address[] memory allFlywheels = new address[](rewardsDistributors.length + nonAccruingRewardsDistributors.length);

    uint8 i = 0;
    while (i < rewardsDistributors.length) {
      allFlywheels[i] = rewardsDistributors[i];
      i++;
    }
    uint8 j = 0;
    while (j < nonAccruingRewardsDistributors.length) {
      allFlywheels[i + j] = nonAccruingRewardsDistributors[j];
      j++;
    }

    return allFlywheels;
  }

  function getAccruingFlywheels() external view returns (address[] memory) {
    return rewardsDistributors;
  }

  /**
   * @dev Removes a flywheel from the accruing or non-accruing array
   * @param flywheelAddress The address of the flywheel to remove from the accruing or non-accruing array
   * @return true if the flywheel was found and removed
   */
  function _removeFlywheel(address flywheelAddress) external returns (bool) {
    require(hasAdminRights(), "!admin");
    require(flywheelAddress != address(0), "!flywheel");

    // remove it from the accruing
    for (uint256 i = 0; i < rewardsDistributors.length; i++) {
      if (flywheelAddress == rewardsDistributors[i]) {
        rewardsDistributors[i] = rewardsDistributors[rewardsDistributors.length - 1];
        rewardsDistributors.pop();
        return true;
      }
    }

    // or remove it from the non-accruing
    for (uint256 i = 0; i < nonAccruingRewardsDistributors.length; i++) {
      if (flywheelAddress == nonAccruingRewardsDistributors[i]) {
        nonAccruingRewardsDistributors[i] = nonAccruingRewardsDistributors[nonAccruingRewardsDistributors.length - 1];
        nonAccruingRewardsDistributors.pop();
        return true;
      }
    }

    return false;
  }

  function isUserOfPool(address user) external view returns (bool) {
    for (uint256 i = 0; i < allMarkets.length; i++) {
      address marketAddress = address(allMarkets[i]);
      if (markets[marketAddress].accountMembership[user]) {
        return true;
      }
    }

    return false;
  }
}