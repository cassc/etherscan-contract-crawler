// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import {
    AccessControlEnumerable
} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWrap } from "./interfaces/IWrap.sol";
import { Multisig } from "./libraries/Multisig.sol";

abstract contract Wrap is IWrap, AccessControlEnumerable {
    using Multisig for Multisig.DualMultisig;

    using SafeERC20 for IERC20;

    /// @dev The role ID for addresses that can pause the contract.
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");

    /// @dev The role ID for addresses that has weak admin power.
    /// Weak admin can perform administrative tasks that don't risk user's funds.
    bytes32 public constant WEAK_ADMIN_ROLE = keccak256("WEAK_ADMIN");

    /// @dev Max protocol/validator fee that can be set by the owner.
    uint16 constant maxFeeBPS = 500; // should be less than 10,000

    /// @dev True if the contracts are paused, false otherwise.
    bool public paused;

    /// @dev Map token address to token info.
    mapping(address => TokenInfoStore) public tokenInfos;

    /// @dev Map mirror token address to token address.
    mapping(address => address) public mirrorTokens;

    /// @dev Map validator to its fee recipient.
    mapping(address => address) public validatorFeeRecipients;

    /// @dev Map tokens to validator index to fee that can be collected.
    mapping(address => mapping(uint256 => uint256)) public feeBalance;

    /// @dev Array of all the tokens added.
    /// @notice A token in the list might not be active.
    address[] public tokens;

    /// @dev Dual multisig to manage validators,
    /// attestations and request quorum.
    Multisig.DualMultisig internal multisig;

    /// @dev The number of deposits.
    uint256 public depositIndex;

    /// @dev Validator fee basis points.
    uint16 public validatorFeeBPS;

    /// @dev Address of the migrated contract.
    address public migratedContract;

    constructor(Multisig.Config memory config, uint16 _validatorFeeBPS) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WEAK_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(PAUSE_ROLE, WEAK_ADMIN_ROLE);
        multisig.configure(config);
        configureValidatorFees(_validatorFeeBPS);
    }

    /// @dev Hook to execute on deposit.
    /// @param token Address of the token being deposited.
    /// @param amount The amount being deposited.
    /// @return fee The fee charged to the depositor.
    function onDeposit(
        address token,
        uint256 amount
    ) internal virtual returns (uint256 fee);

    /// @dev Returns the gross deposit amount for the given net amount.
    /// @param netAmount The net amount expected after fee is subtracted from gross amount.
    /// @return grossAmount The gross amount for the given net amount.
    function grossDepositAmount(
        uint256 netAmount
    ) internal view virtual returns (uint256 grossAmount);

    /// @dev Hook to execute on successful bridging.
    /// @param token Address of the token being bridged.
    /// @param amount The amount being bridged.
    /// @param to The address where the bridged are being sent to.
    /// @return totalFee Total fee charged to the user.
    /// @return validatorFee Total fee minus the protocol fees.
    function onExecute(
        address token,
        uint256 amount,
        address to
    ) internal virtual returns (uint256 totalFee, uint256 validatorFee);

    /// @dev Hook executed before the bridge migration.
    /// @param _newContract Address of the new contract.
    function onMigrate(address _newContract) internal virtual;

    /// @dev Modifier to check if the contract is not paused.
    modifier isNotPaused() {
        if (paused == true) {
            revert ContractPaused();
        }
        _;
    }

    /// @dev Modifier to check if the contract is paused.
    modifier isPaused() {
        if (paused == false) {
            revert ContractNotPaused();
        }
        _;
    }

    /// @dev Modifier to check that contract is not already migrated.
    modifier notMigrated() {
        if (migratedContract != address(0)) {
            revert ContractMigrated();
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the token and amount is correct.
    modifier isValidTokenAmount(address token, uint256 amount) {
        TokenInfoStore storage t = tokenInfos[token];

        // Notice that amount should be greater than minAmountWithFees.
        // This is required as amount after the fees should be greater
        // than minAmount so that when this is approved it passes the
        // isValidMirrorTokenAmount check.
        // Notice that t.maxAmount is 0 for non existent and disabled tokens.
        // Therefore, this check also ensures txs of such tokens are reverted.
        if (t.maxAmount <= amount || t.minAmountWithFees > amount) {
            revert InvalidTokenAmount();
        }

        if (t.dailyLimit != 0) {
            // Reset daily limit if the day is passed after last update.
            if (block.timestamp > t.lastUpdated + 1 days) {
                t.lastUpdated = block.timestamp;
                t.consumedLimit = 0;
            }

            if (t.consumedLimit + amount > t.dailyLimit) {
                revert DailyLimitExhausted();
            }
            t.consumedLimit += amount;
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the token and amount is correct.
    modifier isValidMirrorTokenAmount(address mirrorToken, uint256 amount) {
        TokenInfoStore memory t = tokenInfos[mirrorTokens[mirrorToken]];
        if (t.maxAmount <= amount || t.minAmount > amount) {
            revert InvalidTokenAmount();
        }
        _;
    }

    /// @dev Modifier to make a function callable only when the recent block hash is valid.
    modifier withValidRecentBlockHash(
        bytes32 recentBlockHash,
        uint256 recentBlockNumber
    ) {
        // Prevent malicious validators from pre-producing attestation signatures.
        // This is helpful in case validators are temporarily compromised.
        // `blockhash(recentBlockNumber)` yields `0x0` when `recentBlockNumber < block.number - 256`.
        if (
            recentBlockHash == bytes32(0) ||
            blockhash(recentBlockNumber) != recentBlockHash
        ) {
            revert InvalidBlockHash();
        }
        _;
    }

    /// @inheritdoc IWrap
    function nextExecutionIndex() external view returns (uint256) {
        return multisig.nextExecutionIndex;
    }

    /// @inheritdoc IWrap
    function validatorInfo(
        address validator
    ) external view returns (Multisig.SignerInfo memory) {
        return multisig.signers[validator];
    }

    /// @inheritdoc IWrap
    function attesters(
        bytes32 hash
    ) external view returns (uint16[] memory attesterIndexes, uint16 count) {
        return multisig.getApprovers(hash);
    }

    /// @dev Internal function to calculate fees by amount and BPS.
    function calculateFee(
        uint256 amount,
        uint16 feeBPS
    ) internal pure returns (uint256) {
        // 10,000 is 100%
        return (amount * feeBPS) / 10000;
    }

    /// @inheritdoc IWrap
    function deposit(
        address token,
        uint256 amount,
        address to
    )
        external
        isNotPaused
        isValidTokenAmount(token, amount)
        returns (uint256 id)
    {
        if (to == address(0)) revert InvalidToAddress();
        id = depositIndex;
        depositIndex++;
        uint256 fee = onDeposit(token, amount);
        emit Deposit(id, token, amount - fee, to, fee);
    }

    /// @dev Internal function to calculate the hash of the request.
    function hashRequest(
        uint256 id,
        address token,
        uint256 amount,
        address to
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, token, amount, to));
    }

    /// @dev Internal function to approve and/or execute a given request.
    function _approveExecute(
        uint256 id,
        address mirrorToken,
        uint256 amount,
        address to
    ) private isNotPaused isValidMirrorTokenAmount(mirrorToken, amount) {
        // If the request ID is lower than the last executed ID then simply ignore the request.
        if (id < multisig.nextExecutionIndex) {
            return;
        }

        bytes32 hash = hashRequest(id, mirrorToken, amount, to);
        Multisig.RequestStatusTransition transition = multisig.tryApprove(
            msg.sender,
            hash,
            id
        );
        if (transition == Multisig.RequestStatusTransition.NULLToUndecided) {
            emit Requested(id, mirrorToken, amount, to);
        }

        if (multisig.tryExecute(hash, id)) {
            address token = mirrorTokens[mirrorToken];
            (uint256 totalFee, uint256 validatorFee) = onExecute(
                token,
                amount,
                to
            );
            {
                (uint16[] memory approvers, uint16 approverCount) = multisig
                    .getApprovers(hash);
                uint256 feeToIndividualValidator = validatorFee / approverCount;
                mapping(uint256 => uint256)
                    storage tokenFeeBalance = feeBalance[token];
                for (uint16 i = 0; i < approverCount; i++) {
                    tokenFeeBalance[approvers[i]] += feeToIndividualValidator;
                }
            }
            emit Executed(
                id,
                mirrorToken,
                token,
                amount - totalFee,
                to,
                totalFee
            );
        }
    }

    /// @inheritdoc IWrap
    function approveExecute(
        uint256 id,
        address mirrorToken,
        uint256 amount,
        address to,
        bytes32 recentBlockHash,
        uint256 recentBlockNumber
    ) external withValidRecentBlockHash(recentBlockHash, recentBlockNumber) {
        _approveExecute(id, mirrorToken, amount, to);
    }

    /// @inheritdoc IWrap
    function batchApproveExecute(
        RequestInfo[] calldata requests,
        bytes32 recentBlockHash,
        uint256 recentBlockNumber
    ) external withValidRecentBlockHash(recentBlockHash, recentBlockNumber) {
        for (uint256 i = 0; i < requests.length; i++) {
            _approveExecute(
                requests[i].id,
                requests[i].token,
                requests[i].amount,
                requests[i].to
            );
        }
    }

    function _configureTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 dailyLimit,
        bool newToken
    ) internal {
        uint256 currMinAmount = tokenInfos[token].minAmount;
        if (
            minAmount == 0 ||
            (newToken ? currMinAmount != 0 : currMinAmount == 0)
        ) {
            revert InvalidTokenConfig();
        }

        // configuring token also resets the daily volume limit
        TokenInfoStore memory tokenInfoStore = TokenInfoStore(
            maxAmount,
            minAmount,
            grossDepositAmount(minAmount),
            dailyLimit,
            0,
            block.timestamp
        );
        tokenInfos[token] = tokenInfoStore;
    }

    /// @inheritdoc IWrap
    function configureToken(
        address token,
        TokenInfo calldata tokenInfo
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        _configureTokenInfo(
            token,
            tokenInfo.minAmount,
            tokenInfo.maxAmount,
            tokenInfo.dailyLimit,
            false
        );
    }

    /// @inheritdoc IWrap
    function configureValidatorFees(
        uint16 _validatorFeeBPS
    ) public onlyRole(WEAK_ADMIN_ROLE) {
        if (_validatorFeeBPS > maxFeeBPS) {
            revert FeeExceedsMaxFee();
        }
        validatorFeeBPS = _validatorFeeBPS;
    }

    /// @dev Internal function to add a new token.
    /// @param token Token that will be deposited in the contract.
    /// @param mirrorToken Token that will be deposited in the mirror contract.
    /// @param tokenInfo Token info associated with the token.
    function _addToken(
        address token,
        address mirrorToken,
        TokenInfo calldata tokenInfo
    ) internal {
        if (mirrorTokens[mirrorToken] != address(0)) {
            revert InvalidTokenConfig();
        }

        _configureTokenInfo(
            token,
            tokenInfo.minAmount,
            tokenInfo.maxAmount,
            tokenInfo.dailyLimit,
            true
        );
        tokens.push(token);
        mirrorTokens[mirrorToken] = token;
    }

    /// @inheritdoc IWrap
    function configureMultisig(
        Multisig.Config calldata config
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig.configure(config);
    }

    /// @inheritdoc IWrap
    function pause() external onlyRole(PAUSE_ROLE) {
        paused = true;
    }

    /// @inheritdoc IWrap
    function unpause() external notMigrated onlyRole(WEAK_ADMIN_ROLE) {
        paused = false;
    }

    /// @inheritdoc IWrap
    function addValidator(
        address validator,
        bool isFirstCommittee,
        address feeRecipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig.addSigner(validator, isFirstCommittee);
        validatorFeeRecipients[validator] = feeRecipient;
    }

    /// @inheritdoc IWrap
    function removeValidator(
        address validator
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        multisig.removeSigner(validator);
    }

    /// @inheritdoc IWrap
    function configureValidatorFeeRecipient(
        address validator,
        address feeRecipient
    ) external onlyRole(WEAK_ADMIN_ROLE) {
        validatorFeeRecipients[validator] = feeRecipient;
    }

    /// @inheritdoc IWrap
    function claimValidatorFees(address validator) public {
        address feeRecipient = validatorFeeRecipients[validator];

        if (feeRecipient == address(0)) {
            revert InvalidFeeRecipient();
        }

        uint16 index = multisig.signers[validator].index;
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenValidatorFee = feeBalance[token][index];
            feeBalance[token][index] = 0;
            IERC20(token).safeTransfer(feeRecipient, tokenValidatorFee);
        }
    }

    /// @inheritdoc IWrap
    function forceSetNextExecutionIndex(
        uint256 index
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig.forceSetNextExecutionIndex(index);
    }

    /// @inheritdoc IWrap
    function migrate(
        address _newContract
    ) public isPaused notMigrated onlyRole(DEFAULT_ADMIN_ROLE) {
        onMigrate(_newContract);
        migratedContract = _newContract;
    }
}