// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { MarginVault } from "../libs/MarginVault.sol";
import { Actions } from "../libs/Actions.sol";
import { AddressBookInterface } from "../interfaces/AddressBookInterface.sol";
import { ONtokenInterface } from "../interfaces/ONtokenInterface.sol";
import { MarginCalculatorInterface } from "../interfaces/MarginCalculatorInterface.sol";
import { OracleInterface } from "../interfaces/OracleInterface.sol";
import { WhitelistInterface } from "../interfaces/WhitelistInterface.sol";
import { MarginPoolInterface } from "../interfaces/MarginPoolInterface.sol";
import { ArrayAddressUtils } from "../libs/ArrayAddressUtils.sol";
import { FPI } from "../libs/FixedPointInt256.sol";

/**
 * Controller Error Codes
 * C1: sender is not full pauser
 * C2: sender is not partial pauser
 * C4: system is partially paused
 * C5: system is fully paused
 * C6: msg.sender is not authorized to run action
 * C7: invalid addressbook address
 * C8: invalid owner address
 * C9: invalid input
 * C10: fullPauser cannot be set to address zero
 * C11: partialPauser cannot be set to address zero
 * C12: can not run actions for different owners
 * C13: can not run actions on different vaults
 * C14: can not run actions on inexistent vault
 * C15: cannot deposit long onToken from this address
 * C16: onToken is not whitelisted to be used as collateral
 * C17: can not withdraw an expired onToken
 * C18: cannot deposit collateral from this address
 * C19: onToken is not whitelisted
 * C20: can not mint expired onToken
 * C21: can not burn expired onToken
 * C22: onToken is not whitelisted to be redeemed
 * C23: can not redeem un-expired onToken
 * C24: asset prices not finalized yet
 * C25: can not settle vault with un-expired onToken
 * C26: invalid vault id
 * C27: vault does not have long to withdraw
 * C28: vault has no collateral to mint onToken
 * C29: deposit/withdraw collateral amounts should be same length as collateral assets amount for correspoding vault short
 * C30: donate asset adress is zero
 * C31: donate asset is one of collaterls in associated onToken
 */

/**
 * @title Controller
 * @notice Contract that controls the Gamma Protocol and the interaction of all sub contracts
 */
contract Controller is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using MarginVault for MarginVault.Vault;
    using SafeMath for uint256;
    using ArrayAddressUtils for address[];

    AddressBookInterface public addressbook;
    WhitelistInterface public whitelist;
    OracleInterface public oracle;
    MarginCalculatorInterface public calculator;
    MarginPoolInterface public pool;

    /// @notice address that has permission to partially pause the system, where system functionality is paused
    /// except redeem and settleVault
    address public partialPauser;

    /// @notice address that has permission to fully pause the system, where all system functionality is paused
    address public fullPauser;

    /// @notice True if all system functionality is paused other than redeem and settle vault
    bool public systemPartiallyPaused;

    /// @notice True if all system functionality is paused
    bool public systemFullyPaused;

    /// @dev mapping between an owner address and the number of owner address vaults
    mapping(address => uint256) public accountVaultCounter;
    /// @dev mapping between an owner address and a specific vault using a vault id
    mapping(address => mapping(uint256 => MarginVault.Vault)) public vaults;
    /// @dev mapping between an account owner and their approved or unapproved account operators
    mapping(address => mapping(address => bool)) internal operators;

    /// @dev mapping to store the timestamp at which the vault was last updated, will be updated in every action that changes the vault state or when calling sync()
    mapping(address => mapping(uint256 => uint256)) internal vaultLatestUpdate;

    /// @notice emits an event when an account operator is updated for a specific account owner
    event AccountOperatorUpdated(address indexed accountOwner, address indexed operator, bool isSet);
    /// @notice emits an event when a new vault is opened
    event VaultOpened(address indexed accountOwner, uint256 vaultId);
    /// @notice emits an event when a long onToken is deposited into a vault
    event LongONtokenDeposited(
        address indexed onToken,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a long onToken is withdrawn from a vault
    event LongONtokenWithdrawed(
        address indexed onToken,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is deposited into a vault
    event CollateralAssetDeposited(
        address indexed asset,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is withdrawn from a vault
    event CollateralAssetWithdrawed(
        address indexed asset,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short onToken is minted from a vault
    event ShortONtokenMinted(
        address indexed onToken,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short onToken is burned
    event ShortONtokenBurned(
        address indexed onToken,
        address indexed accountOwner,
        address indexed sender,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when an onToken is redeemed
    event Redeem(
        address indexed onToken,
        address indexed redeemer,
        address indexed receiver,
        address[] collateralAssets,
        uint256 onTokenBurned,
        uint256[] payouts
    );
    /// @notice emits an event when a vault is settled
    event VaultSettled(
        address indexed accountOwner,
        address indexed shortONtoken,
        address to,
        uint256[] payouts,
        uint256 vaultId
    );
    /// @notice emits an event when a call action is executed
    event CallExecuted(address indexed from, address indexed to, bytes data);
    /// @notice emits an event when the fullPauser address changes
    event FullPauserUpdated(address indexed oldFullPauser, address indexed newFullPauser);
    /// @notice emits an event when the partialPauser address changes
    event PartialPauserUpdated(address indexed oldPartialPauser, address indexed newPartialPauser);
    /// @notice emits an event when the system partial paused status changes
    event SystemPartiallyPaused(bool isPaused);
    /// @notice emits an event when the system fully paused status changes
    event SystemFullyPaused(bool isPaused);
    /// @notice emits an event when a donation transfer executed
    event Donated(address indexed donator, address indexed asset, uint256 amount);
    /// @notice emits an event when naked cap is updated
    // event NakedCapUpdated(address indexed collateral, uint256 cap);

    /**
     * @notice modifier to check if the system is not partially paused, where only redeem and settleVault is allowed
     */
    modifier notPartiallyPaused() {
        _isNotPartiallyPaused();

        _;
    }

    /**
     * @notice modifier to check if the system is not fully paused, where no functionality is allowed
     */
    modifier notFullyPaused() {
        _isNotFullyPaused();

        _;
    }

    /**
     * @notice modifier to check if sender is the fullPauser address
     */
    modifier onlyFullPauser() {
        require(msg.sender == fullPauser, "C1");

        _;
    }

    /**
     * @notice modifier to check if the sender is the partialPauser address
     */
    modifier onlyPartialPauser() {
        require(msg.sender == partialPauser, "C2");

        _;
    }

    /**
     * @notice modifier to check if the sender is the account owner or an approved account operator
     * @param _sender sender address
     * @param _accountOwner account owner address
     */
    modifier onlyAuthorized(address _sender, address _accountOwner) {
        _isAuthorized(_sender, _accountOwner);

        _;
    }

    /**
     * @dev check if the system is not in a partiallyPaused state
     */
    function _isNotPartiallyPaused() internal view {
        require(!systemPartiallyPaused, "C4");
    }

    /**
     * @dev check if the system is not in an fullyPaused state
     */
    function _isNotFullyPaused() internal view {
        require(!systemFullyPaused, "C5");
    }

    /**
     * @dev check if the sender is an authorized operator
     * @param _sender msg.sender
     * @param _accountOwner owner of a vault
     */
    function _isAuthorized(address _sender, address _accountOwner) internal view {
        require((_sender == _accountOwner) || (operators[_accountOwner][_sender]), "C6");
    }

    /**
     * @notice initalize the deployed contract
     * @param _addressBook addressbook module
     * @param _owner account owner address
     */
    function initialize(address _addressBook, address _owner) external initializer {
        require(_addressBook != address(0), "C7");
        require(_owner != address(0), "C8");

        __Ownable_init();
        transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();

        addressbook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }

    /**
     * @notice send asset amount to margin pool
     * @dev use donate() instead of direct transfer() to store the balance in assetBalance
     * @param _asset asset address
     * @param _amount amount to donate to pool
     * @param _onToken to donate _asset for
     */
    function donate(
        address _asset,
        uint256 _amount,
        address _onToken
    ) external {
        require(_asset != address(0), "C30");
        require(whitelist.isWhitelistedONtoken(_onToken), "C19");

        address[] memory _collateralAssets = ONtokenInterface(_onToken).getCollateralAssets();

        bool isCollateralAsset = false;
        for (uint256 i = 0; i < _collateralAssets.length; i++) {
            if (_collateralAssets[i] == _asset) {
                isCollateralAsset = true;
                break;
            }
        }

        require(isCollateralAsset, "C31");

        pool.transferToPool(_asset, msg.sender, _amount);

        emit Donated(msg.sender, _asset, _amount);
    }

    /**
     * @notice allows the partialPauser to toggle the systemPartiallyPaused variable and partially pause or partially unpause the system
     * @dev can only be called by the partialPauser
     * @param _partiallyPaused new boolean value to set systemPartiallyPaused to
     */
    function setSystemPartiallyPaused(bool _partiallyPaused) external onlyPartialPauser {
        require(systemPartiallyPaused != _partiallyPaused, "C9");

        systemPartiallyPaused = _partiallyPaused;

        emit SystemPartiallyPaused(systemPartiallyPaused);
    }

    /**
     * @notice allows the fullPauser to toggle the systemFullyPaused variable and fully pause or fully unpause the system
     * @dev can only be called by the fullyPauser
     * @param _fullyPaused new boolean value to set systemFullyPaused to
     */
    function setSystemFullyPaused(bool _fullyPaused) external onlyFullPauser {
        require(systemFullyPaused != _fullyPaused, "C9");

        systemFullyPaused = _fullyPaused;

        emit SystemFullyPaused(systemFullyPaused);
    }

    /**
     * @notice allows the owner to set the fullPauser address
     * @dev can only be called by the owner
     * @param _fullPauser new fullPauser address
     */
    function setFullPauser(address _fullPauser) external onlyOwner {
        require(_fullPauser != address(0), "C10");
        require(fullPauser != _fullPauser, "C9");
        emit FullPauserUpdated(fullPauser, _fullPauser);
        fullPauser = _fullPauser;
    }

    /**
     * @notice allows the owner to set the partialPauser address
     * @dev can only be called by the owner
     * @param _partialPauser new partialPauser address
     */
    function setPartialPauser(address _partialPauser) external onlyOwner {
        require(_partialPauser != address(0), "C11");
        require(partialPauser != _partialPauser, "C9");
        emit PartialPauserUpdated(partialPauser, _partialPauser);
        partialPauser = _partialPauser;
    }

    /**
     * @notice allows a user to give or revoke privileges to an operator which can act on their behalf on their vaults
     * @dev can only be updated by the vault owner
     * @param _operator operator that the sender wants to give privileges to or revoke them from
     * @param _isOperator new boolean value that expresses if the sender is giving or revoking privileges for _operator
     */
    function setOperator(address _operator, bool _isOperator) external {
        require(operators[msg.sender][_operator] != _isOperator, "C9");

        operators[msg.sender][_operator] = _isOperator;

        emit AccountOperatorUpdated(msg.sender, _operator, _isOperator);
    }

    /**
     * @dev updates the configuration of the controller. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    /**
     * @notice execute a number of actions on specific vaults
     * @dev can only be called when the system is not fully paused
     * @param _actions array of actions arguments
     */
    function operate(Actions.ActionArgs[] memory _actions) external nonReentrant notFullyPaused {
        (bool vaultUpdated, address vaultOwner, uint256 vaultId) = _runActions(_actions);
        if (vaultUpdated) {
            vaultLatestUpdate[vaultOwner][vaultId] = block.timestamp;
        }
    }

    /**
     * @notice check if a specific address is an operator for an owner account
     * @param _owner account owner address
     * @param _operator account operator address
     * @return True if the _operator is an approved operator for the _owner account
     */
    function isOperator(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }

    /**
     * @notice return a vault's proceeds pre or post expiry, the amount of collateral that can be removed from a vault
     * @param _owner account owner of the vault
     * @param _vaultId vaultId to return balances for
     * @return amount of collateral that can be taken out
     */
    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256[] memory) {
        (MarginVault.Vault memory vault, ) = getVaultWithDetails(_owner, _vaultId);
        return calculator.getExcessCollateral(vault);
    }

    /**
     * @dev return if an expired onToken is ready to be settled, only true when price for underlying,
     * strike and collateral assets at this specific expiry is available in our Oracle module
     * @param _onToken onToken
     */
    function isSettlementAllowed(address _onToken) external view returns (bool) {
        (address[] memory collaterals, address underlying, address strike, uint256 expiry) = _getONtokenDetails(
            _onToken
        );
        return canSettleAssets(underlying, strike, collaterals, expiry);
    }

    /**
     * @notice check if an onToken has expired
     * @param _onToken onToken address
     * @return True if the onToken has expired, False if not
     */
    function hasExpired(address _onToken) external view returns (bool) {
        return block.timestamp >= ONtokenInterface(_onToken).expiryTimestamp();
    }

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner, vault type and the latest timestamp when the vault was updated
     */
    function getVaultWithDetails(address _owner, uint256 _vaultId)
        public
        view
        returns (MarginVault.Vault memory, uint256)
    {
        return (vaults[_owner][_vaultId], vaultLatestUpdate[_owner][_vaultId]);
    }

    /**
     * @notice execute a variety of actions
     * @dev for each action in the action array, execute the corresponding action, only one vault can be modified
     * for all actions except SettleVault, Redeem, and Call
     * @param _actions array of type Actions.ActionArgs[], which expresses which actions the user wants to execute
     * @return vaultUpdated, indicates if a vault has changed
     * @return owner, the vault owner if a vault has changed
     * @return vaultId, the vault Id if a vault has changed
     */
    function _runActions(Actions.ActionArgs[] memory _actions)
        internal
        returns (
            bool,
            address,
            uint256
        )
    {
        address vaultOwner;
        uint256 vaultId;
        bool vaultUpdated;

        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];
            Actions.ActionType actionType = action.actionType;

            // actions except Settle, Redeem are "Vault-updating actions"
            // only allow update 1 vault in each operate call
            if ((actionType != Actions.ActionType.SettleVault) && (actionType != Actions.ActionType.Redeem)) {
                // check if this action is manipulating the same vault as all other actions, if a vault has already been updated
                if (vaultUpdated) {
                    require(vaultOwner == action.owner, "C12");
                    require(vaultId == action.vaultId, "C13");
                }
                vaultUpdated = true;
                vaultId = action.vaultId;
                vaultOwner = action.owner;
            }

            if (actionType == Actions.ActionType.OpenVault) {
                _openVault(Actions._parseOpenVaultArgs(action));
            } else if (actionType == Actions.ActionType.DepositLongOption) {
                _depositLong(Actions._parseDepositLongArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawLongOption) {
                _withdrawLong(Actions._parseWithdrawLongArgs(action));
            } else if (actionType == Actions.ActionType.DepositCollateral) {
                _depositCollateral(Actions._parseDepositCollateralArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawCollateral) {
                _withdrawCollateral(Actions._parseWithdrawCollateralArgs(action));
            } else if (actionType == Actions.ActionType.MintShortOption) {
                _mintONtoken(Actions._parseMintArgs(action));
            } else if (actionType == Actions.ActionType.BurnShortOption) {
                _burnONtoken(Actions._parseBurnArgs(action));
            } else if (actionType == Actions.ActionType.Redeem) {
                _redeem(Actions._parseRedeemArgs(action));
            } else if (actionType == Actions.ActionType.SettleVault) {
                _settleVault(Actions._parseSettleVaultArgs(action));
            }
        }

        return (vaultUpdated, vaultOwner, vaultId);
    }

    /**
     * @notice open a new vault inside an account
     * @dev only the account owner or operator can open a vault, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args OpenVaultArgs structure
     */
    function _openVault(Actions.OpenVaultArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        uint256 vaultId = accountVaultCounter[_args.owner].add(1);

        require(_args.vaultId == vaultId, "C14");
        require(whitelist.isWhitelistedONtoken(_args.shortONtoken), "C19");

        ONtokenInterface onToken = ONtokenInterface(_args.shortONtoken);

        // store new vault
        accountVaultCounter[_args.owner] = vaultId;
        // every vault is linked to certain onToken which this vault can mint
        vaults[_args.owner][vaultId].shortONtoken = _args.shortONtoken;
        address[] memory collateralAssets = onToken.getCollateralAssets();
        // store collateral assets of linked onToken to vault
        vaults[_args.owner][vaultId].collateralAssets = collateralAssets;

        uint256 assetsLength = collateralAssets.length;

        // Initialize vault collateral params as arrays for later use
        vaults[_args.owner][vaultId].collateralAmounts = new uint256[](assetsLength);
        vaults[_args.owner][vaultId].availableCollateralAmounts = new uint256[](assetsLength);
        vaults[_args.owner][vaultId].reservedCollateralAmounts = new uint256[](assetsLength);
        vaults[_args.owner][vaultId].usedCollateralValues = new uint256[](assetsLength);

        emit VaultOpened(_args.owner, vaultId);
    }

    /**
     * @notice deposit a long onToken into a vault
     * @dev only the account owner or operator can deposit a long onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositLong(Actions.DepositLongArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");
        // only allow vault owner or vault operator to deposit long onToken
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C15");

        require(whitelist.isWhitelistedONtoken(_args.longONtoken), "C16");

        // Check if short and long onTokens params are matched,
        // they must be they should differ only in strike value
        require(
            calculator.isMarginableLong(_args.longONtoken, vaults[_args.owner][_args.vaultId]),
            "not marginable long"
        );

        vaults[_args.owner][_args.vaultId].addLong(_args.longONtoken, _args.amount);
        pool.transferToPool(_args.longONtoken, _args.from, _args.amount);

        emit LongONtokenDeposited(_args.longONtoken, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice withdraw a long onToken from a vault
     * @dev only the account owner or operator can withdraw a long onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawLong(Actions.WithdrawLongArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        address onTokenAddress = vaults[_args.owner][_args.vaultId].longONtoken;
        require(onTokenAddress != address(0), "C27");

        ONtokenInterface onToken = ONtokenInterface(vaults[_args.owner][_args.vaultId].longONtoken);

        // Can't withdraw after expiry, should call settleVault to execute long
        require(block.timestamp < onToken.expiryTimestamp(), "C17");

        vaults[_args.owner][_args.vaultId].removeLong(onTokenAddress, _args.amount);

        pool.transferToUser(onTokenAddress, _args.to, _args.amount);

        emit LongONtokenWithdrawed(onTokenAddress, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice deposit a collateral asset into a vault
     * @dev only the account owner or operator can deposit collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositCollateral(Actions.DepositCollateralArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");
        // only allow vault owner or vault operator to deposit collateral
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C18");

        address[] memory collateralAssets = vaults[_args.owner][_args.vaultId].collateralAssets;
        uint256 collateralsLength = collateralAssets.length;
        require(collateralsLength == _args.amounts.length, "C29");

        for (uint256 i = 0; i < collateralsLength; i++) {
            if (_args.amounts[i] > 0) {
                pool.transferToPool(collateralAssets[i], _args.from, _args.amounts[i]);
                emit CollateralAssetDeposited(
                    collateralAssets[i],
                    _args.owner,
                    _args.from,
                    _args.vaultId,
                    _args.amounts[i]
                );
            }
        }
        vaults[_args.owner][_args.vaultId].addCollaterals(collateralAssets, _args.amounts);
    }

    /**
     * @notice withdraw a collateral asset from a vault
     * @dev only the account owner or operator can withdraw collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawCollateral(Actions.WithdrawCollateralArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        (MarginVault.Vault memory vault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        // If argument is one element array with zero element withdraw all available
        // otherwise withdraw provided amounts array
        uint256[] memory amounts = _args.amounts.length == 1 && _args.amounts[0] == 0
            ? vault.availableCollateralAmounts
            : _args.amounts;

        vaults[_args.owner][_args.vaultId].removeCollateral(amounts);

        address[] memory collateralAssets = vaults[_args.owner][_args.vaultId].collateralAssets;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                pool.transferToUser(collateralAssets[i], _args.to, amounts[i]);
                emit CollateralAssetWithdrawed(collateralAssets[i], _args.owner, _args.to, _args.vaultId, amounts[i]);
            }
        }
    }

    /**
     * @notice calculates maximal short amount can be minted for collateral in a given user and vault
     */
    function getMaxCollateratedShortAmount(address user, uint256 vault_id) external view returns (uint256) {
        return calculator.getMaxShortAmount(vaults[user][vault_id]);
    }

    /**
     * @notice mint short onTokens from a vault which creates an obligation that is recorded in the vault
     * @dev only the account owner or operator can mint an onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _mintONtoken(Actions.MintArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        MarginVault.Vault storage vault = vaults[_args.owner][_args.vaultId];

        address vaultShortONtoken = vault.shortONtoken;

        ONtokenInterface onToken = ONtokenInterface(vaultShortONtoken);
        require(block.timestamp < onToken.expiryTimestamp(), "C20");

        // Mint maximum possible shorts if zero
        if (_args.amount == 0) {
            _args.amount = calculator.getMaxShortAmount(vault);
        }

        // If amount is still zero must be not enough collateral to mint any short
        if (_args.amount == 0) {
            revert("C28");
        }

        // collateralsValuesRequired - is value of each collateral used for minting onToken in strike asset,
        // in other words -  usedCollateralsAmounts[i] * collateralAssetPriceInStrike[i]
        // collateralsAmountsUsed and collateralsValuesUsed takes into account amounts used from long too
        // collateralsAmountsRequired is amounts required from vaults deposited collaterals only, without using long
        (
            uint256[] memory collateralsAmountsRequired,
            uint256[] memory collateralsAmountsUsed,
            uint256[] memory collateralsValuesUsed,
            uint256 usedLongAmount
        ) = calculator.getCollateralsToCoverShort(vault, _args.amount);
        onToken.mintONtoken(_args.to, _args.amount, collateralsAmountsUsed, collateralsValuesUsed);
        vault.addShort(_args.amount);
        // Updates vault's data regarding used and available collaterals,
        // and used collaterals values for later calculations on vault settlement
        vault.useVaultsAssets(collateralsAmountsRequired, usedLongAmount, collateralsValuesUsed);

        emit ShortONtokenMinted(vaultShortONtoken, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice burn onTokens to reduce or remove the minted onToken obligation recorded in a vault
     * @dev only the account owner or operator can burn an onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _burnONtoken(Actions.BurnArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        // check that vault id is valid for this vault owner
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");
        address onTokenAddress = vaults[_args.owner][_args.vaultId].shortONtoken;
        ONtokenInterface onToken = ONtokenInterface(onTokenAddress);

        // do not allow burning expired onToken
        require(block.timestamp < onToken.expiryTimestamp(), "C21");

        onToken.burnONtoken(_args.owner, _args.amount);

        // Cases:
        // New short amount needs less collateral or no at all cause long amount is enough

        // remove onToken from vault
        // collateralRation represents how much of already used collateral will be used after burn
        (FPI.FixedPointInt memory collateralRatio, uint256 newUsedLongAmount) = calculator.getAfterBurnCollateralRatio(
            vaults[_args.owner][_args.vaultId],
            _args.amount
        );
        (uint256[] memory freedCollateralAmounts, uint256[] memory freedCollateralValues) = vaults[_args.owner][
            _args.vaultId
        ].removeShort(_args.amount, collateralRatio, newUsedLongAmount);

        // Update onToken info regarding collaterization after burn
        onToken.reduceCollaterization(freedCollateralAmounts, freedCollateralValues, _args.amount);

        emit ShortONtokenBurned(onTokenAddress, _args.owner, msg.sender, _args.vaultId, _args.amount);
    }

    /**
     * @notice redeem an onToken after expiry, receiving the payout of the onToken in the collateral asset
     * @dev cannot be called when system is fullyPaused
     * @param _args RedeemArgs structure
     */
    function _redeem(Actions.RedeemArgs memory _args) internal {
        ONtokenInterface onToken = ONtokenInterface(_args.onToken);

        // check that onToken to redeem is whitelisted
        require(whitelist.isWhitelistedONtoken(_args.onToken), "C22");

        (address[] memory collaterals, address underlying, address strike, uint256 expiry) = _getONtokenDetails(
            address(onToken)
        );

        // only allow redeeming expired onToken
        require(block.timestamp >= expiry, "C23");

        // Check prices are finalised
        require(canSettleAssets(underlying, strike, collaterals, expiry), "C24");

        uint256[] memory payout = calculator.getPayout(_args.onToken, _args.amount);

        onToken.burnONtoken(msg.sender, _args.amount);

        for (uint256 i = 0; i < collaterals.length; i++) {
            if (payout[i] > 0) {
                pool.transferToUser(collaterals[i], _args.receiver, payout[i]);
            }
        }

        emit Redeem(_args.onToken, msg.sender, _args.receiver, collaterals, _args.amount, payout);
    }

    /**
     * @notice settle a vault after expiry, removing the net proceeds/collateral after both long and short onToken payouts have settled
     * @dev deletes a vault of vaultId after net proceeds/collateral is removed, cannot be called when system is fullyPaused
     * @param _args SettleVaultArgs structure
     */
    function _settleVault(Actions.SettleVaultArgs memory _args) internal onlyAuthorized(msg.sender, _args.owner) {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        (MarginVault.Vault memory vault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        ONtokenInterface onToken;

        // new scope to avoid stack too deep error
        // check if there is short or long onToken in vault
        // do not allow settling vault that have no short or long onToken
        // if there is a long onToken, burn it
        // store onToken address outside of this scope
        {
            bool hasLong = vault.longONtoken != address(0);

            onToken = ONtokenInterface(vault.shortONtoken);

            if (hasLong && vault.longAmount > 0) {
                ONtokenInterface longONtoken = ONtokenInterface(vault.longONtoken);

                longONtoken.burnONtoken(address(pool), vault.longAmount);
            }
        }

        (address[] memory collaterals, address underlying, address strike, uint256 expiry) = _getONtokenDetails(
            address(onToken)
        );

        // do not allow settling vault with un-expired onToken
        require(block.timestamp >= expiry, "C25");
        require(canSettleAssets(underlying, strike, collaterals, expiry), "C24");

        uint256[] memory payouts = calculator.getExcessCollateral(vault);

        delete vaults[_args.owner][_args.vaultId];

        for (uint256 i = 0; i < collaterals.length; i++) {
            if (payouts[i] != 0) {
                pool.transferToUser(collaterals[i], _args.to, payouts[i]);
            }
        }

        uint256 vaultId = _args.vaultId;
        address payoutRecipient = _args.to;

        emit VaultSettled(_args.owner, address(onToken), payoutRecipient, payouts, vaultId);
    }

    /**
     * @notice check if a vault id is valid for a given account owner address
     * @param _accountOwner account owner address
     * @param _vaultId vault id to check
     * @return True if the _vaultId is valid, False if not
     */
    function _checkVaultId(address _accountOwner, uint256 _vaultId) internal view returns (bool) {
        return ((_vaultId > 0) && (_vaultId <= accountVaultCounter[_accountOwner]));
    }

    /**
     * @dev get onToken detail
     * @return collaterals, of onToken
     * @return underlying, of onToken
     * @return strike, of onToken
     * @return expiry, of onToken
     */
    function _getONtokenDetails(address _onToken)
        internal
        view
        returns (
            address[] memory,
            address,
            address,
            uint256
        )
    {
        ONtokenInterface onToken = ONtokenInterface(_onToken);
        (address[] memory collaterals, , , , address underlying, address strike, , uint256 expiry, , ) = onToken
            .getONtokenDetails();
        return (collaterals, underlying, strike, expiry);
    }

    /**
     * @dev return if underlying, strike, collateral are all allowed to be settled
     * @param _underlying onToken underlying asset
     * @param _strike onToken strike asset
     * @param _collaterals onToken collateral assets
     * @param _expiry onToken expiry timestamp
     * @return True if the onToken has expired AND all oracle prices at the expiry timestamp have been finalized, False if not
     */
    function canSettleAssets(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        uint256 _expiry
    ) public view returns (bool) {
        bool canSettle = true;
        for (uint256 i = 0; i < _collaterals.length; i++) {
            canSettle = canSettle && oracle.isDisputePeriodOver(_collaterals[i], _expiry);
        }
        return
            canSettle &&
            oracle.isDisputePeriodOver(_underlying, _expiry) &&
            oracle.isDisputePeriodOver(_strike, _expiry);
    }

    /**
     * @dev updates the internal configuration of the controller
     */
    function _refreshConfigInternal() internal {
        whitelist = WhitelistInterface(addressbook.getWhitelist());
        oracle = OracleInterface(addressbook.getOracle());
        calculator = MarginCalculatorInterface(addressbook.getMarginCalculator());
        pool = MarginPoolInterface(addressbook.getMarginPool());
    }
}