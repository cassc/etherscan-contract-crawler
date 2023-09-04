// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

import {IHashnoteVault} from "../interfaces/IHashnoteVault.sol";
import {IHNT20} from "../interfaces/IHNT20.sol";
import {IPositionPauser} from "../interfaces/IPositionPauser.sol";
import {IVaultShare} from "../interfaces/IVaultShare.sol";
import {IWhitelistManager} from "../interfaces/IWhitelistManager.sol";

import "../config/constants.sol";
import "../config/types.sol";
import "../config/errors.sol";

contract Registrar is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IHNT20;

    /// the erc1155 contract that issues vault shares
    IVaultShare public immutable share;

    // Whitelist manager
    IWhitelistManager public immutable whitelist;

    /*///////////////////////////////////////////////////////////////
                            State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @notice Stores vault user's deposits
    mapping(address => mapping(address => DepositReceipt)) public depositReceipts;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed vault, address indexed account, uint256[] amounts, uint256 round);

    event QuickWithdrew(address indexed vault, address indexed account, uint256[] amounts, uint256 round);

    event RequestedWithdraw(address indexed vault, address indexed account, uint256 shares, uint256 round);

    event Redeem(address indexed vault, address indexed account, uint256 share, uint256 round);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _share, address _whitelist) {
        if (_share == address(0)) revert BadAddress();
        if (_whitelist == address(0)) revert BadAddress();

        share = IVaultShare(_share);
        whitelist = IWhitelistManager(_whitelist);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        _transferOwnership(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from address added to `_subAccount`'s deposit
     * @dev this function will only work for single asset collaterals
     * @param _vault is the address of the vault to deposit to
     * @param _from is the address to pull the assets from
     * @param _amount is the amount of primary asset to deposit
     * @param _subAccount is the address that can claim/withdraw deposited amount
     * @param _v is the v param of the signature
     * @param _r is the r param of the signature
     * @param _s is the s param of the signature
     */
    function depositFrom(address _vault, address _from, uint256 _amount, address _subAccount, uint8 _v, bytes32 _r, bytes32 _s)
        external
        nonReentrant
    {
        if (_subAccount == address(0)) _subAccount = msg.sender;

        if (msg.sender != _from) _onlyManager(_vault);

        _migratePrecheck(_vault, _subAccount);

        IHashnoteVault vault = IHashnoteVault(_vault);

        if (_v != 0 && _r.length != 0 && _s.length != 0) {
            IHNT20(vault.collaterals(0).addr).permit(_from, address(this), type(uint256).max, type(uint256).max, _v, _r, _s);
        }

        uint256 round = _depositFor(vault, _subAccount, _amount);
        uint256[] memory amounts = _transferAssets(vault, _from, _amount, _vault, round);

        emit Deposited(_vault, _subAccount, amounts, round);
    }

    /**
     * @notice Deposits the `asset` from address added to `_subAccount`'s deposit
     * @dev this function supports multiple collaterals
     * @param _vault is the address of the vault to deposit to
     * @param _from is the address to pull the assets from
     * @param _amount is the amount of primary asset to deposit
     * @param _subAccount is the address that can claim/withdraw deposited amount
     * @param _v is the v params of the signature (array)
     * @param _r is the r params of the signature (array)
     * @param _s is the s params of the signature (array)
     */
    function depositFrom(
        address _vault,
        address _from,
        uint256 _amount,
        address _subAccount,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) external nonReentrant {
        if (_subAccount == address(0)) _subAccount = msg.sender;

        if (msg.sender != _from) _onlyManager(_vault);

        _migratePrecheck(_vault, _subAccount);

        IHashnoteVault vault = IHashnoteVault(_vault);
        Collateral[] memory collats = vault.getCollaterals();

        for (uint256 i; i < collats.length;) {
            if (_v[i] != 0 && _r[i].length != 0 && _s[i].length != 0) {
                IHNT20(collats[i].addr).permit(_from, address(this), type(uint256).max, type(uint256).max, _v[i], _r[i], _s[i]);
            }

            unchecked {
                ++i;
            }
        }

        uint256 round = _depositFor(vault, _subAccount, _amount);
        uint256[] memory amounts = _transferAssets(vault, _from, _amount, _vault, round);

        emit Deposited(_vault, _subAccount, amounts, round);
    }

    /**
     * @notice Withdraws the assets of the vault using the outstanding `DepositReceipt.amount`
     * @dev only pending funds can be withdrawn using this method
     * @param _vault is the address of the vault
     * @param _subAccount is the address of the sub account
     * @param _amount is the pending amount of primary asset to be withdrawn
     */
    function quickWithdrawFor(address _vault, address _subAccount, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert REG_BadAmount();
        if (msg.sender != _subAccount) _onlyManager(_vault);
        _validateWhitelisted(_subAccount);

        _migratePrecheck(_vault, _subAccount);

        IHashnoteVault vault = IHashnoteVault(_vault);
        uint256 currentRound = vault.vaultState().round;

        DepositReceipt storage depositReceipt = depositReceipts[_vault][_subAccount];
        if (depositReceipt.round != currentRound) revert REG_BadRound();

        uint96 receiptAmount = depositReceipt.amount;
        if (_amount > receiptAmount) revert REG_BadAmount();

        // amount is within uin96 based on above less-than check
        depositReceipt.amount = receiptAmount - uint96(_amount);

        // inform the vault of the quick withdraw
        vault.quickWithdraw(_amount);

        uint256[] memory amounts = _transferAssets(vault, _vault, _amount, _subAccount, currentRound);

        emit QuickWithdrew(_vault, _subAccount, amounts, currentRound);
    }

    /**
     * @notice requests a withdraw that can be processed once the round closes
     * @param _vault is the address of the vault
     * @param _subAccount is the address of the sub account
     * @param _numShares is the number of shares to withdraw
     */
    function requestWithdrawFor(address _vault, address _subAccount, uint256 _numShares) external virtual nonReentrant {
        if (_numShares == 0) revert REG_BadNumShares();
        if (msg.sender != _subAccount) _onlyManager(_vault);

        _migratePrecheck(_vault, _subAccount);

        DepositReceipt memory depositReceipt = depositReceipts[_vault][_subAccount];
        // if unredeemed shares exist, do a max redeem before initiating a withdraw
        if (depositReceipt.amount > 0 || depositReceipt.unredeemedShares > 0) _redeem(_vault, _subAccount, 0, true);

        // transferring vault tokens (shares) back to vault, to be burned when round closes
        share.transferRegistrarOnly(_subAccount, _vault, _vault, _numShares, "");

        IHashnoteVault vault = IHashnoteVault(_vault);
        // inform the vault of the withdraw request
        vault.requestWithdrawFor(_subAccount, _numShares);

        emit RequestedWithdraw(_vault, _subAccount, _numShares, vault.vaultState().round);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _subAccount is the address of the depositor
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function redeemFor(address _vault, address _subAccount, uint256 _numShares, bool _isMax) external virtual nonReentrant {
        if (msg.sender != _subAccount) _onlyManager(_vault);

        _migratePrecheck(_vault, _subAccount);

        _redeem(_vault, _subAccount, _numShares, _isMax);
    }

    /**
     * @notice Migrates deposits from vaults that were deployed pre Registrar
     * @param _vault is the address of the vault
     * @param _subAccount is the address of the sub account
     */
    function migrateDeposits(address _vault, address _subAccount) external {
        if (depositReceipts[_vault][_subAccount].round != 0) revert();

        IHashnoteVault vault = IHashnoteVault(_vault);
        DepositReceipt memory receipt = vault._depositReceipts(_subAccount);

        if (receipt.round == 0) revert();

        depositReceipts[_vault][_subAccount] = receipt;
    }

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param _account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address _vault, address _account) external view returns (uint256 heldByAccount, uint256 heldByVault) {
        DepositReceipt memory depositReceipt = depositReceipts[_vault][_account];

        if (depositReceipt.round < PLACEHOLDER_UINT) {
            return (share.getBalanceOf(_account, _vault), 0);
        }

        heldByVault = _getUnredeemedShares(depositReceipt, _vault, IHashnoteVault(_vault).vaultState().round);
        heldByAccount = share.getBalanceOf(_account, _vault);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _migratePrecheck(address _vault, address _subAccount) internal {
        if (depositReceipts[_vault][_subAccount].round != 0) return;

        IHashnoteVault vault = IHashnoteVault(_vault);
        DepositReceipt memory receipt = vault._depositReceipts(_subAccount);

        if (receipt.round == 0) return;

        depositReceipts[_vault][_subAccount] = receipt;
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `_subAccount`'s deposit
     * @param _subAccount is the address that can claim/withdraw deposited amount
     * @param _amount is the amount of primary asset to deposit
     */
    function _depositFor(IHashnoteVault _vault, address _subAccount, uint256 _amount)
        internal
        virtual
        returns (uint256 currentRound)
    {
        if (_amount == 0) revert REG_BadDepositAmount();
        _validateWhitelisted(msg.sender);

        if (_subAccount != msg.sender) _validateWhitelisted(_subAccount);

        currentRound = _vault.vaultState().round;
        DepositReceipt memory depositReceipt = depositReceipts[address(_vault)][_subAccount];
        uint256 unredeemedShares = depositReceipt.unredeemedShares;
        uint256 depositAmount = _amount;

        if (currentRound > depositReceipt.round) {
            // if we have an unprocessed pending deposit from the previous rounds, we first process it.
            if (depositReceipt.amount > 0) {
                unredeemedShares = _getUnredeemedShares(depositReceipt, address(_vault), currentRound);
            }
        } else {
            // if we have a pending deposit in the current round, we add on to the pending deposit
            depositAmount += depositReceipt.amount;
        }

        depositReceipts[address(_vault)][_subAccount] = DepositReceipt({
            round: uint32(currentRound),
            amount: _toUint96(depositAmount),
            unredeemedShares: _toUint128(unredeemedShares)
        });

        // inform vault of deposit
        _vault.deposit(_amount);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _depositor receipts
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function _redeem(address _vault, address _depositor, uint256 _numShares, bool _isMax) internal {
        if (!_isMax && _numShares == 0) revert REG_BadNumShares();

        VaultState memory vaultState = IHashnoteVault(_vault).vaultState();
        uint256 currentRound = vaultState.round;
        DepositReceipt storage depositReceipt = depositReceipts[_vault][_depositor];

        uint256 depositInRound = depositReceipt.round;
        uint256 unredeemedShares = depositReceipt.unredeemedShares;

        if (currentRound > depositReceipt.round) {
            unredeemedShares = _getUnredeemedShares(depositReceipt, _vault, currentRound);
        }

        if (_isMax) _numShares = unredeemedShares;
        if (_numShares == 0) return;
        if (_numShares > unredeemedShares) revert REG_ExceedsAvailable();

        // if we have a depositReceipt on the same round, BUT we have unredeemed shares
        // we debit from the unredeemedShares, leaving the amount field intact
        depositReceipt.unredeemedShares = _toUint128(unredeemedShares - _numShares);

        // if the round has past we zero amount for new deposits.
        if (depositInRound < currentRound) depositReceipt.amount = 0;

        emit Redeem(_vault, _depositor, _numShares, depositInRound);

        // account shares minted at closeRound to vault, we transfer to account from vault
        share.transferRegistrarOnly(_vault, _depositor, _vault, _numShares, "");
    }

    function _getUnredeemedShares(DepositReceipt memory _depositReceipt, address _vault, uint256 _currentRound)
        internal
        view
        returns (uint256 unredeemedShares)
    {
        if (_depositReceipt.round > 0 && _depositReceipt.round < _currentRound) {
            IHashnoteVault vault = IHashnoteVault(_vault);

            uint256 pps = vault.pricePerShare(_depositReceipt.round);
            if (pps <= PLACEHOLDER_UINT) revert FL_NPSLow();

            Collateral[] memory collaterals = vault.getCollaterals();
            uint256[] memory startingBalances = vault.getStartingBalances(_depositReceipt.round);
            uint256[] memory collateralPrices = vault.getCollateralPrices(_depositReceipt.round);
            uint256 nav;

            // primary asset amount used to calculating the amount of secondary assets deposited in the round
            uint256 primaryTotal = startingBalances[0];

            for (uint256 i; i < collaterals.length;) {
                uint256 balance = startingBalances[i].mulDivDown(_depositReceipt.amount, primaryTotal);

                nav += balance.mulDivDown(collateralPrices[i], 10 ** collaterals[i].decimals);

                unchecked {
                    ++i;
                }
            }

            uint256 sharesFromRound = nav.mulDivDown(UNIT, pps);

            return uint256(_depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return _depositReceipt.unredeemedShares;
    }

    /**
     * @notice Transfers assets between account holder and vault
     * @dev only called from depositFor and quickWithdraw
     */
    function _transferAssets(IHashnoteVault _vault, address _from, uint256 _amount, address _recipient, uint256 _round)
        internal
        returns (uint256[] memory amounts)
    {
        Collateral[] memory collats = _vault.getCollaterals();
        uint256[] memory startingBalances = _vault.getStartingBalances(_round);

        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = startingBalances[0];

        bool isWithdraw = _recipient != address(_vault);

        amounts = new uint256[](collats.length);

        for (uint256 i; i < collats.length;) {
            uint256 balance = startingBalances[i];

            if (isWithdraw) {
                amounts[i] = FixedPointMathLib.mulDivDown(balance, _amount, primaryTotal);
            } else {
                amounts[i] = FixedPointMathLib.mulDivUp(balance, _amount, primaryTotal);
            }

            if (amounts[i] != 0) {
                IHNT20(collats[i].addr).safeTransferFrom(_from, _recipient, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice gets whitelist status of an account
     * @param _subAccount address
     */
    function _validateWhitelisted(address _subAccount) internal view {
        if (!whitelist.isCustomer(_subAccount)) revert Unauthorized();
    }

    function _onlyManager(address _vault) internal view {
        if (msg.sender != IHashnoteVault(_vault).manager()) revert Unauthorized();
    }

    function _toUint96(uint256 _num) internal pure returns (uint96) {
        if (_num > type(uint96).max) revert Overflow();
        return uint96(_num);
    }

    function _toUint128(uint256 _num) internal pure returns (uint128) {
        if (_num > type(uint128).max) revert Overflow();
        return uint128(_num);
    }
}