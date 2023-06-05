// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseVault} from "../../BaseVault.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IAuctionVault} from "../../../../interfaces/IAuctionVault.sol";
import {IPositionPauser} from "../../../../interfaces/IPositionPauser.sol";

// libraries
import {FeeLib} from "../../../../libraries/FeeLib.sol";
import {StructureLib} from "../../../../libraries/StructureLib.sol";
import {VaultLib} from "../../../../libraries/VaultLib.sol";

import "../../../../config/errors.sol";
import "../../../../config/constants.sol";
import "../../../../config/types.sol";

abstract contract BaseOptionsVault is BaseVault, IAuctionVault {
    /*///////////////////////////////////////////////////////////////
                        Storage V1
    //////////////////////////////////////////////////////////////*/
    // auction contract
    address public auction;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[24] private __gap;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event AuctionSet(address auction, address newAuction);

    event MarginAccountAccessSet(address auction, uint256 allowedExecutions);

    event StagedAuction(uint256 indexed expiry, uint32 round);

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     */
    constructor(address _share) BaseVault(_share) {}

    function __OptionsVault_init(InitParams calldata _initParams, address _auction) internal onlyInitializing {
        __BaseVault_init(_initParams);

        // verifies that initial collaterals are present
        StructureLib.verifyInitialCollaterals(_initParams._collaterals);

        if (_auction == address(0)) revert BadAddress();

        auction = _auction;
    }

    /*///////////////////////////////////////////////////////////////
                                Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new batch auction address
     * @param _auction is the auction duration address
     */
    function setAuction(address _auction) external {
        _onlyOwner();

        if (_auction == address(0)) revert BadAddress();

        emit AuctionSet(auction, _auction);

        auction = _auction;
    }

    /**
     * @notice Sets the auction allowable executions on the margin account
     * @param _allowedExecutions how many times the account is authorized to update vault account.
     *        set to max(uint256) to allow unlimited access
     */
    function setAuctionMarginAccountAccess(uint256 _allowedExecutions) external {
        _onlyManager();

        emit MarginAccountAccessSet(auction, _allowedExecutions);

        _setAuctionMarginAccountAccess(_allowedExecutions);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the amount of collateral to use in the next auction
     * @dev performing asset requirements off-chain to save gas fees
     */
    function stageAuction() external {
        _onlyManager();

        uint256 expiry = _setRoundExpiry();

        _setAuctionMarginAccountAccess(type(uint256).max);

        emit StagedAuction(expiry, vaultState.round);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal function to override
    //////////////////////////////////////////////////////////////*/

    function _marginEngineAddr() internal view virtual returns (address) {}

    function _getMarginAccount() internal view virtual returns (Position[] memory, Position[] memory, Balance[] memory) {}

    function _setAuctionMarginAccountAccess(uint256 _allowedExecutions) internal virtual {}

    function _settleOptions() internal virtual {}

    function _withdrawCollateral(Collateral[] memory _collaterals, uint256[] memory _amounts, address _recipient)
        internal
        virtual
    {}

    function _depositCollateral(Collateral[] memory _collaterals) internal virtual {}

    function _withdrawWithShares(uint256 _totalSupply, uint256 _shares, address _pauser)
        internal
        virtual
        returns (uint256[] memory amounts)
    {}

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
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
            (Position[] memory shorts, Position[] memory longs,) = _getMarginAccount();

            if (shorts.length == 0 && longs.length == 0) revert OV_RoundClosed();

            _settleOptions();
        }
    }

    /**
     * @notice Sets the next options expiry
     */
    function _setRoundExpiry() internal virtual returns (uint256 newExpiry) {
        uint256 currentRound = vaultState.round;

        if (currentRound == 1) revert OV_BadRound();

        uint256 currentExpiry = roundExpiry[currentRound];
        newExpiry = VaultLib.getNextExpiry(roundConfig);

        if (PLACEHOLDER_UINT < currentExpiry && currentExpiry < newExpiry) {
            (Position[] memory shorts, Position[] memory longs,) = _getMarginAccount();

            if (shorts.length > 0 || longs.length > 0) revert OV_ActiveRound();
        }

        roundExpiry[currentRound] = newExpiry;
    }

    function _processFees(uint256[] memory _balances, uint256 _currentRound)
        internal
        virtual
        override
        returns (uint256[] memory balances)
    {
        uint256[] memory totalFees;

        VaultDetails memory vaultDetails =
            VaultDetails(collaterals, roundStartingBalances[_currentRound], _balances, vaultState.totalPending);

        (totalFees, balances) = FeeLib.processFees(vaultDetails, managementFee, performanceFee);

        _withdrawCollateral(collaterals, totalFees, feeRecipient);

        emit CollectedFees(totalFees, _currentRound, feeRecipient);
    }

    function _rollInFunds(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry) internal override {
        super._rollInFunds(_balances, _currentRound, _expiry);

        _depositCollateral(collaterals);
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal virtual override returns (uint256) {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        uint256[] memory withdrawAmounts = new uint256[](1);

        if (withdrawShares > 0) {
            vaultState.queuedWithdrawShares = 0;

            withdrawAmounts = _withdrawWithShares(share.totalSupply(address(this)), withdrawShares, pauser);

            // recording deposits with pauser for past round
            IPositionPauser(pauser).processVaultWithdraw(withdrawAmounts);

            // burns shares that were transferred to vault during requestWithdraw
            share.burn(address(this), withdrawShares);

            emit Withdrew(msg.sender, withdrawAmounts, withdrawShares);
        }

        return withdrawAmounts[0];
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in _processFees, _rollInFunds and lockedAmount (in a rolling close)
     */
    function _getCurrentBalances() internal view virtual override returns (uint256[] memory balances) {
        (,, Balance[] memory marginCollaterals) = _getMarginAccount();

        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            if (marginCollaterals.length > i) balances[i] += marginCollaterals[i].amount;

            unchecked {
                ++i;
            }
        }
    }
}