// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseOptionsVault} from "./BaseOptionsVault.sol";

// interfaces
import {IMarginEnginePhysical} from "../../../../interfaces/IMarginEngine.sol";
import {IPhysicalReturnProcessor} from "../../../../interfaces/IPhysicalReturnProcessor.sol";

// libraries
import {StructureLib} from "../../../../libraries/StructureLib.sol";

import "../../../../config/constants.sol";
import "../../../../config/errors.sol";
import "../../../../config/types.sol";

abstract contract PhysicalOptionsVault is BaseOptionsVault {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice marginAccount is the options protocol collateral pool
    IMarginEnginePhysical public immutable marginEngine;

    /*///////////////////////////////////////////////////////////////
                        Storage V1
    //////////////////////////////////////////////////////////////*/
    /// @notice Window to exercise long options
    uint256 public exerciseWindow;

    address public returnProcessor;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[23] private __gap;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event ExerciseWindowSet(uint256 exerciseWindow, uint256 newExerciseWindow);

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _share, address _marginEngine) BaseOptionsVault(_share) {
        if (_marginEngine == address(0)) revert BadAddress();

        marginEngine = IMarginEnginePhysical(_marginEngine);
    }

    function __PhysicalOptionsVault_init(InitParams calldata _initParams, address _auction, uint256 _exerciseWindow)
        internal
        onlyInitializing
    {
        __OptionsVault_init(_initParams, _auction);

        if (_exerciseWindow == 0) revert POV_BadExerciseWindow();

        exerciseWindow = _exerciseWindow;
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    function setExerciseWindow(uint256 _exerciseWindow) external {
        _onlyOwner();

        if (_exerciseWindow == 0 || _exerciseWindow > type(uint64).max) revert POV_BadExerciseWindow();

        if (roundExpiry[vaultState.round] > block.timestamp + exerciseWindow) revert POV_OptionNotExpired();

        emit ExerciseWindowSet(exerciseWindow, _exerciseWindow);

        exerciseWindow = _exerciseWindow;
    }

    function requestWithdraw(uint256 _numShares) external virtual override {
        if (roundExpiry[vaultState.round] > block.timestamp + exerciseWindow) revert POV_OptionNotExpired();

        (,, Balance[] memory marginCollaterals) = marginEngine.marginAccounts(address(this));

        bool isFullyExercised = marginCollaterals.length == 1 && marginCollaterals[0].collateralId != collaterals[0].id;

        if (marginCollaterals.length > 1 || isFullyExercised) revert POV_CannotRequestWithdraw();

        _requestWithdraw(_numShares);
    }

    /**
     * @notice transfers asset from the margin account to depositors based on their shares and burns the shares
     * @dev called when vault gets put into the money
     *      only supports single asset structures
     *      assumes all depositors passed in have ownership in vault
     * @param _returnProcessor contract to perform airdrop
     * @param _depositors array of depositors to receive the underlying
     */
    function returnOnExercise(address _returnProcessor, address[] calldata _depositors) external virtual {
        _onlyOwner();

        if (_returnProcessor != address(0) && returnProcessor != _returnProcessor) returnProcessor = _returnProcessor;

        if (_depositors.length > 0) {
            marginEngine.setAccountAccess(returnProcessor, type(uint256).max);

            IPhysicalReturnProcessor(returnProcessor).returnOnExercise(_depositors);

            marginEngine.setAccountAccess(returnProcessor, 0);
        }
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @dev    called by depositor or returnProcessor
     * @param _depositor is the address of the depositor
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function redeemFor(address _depositor, uint256 _numShares, bool _isMax) external override {
        if (_depositor != msg.sender && msg.sender != returnProcessor) revert Unauthorized();

        _redeem(_depositor, _numShares, _isMax);
    }

    /**
     * @notice Burns shares that are owed to a depositor
     * @dev    called by returnProcessor, cannot burn vault shares
     * @param _depositor is the address of the depositor
     * @param _sharesToWithdraw is the number of shares to burn
     */
    function burnSharesFor(address _depositor, uint256 _sharesToWithdraw) external {
        if (msg.sender != returnProcessor || _depositor == address(this)) revert Unauthorized();

        share.burn(_depositor, _sharesToWithdraw);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal function overrides
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Settles the existing option(s)
     */
    function _beforeCloseRound() internal virtual override {
        VaultState memory vState = vaultState;

        if (vState.round == 1) return;

        uint256 currentExpiry = roundExpiry[vState.round];

        if (currentExpiry <= PLACEHOLDER_UINT) revert OV_RoundClosed();

        if (currentExpiry > block.timestamp) {
            if (vState.totalPending == 0) revert OV_NoCollateralPending();
        } else {
            (Position[] memory shorts, Position[] memory longs, Balance[] memory marginCollaterals) =
                marginEngine.marginAccounts(address(this));

            // last round got fully exercised and exitOnExercise has happened
            if (marginCollaterals.length == 0) return;

            // last round got exercised so collateral does not match deposit, needs to be withdrawn first
            if (marginCollaterals[0].collateralId != collaterals[0].id) revert OV_VaultExercised();

            // last round got partially exercised then exitOnExercise has happened
            if (marginCollaterals[0].amount < vaultState.lockedAmount) return;

            if (shorts.length == 0 && longs.length == 0) revert OV_RoundClosed();

            _settleOptions();
        }
    }

    function _getMarginAccount()
        internal
        view
        virtual
        override
        returns (Position[] memory, Position[] memory, Balance[] memory)
    {
        return marginEngine.marginAccounts(address(this));
    }

    function _marginEngineAddr() internal view virtual override returns (address) {
        return address(marginEngine);
    }

    function _setAuctionMarginAccountAccess(uint256 _allowedExecutions) internal virtual override {
        marginEngine.setAccountAccess(auction, _allowedExecutions);
    }

    function _settleOptions() internal virtual override {
        StructureLib.settleOptions(marginEngine);
    }

    function _withdrawCollateral(Collateral[] memory _collaterals, uint256[] memory _amounts, address _recipient)
        internal
        virtual
        override
    {
        StructureLib.withdrawCollaterals(marginEngine, _collaterals, _amounts, _recipient);
    }

    function _depositCollateral(Collateral[] memory _collaterals) internal override {
        StructureLib.depositCollateral(marginEngine, _collaterals);
    }

    function _withdrawWithShares(uint256 _totalSupply, uint256 _shares, address _pauser)
        internal
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return StructureLib.withdrawWithShares(marginEngine, _totalSupply, _shares, _pauser);
    }
}