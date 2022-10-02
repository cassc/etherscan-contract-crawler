pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./MtrollerCommon.sol";
import "./MTokenInterfaces.sol";
import "./Mmo.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

/**
 * @title Based on Compound's Mtroller Contract, with some modifications
 * @dev This contract must not declare any variables. All required storage must be inherited from MtrollerCommon
 * @author Compound, mmo.finance
 */
contract MtrollerAdmin is MtrollerCommon, MtrollerAdminInterface {

    /**
     * @notice Constructs a new MtrollerAdmin
     */
    constructor() public MtrollerCommon() {
        implementedSelectors.push(bytes4(keccak256('isMDelegatorAdminImplementation()')));
        implementedSelectors.push(bytes4(keccak256('initialize(address,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_supportMarket(uint240)')));
        implementedSelectors.push(bytes4(keccak256('_setPriceOracle(address)')));
        implementedSelectors.push(bytes4(keccak256('_setCloseFactor(uint256)')));
        implementedSelectors.push(bytes4(keccak256('_setLiquidationIncentive(uint256)')));
        implementedSelectors.push(bytes4(keccak256('_setMaxAssets(uint256)')));
        implementedSelectors.push(bytes4(keccak256('_setBorrowCapGuardian(address)')));
        implementedSelectors.push(bytes4(keccak256('_setMarketBorrowCaps(uint240[],uint256[])')));
        implementedSelectors.push(bytes4(keccak256('_setPauseGuardian(address)')));
        implementedSelectors.push(bytes4(keccak256('_setAuctionPaused(uint240,bool)')));
        implementedSelectors.push(bytes4(keccak256('_setMintPaused(uint240,bool)')));
        implementedSelectors.push(bytes4(keccak256('_setBorrowPaused(uint240,bool)')));
        implementedSelectors.push(bytes4(keccak256('_setTransferPaused(uint240,bool)')));
        implementedSelectors.push(bytes4(keccak256('_setSeizePaused(uint240,bool)')));
    }

    /**
     * @notice Returns the type of implementation for this contract
     */
    function isMDelegatorAdminImplementation() public pure returns (bool) {
        return true;
    }

    /**
     * @notice Initializes a new Mtroller
     * @param _mmoTokenAddress The address of the mmo token
     * @param _maxAssets The maximum number of assets an account can be "in" at any time. This has
     * to be limited to some low number (e.g. <= 50?) to avoid liquidity calculation running into
     * the block gas limit.
     */
    function initialize(address _mmoTokenAddress, uint _maxAssets) public {
        require(msg.sender == getAdmin(), "only admin");
        require(mmoTokenAddress == address(0) && _mmoTokenAddress != address(0), "invalid initialization");
        mmoTokenAddress = _mmoTokenAddress;
        maxAssets = _maxAssets;
    }

    /*** Admin Functions ***/

    /**
      * @notice Add the mToken market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param mToken The mToken market to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(uint240 mToken) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }
        return _supportMarketInternal(mToken);
    }

    /**
      * @notice Sets a new price oracle for the mtroller
      * @dev Admin function to set a new price oracle
      * @param newOracle The new price oracle to be used
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(PriceOracle newOracle) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the mtroller
        PriceOracle oldOracle = oracle;

        // Set mtroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        if (newCloseFactorMantissa < closeFactorMinMantissa || newCloseFactorMantissa > closeFactorMaxMantissa) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18. The amount of
      * seized tokens the liquidator receives as compensation for repaying the borrower's borrow, 
      * relative to market value. For example, a value of 1e18 means no liquidation incentive, 
      * and a value of 1.1e18 means 10% additional tokens as liquidation incentive.
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        if (newLiquidationIncentiveMantissa < liquidationIncentiveMinMantissa || newLiquidationIncentiveMantissa > liquidationIncentiveMaxMantissa) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Set the given borrow caps for the given mToken markets. Borrowing that brings total 
      * borrows to or above borrow cap will revert.
      * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds 
      * to unlimited borrowing.
      * @param mTokens The mToken markets to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds 
      * to unlimited borrowing.
      */
    function _setMarketBorrowCaps(uint240[] calldata mTokens, uint[] calldata newBorrowCaps) external {
    	require(msg.sender == getAdmin() || msg.sender == borrowCapGuardian, "only admin or borrow cap guardian can set borrow caps"); 

        uint numMarkets = mTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[mTokens[i]] = newBorrowCaps[i];
            emit NewBorrowCap(mTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the maximum number of assets (i.e., different mToken IDs) 
     * that a single account can hold at any one time
     * @param newMaxAssets The new maximum number of assets 
     */
    function _setMaxAssets(uint newMaxAssets) external {
        require(msg.sender == getAdmin(), "only admin can set maxAssets");

        // Save current value for inclusion in log
        uint oldMaxAssets = maxAssets;

        // Store maxAssets with value newMaxAssets
        maxAssets = newMaxAssets;

        // Emit NewMaxAssets(oldMaxAssets, newMaxAssets)
        emit NewMaxAssets(oldMaxAssets, newMaxAssets);
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == getAdmin(), "only admin can set borrow cap guardian");

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
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _setAuctionPaused(uint240 mToken, bool state) public returns (bool) {
        require(isListed(mToken), "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        auctionGuardianPaused[mToken] = state;
        emit ActionPaused(mToken, "Auction", state);
        return state;
    }

    function _setMintPaused(uint240 mToken, bool state) public returns (bool) {
        require(isListed(mToken), "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        mintGuardianPaused[mToken] = state;
        emit ActionPaused(mToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(uint240 mToken, bool state) public returns (bool) {
        require(isListed(mToken), "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        borrowGuardianPaused[mToken] = state;
        emit ActionPaused(mToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(uint240 mToken, bool state) public returns (bool) {
        require(isListed(mToken), "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        transferGuardianPaused[mToken] = state;
        emit ActionPaused(mToken, "Transfer", state);
        return state;
    }

    function _setSeizePaused(uint240 mToken, bool state) public returns (bool) {
        require(isListed(mToken), "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        seizeGuardianPaused[mToken] = state;
        emit ActionPaused(mToken, "Seize", state);
        return state;
    }
}

contract MtrollerInterfaceFull is MtrollerAdmin, MtrollerInterface {}