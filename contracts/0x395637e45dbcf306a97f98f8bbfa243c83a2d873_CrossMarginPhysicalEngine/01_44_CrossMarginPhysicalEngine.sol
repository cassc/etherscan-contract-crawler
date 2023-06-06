// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";

// inheriting contracts
import {OptionTransferable} from "pomace/core/engines/mixins/OptionTransferable.sol";
import {BaseEngine} from "pomace/core/engines/BaseEngine.sol";

// interfaces
import {IMarginEngine} from "pomace/interfaces/IMarginEngine.sol";
import {IWhitelist} from "pomace/interfaces/IWhitelist.sol";
import {IOracle} from "pomace/interfaces/IOracle.sol";

// libraries
import {BalanceUtil} from "pomace/libraries/BalanceUtil.sol";
import {ProductIdUtil} from "pomace/libraries/ProductIdUtil.sol";
import {TokenIdUtil} from "pomace/libraries/TokenIdUtil.sol";
import {UintArrayLib} from "array-lib/UintArrayLib.sol";

// Cross margin libraries
import {AccountUtil} from "../libraries/AccountUtil.sol";
import {CrossMarginPhysicalMath} from "./CrossMarginPhysicalMath.sol";
import {CrossMarginPhysicalLib} from "./CrossMarginPhysicalLib.sol";

// Cross margin types
import "./types.sol";
import "../config/errors.sol";

// global constants and types
import {BatchExecute, ActionArgs} from "pomace/config/types.sol";
import "pomace/config/enums.sol";
import "pomace/config/constants.sol";
import "pomace/config/errors.sol";

/**
 * @title   CrossMarginPhysicalEngine
 * @author  @dsshap, @antoncoding
 * @notice  Fully collateralized margin engine
 *             Users can deposit collateral into Cross Margin and mint optionTokens (debt) out of it.
 *             Interacts with OptionToken to mint / burn
 *             Interacts with pomace to fetch registered asset info
 */
contract CrossMarginPhysicalEngine is
    OptionTransferable,
    IMarginEngine,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using AccountUtil for Position[];
    using BalanceUtil for Balance[];
    using CrossMarginPhysicalLib for CrossMarginAccount;
    using ProductIdUtil for uint32;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TokenIdUtil for uint256;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    ///@dev subAccount => CrossMarginAccount structure.
    ///     subAccount can be an address similar to the primary account, but has the last 8 bits different.
    ///     this give every account access to 256 sub-accounts
    mapping(address => CrossMarginAccount) internal accounts;

    ///@dev contract that verifies permissions
    ///     if not set allows anyone to transact
    ///     checks msg.sender on execute & batchExecute
    ///     checks recipient on payCashValue
    IWhitelist public whitelist;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev token => SettlementTracker
    mapping(uint256 => SettlementTracker) public tokenTracker;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    // solhint-disable-next-line no-empty-blocks
    constructor(address _pomace, address _optionToken) BaseEngine(_pomace, _optionToken) initializer {}

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();

        _transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();
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
     * @notice Sets the whitelist contract
     * @param _whitelist is the address of the new whitelist
     */
    function setWhitelist(address _whitelist) external {
        _checkOwner();

        whitelist = IWhitelist(_whitelist);
    }

    /**
     * @notice batch execute on multiple subAccounts
     * @dev    check margin after all subAccounts are updated
     *         because we support actions like `TransferCollateral` that moves collateral between subAccounts
     */
    function batchExecute(BatchExecute[] calldata batchActions) external nonReentrant {
        _checkPermissioned(msg.sender);

        uint256 i;
        for (i; i < batchActions.length;) {
            address subAccount = batchActions[i].subAccount;
            ActionArgs[] calldata actions = batchActions[i].actions;

            _execute(subAccount, actions);

            // increase i without checking overflow
            unchecked {
                ++i;
            }
        }

        for (i = 0; i < batchActions.length;) {
            if (!_isAccountAboveWater(batchActions[i].subAccount)) revert BM_AccountUnderwater();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice execute multiple actions on one subAccounts
     * @dev    check margin all actions are applied
     */
    function execute(address _subAccount, ActionArgs[] calldata actions) external override nonReentrant {
        _checkPermissioned(msg.sender);

        _execute(_subAccount, actions);

        if (!_isAccountAboveWater(_subAccount)) revert BM_AccountUnderwater();
    }

    /**
     * @dev hook to be invoked by Grappa to handle custom logic of settlement
     */
    function handleExercise(uint256 _tokenId, uint256 _debtPaid, uint256 _amountPaidOut)
        external
        override(BaseEngine, IMarginEngine)
    {
        _checkIsPomace();

        tokenTracker[_tokenId].totalDebt += _debtPaid.toUint80();
        tokenTracker[_tokenId].totalPaid += _amountPaidOut.toUint80();
    }

    /**
     * @dev gets the amount of debts and payouts that should be recorded for given short position amounts
     * @dev this function should only be used after expiry to properly socialise all exercised amount to all physical settled options
     */
    function getBatchSettlementForShorts(uint256[] calldata _tokenIds, uint256[] calldata _amounts)
        external
        view
        returns (Balance[] memory debts, Balance[] memory payouts)
    {
        // payouts and debts will be 0 for physical settlement options because it has
        // passed the settlement window
        (debts, payouts) = pomace.batchGetDebtAndPayouts(_tokenIds, _amounts);

        for (uint256 i; i < _tokenIds.length;) {
            SettlementTracker memory tracker = tokenTracker[_tokenIds[i]];

            // if the token is physical settled and someone exercised within exercise window
            // we socialized the payout and debt (total amount paid out and received during exercise window)
            if (tracker.totalDebt > 0) {
                (Balance memory debt, Balance memory payout) = _socializeSettlement(tracker, _tokenIds[i], _amounts[i]);
                debts = _addToBalances(debts, debt.collateralId, debt.amount);
                payouts = _addToBalances(payouts, payout.collateralId, payout.amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice payout to user on settlement.
     * @dev this can only triggered by Grappa, would only be called on settlement.
     * @param _asset asset to transfer
     * @param _sender sender of debt
     * @param _amount amount
     */
    function receiveDebtValue(address _asset, address _sender, uint256 _amount) external {
        _checkPermissioned(_sender);

        _receiveDebtValue(_asset, _sender, _amount);
    }

    /**
     * @notice payout to user on settlement.
     * @dev this can only triggered by Pomace, would only be called on settlement.
     * @param _asset asset to transfer
     * @param _recipient receiver
     * @param _amount amount
     */
    function sendPayoutValue(address _asset, address _recipient, uint256 _amount) external {
        if (_recipient == address(this)) return;

        _checkPermissioned(_recipient);

        _sendPayoutValue(_asset, _recipient, _amount);
    }

    /**
     * @notice get minimum collateral needed for a margin account
     * @param _subAccount account id.
     * @return balances array of collaterals and amount (signed)
     */
    function getMinCollateral(address _subAccount) external view returns (Balance[] memory) {
        CrossMarginAccount memory account = accounts[_subAccount];
        return _getMinCollateral(account);
    }

    /**
     * @notice  move an account to someone else
     * @dev     expected to be call by account owner
     * @param _subAccount the id of subaccount to transfer
     * @param _newSubAccount the id of receiving account
     */
    function transferAccount(address _subAccount, address _newSubAccount) external {
        if (!_isPrimaryAccountFor(msg.sender, _subAccount)) revert NoAccess();

        if (!accounts[_newSubAccount].isEmpty()) revert CM_AccountIsNotEmpty();
        accounts[_newSubAccount] = accounts[_subAccount];

        delete accounts[_subAccount];
    }

    /**
     * @dev view function to get all shorts, longs and collaterals
     */
    function marginAccounts(address _subAccount)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals)
    {
        CrossMarginAccount memory account = accounts[_subAccount];

        return (account.shorts, account.longs, account.collaterals);
    }

    /**
     * @notice get minimum collateral needed for a margin account
     * @param shorts positions.
     * @param longs positions.
     * @return balances array of collaterals and amount
     */
    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory) {
        CrossMarginAccount memory account;

        account.shorts = shorts;
        account.longs = longs;

        return _getMinCollateral(account);
    }

    /**
     * ========================================================= **
     *             Override Internal Functions For Each Action
     * ========================================================= *
     */

    /**
     * @notice  settle the margin account at expiry
     * @dev     override this function from BaseEngine
     *          because we get the payout while updating the storage during settlement
     * @dev     this update the account storage
     */
    function _settle(address _subAccount) internal override {
        // update the account in state
        (, Balance[] memory payouts) = accounts[_subAccount].settleShorts();
        emit AccountSettled(_subAccount, payouts);
    }

    /**
     * ========================================================= **
     *               Override Sate changing functions             *
     * ========================================================= *
     */

    /**
     * @dev mint option token to _subAccount, increase tracker issuance
     * @param _data bytes data to decode
     */
    function _mintOption(address _subAccount, bytes calldata _data) internal virtual override {
        super._mintOption(_subAccount, _data);

        // decode tokenId
        (uint256 tokenId,, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        tokenTracker[tokenId].issued += amount;
    }

    /**
     * @dev mint option token into account, increase tracker issuance
     * @param _data bytes data to decode
     */
    function _mintOptionIntoAccount(address _subAccount, bytes calldata _data) internal virtual override {
        super._mintOptionIntoAccount(_subAccount, _data);

        // decode tokenId
        (uint256 tokenId,, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        // grappa.trackTokenIssuance(tokenId, amount, true);
        tokenTracker[tokenId].issued += amount;
    }

    /**
     * @dev burn option token from user, decrease tracker issuance
     * @param _data bytes data to decode
     */
    function _burnOption(address _subAccount, bytes calldata _data) internal virtual override {
        super._burnOption(_subAccount, _data);

        // decode parameters
        (uint256 tokenId,, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        tokenTracker[tokenId].issued -= amount;
    }

    function _addCollateralToAccount(address _subAccount, uint8 collateralId, uint80 amount) internal override {
        accounts[_subAccount].addCollateral(collateralId, amount);
    }

    function _removeCollateralFromAccount(address _subAccount, uint8 collateralId, uint80 amount) internal override {
        accounts[_subAccount].removeCollateral(collateralId, amount);
    }

    function _increaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].mintOption(tokenId, amount);
    }

    function _decreaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].burnOption(tokenId, amount);
    }

    function _increaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].addOption(tokenId, amount);
    }

    function _decreaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].removeOption(tokenId, amount);
    }

    function _exerciseTokenInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].exerciseToken(pomace, tokenId, amount);
    }

    /**
     * ========================================================= **
     *          Override view functions for BaseEngine
     * ========================================================= *
     */

    /**
     * @dev because we override _settle(), this function is not used
     */
    // solhint-disable-next-line no-empty-blocks
    function _getAccountPayout(address) internal view override returns (uint8, int80) {}

    /**
     * @dev return whether if an account is healthy.
     * @param _subAccount subaccount id
     * @return isHealthy true if account is in good condition, false if it's underwater (liquidatable)
     */
    function _isAccountAboveWater(address _subAccount) internal view override returns (bool) {
        CrossMarginAccount memory account = accounts[_subAccount];

        Balance[] memory collaterals = account.collaterals;
        Balance[] memory requirements = _getMinCollateral(account);

        uint256 collatCount = collaterals.length;

        uint256[] memory masks;
        uint256[] memory amounts = new uint256[](collatCount);
        address[] memory addresses = new address[](collatCount);

        IOracle oracle;

        unchecked {
            for (uint256 x; x < requirements.length; ++x) {
                uint8 reqCollatId = requirements[x].collateralId;
                (address reqCollatAddr,) = pomace.assets(reqCollatId);
                uint256 reqAmount = requirements[x].amount;

                masks = new uint256[](collatCount);
                uint256 y;

                for (y; y < collatCount; ++y) {
                    uint8 collatId = collaterals[y].collateralId;

                    // only setting amount and address on first pass
                    // dont need to repeat each inner loop
                    if (x == 0) {
                        amounts[y] = collaterals[y].amount;

                        (address addr,) = pomace.assets(collatId);
                        addresses[y] = addr;
                    }

                    if (reqCollatId == collatId) {
                        masks[y] = 1 * UNIT;
                    } else {
                        // setting mask to price if reqCollateralId is collateralId
                        if (_isCollateralizable(reqCollatId, collatId)) {
                            if (address(oracle) == address(0)) oracle = pomace.oracle();

                            masks[y] = oracle.getSpotPrice(addresses[y], reqCollatAddr);
                        }
                    }
                }

                uint256 marginValue = UintArrayLib.dot(amounts, masks) / UNIT;

                // not enough collateral posted
                if (marginValue < reqAmount) return false;

                // reserving collateral to prevent double counting
                for (y = 0; y < collatCount; ++y) {
                    if (masks[y] == 0) continue;

                    marginValue = amounts[y] * masks[y] / UNIT;

                    if (reqAmount >= marginValue) {
                        reqAmount = reqAmount - marginValue;
                        amounts[y] = 0;

                        if (reqAmount == 0) break;
                    } else {
                        amounts[y] = uint80(amounts[y] - (amounts[y] * reqAmount / marginValue));
                        // reqAmount would now be set to zero,
                        // no longer need to reserve, so breaking
                        break;
                    }
                }
            }
        }

        return true;
    }

    /**
     * @dev reverts if the account cannot add this token into the margin account.
     * @param tokenId tokenId
     */
    function _verifyLongTokenIdToAdd(uint256 tokenId) internal view override {
        (TokenType tokenType,, uint64 expiry,,) = tokenId.parseTokenId();

        // engine only supports calls and puts
        if (tokenType != TokenType.CALL && tokenType != TokenType.PUT) revert CM_UnsupportedTokenType();

        if (block.timestamp > expiry) revert CM_Token_Expired();

        uint8 engineId = tokenId.parseEngineId();

        // in the future reference a whitelist of engines
        if (engineId != pomace.engineIds(address(this))) revert CM_Not_Authorized_Engine();
    }

    /**
     * ========================================================= **
     *                         Internal Functions
     * ========================================================= *
     */

    /**
     * @notice gets access status of an address
     * @dev if whitelist address is not set, it ignores this
     * @param _address address
     */
    function _checkPermissioned(address _address) internal view {
        if (address(whitelist) != address(0) && !whitelist.isAllowed(_address)) revert NoAccess();
    }

    /**
     * @notice execute multiple actions on one subAccounts
     * @dev    also check access of msg.sender
     */
    function _execute(address _subAccount, ActionArgs[] calldata actions) internal {
        _assertCallerHasAccess(_subAccount);

        // update the account storage and do external calls on the flight
        for (uint256 i; i < actions.length;) {
            if (actions[i].action == ActionType.AddCollateral) {
                _addCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.RemoveCollateral) {
                _removeCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.MintShort) {
                _mintOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.MintShortIntoAccount) {
                _mintOptionIntoAccount(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.BurnShort) {
                _burnOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferLong) {
                _transferLong(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferShort) {
                _transferShort(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferCollateral) {
                _transferCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.AddLong) {
                _addOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.RemoveLong) {
                _removeOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.ExerciseToken) {
                _exerciseToken(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.SettleAccount) {
                _settle(_subAccount);
            } else {
                revert CM_UnsupportedAction();
            }

            // increase i without checking overflow
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev get minimum collateral requirement for an account
     */
    function _getMinCollateral(CrossMarginAccount memory account) internal view returns (Balance[] memory) {
        return CrossMarginPhysicalMath.getMinCollateralForPositions(pomace, account.shorts, account.longs);
    }

    /**
     * @dev check if a pair of assetIds are collateralizable
     */
    function _isCollateralizable(uint8 _assetId0, uint8 _assetId1) internal view returns (bool) {
        if (_assetId0 == _assetId1) return true;

        return pomace.isCollateralizable(_assetId0, _assetId1);
    }

    function _socializeSettlement(SettlementTracker memory tracker, uint256 tokenId, uint256 shortAmount)
        internal
        pure
        returns (Balance memory debt, Balance memory payout)
    {
        (TokenType tokenType, uint32 productId,,,) = TokenIdUtil.parseTokenId(tokenId);
        (, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = ProductIdUtil.parseProductId(productId);

        payout.collateralId = collateralId;

        if (tokenType == TokenType.CALL) debt.collateralId = strikeId;
        else if (tokenType == TokenType.PUT) debt.collateralId = underlyingId;

        debt.amount = (tracker.totalDebt * shortAmount / tracker.issued).toUint80();
        payout.amount = (tracker.totalPaid * shortAmount / tracker.issued).toUint80();
    }

    /**
     * @dev add an entry to array of Balance
     * @param balances existing payout array
     * @param _asset new collateralId
     * @param _amount new payout
     */
    function _addToBalances(Balance[] memory balances, uint8 _asset, uint256 _amount)
        internal
        pure
        returns (Balance[] memory newBalances)
    {
        (bool found, uint256 index) = balances.indexOf(_asset);

        uint80 balance = _amount.toUint80();

        if (!found) balances = balances.append(Balance(_asset, balance));
        else balances[index].amount += balance;

        return balances;
    }
}