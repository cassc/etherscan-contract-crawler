// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {LlamaPay, LlamaPayFactory} from "llamapay/LlamaPayFactory.sol";
import {IERC20, IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

import {BudgetModule, Budget} from "../BudgetModule.sol";
import {ForwarderLib} from "./ForwarderLib.sol";

/**
 * @title LlamaPayStreams
 * @author Firm ([email protected])
 * @notice Budget module to manage LlamaPay v1 streams from Budget allowances
 */
contract LlamaPayStreams is BudgetModule {
    using ForwarderLib for ForwarderLib.Forwarder;

    string public constant moduleId = "org.firm.budget.llamapay-streams";
    uint256 public constant moduleVersion = 1;

    // See https://github.com/LlamaPay/llamapay/blob/90d18e11b94b02208100b3ac8756955b1b726d37/contracts/LlamaPay.sol#L16
    uint256 internal constant LLAMAPAY_DECIMALS = 20;
    LlamaPayFactory internal immutable llamaPayFactory;

    struct StreamConfig {
        bool enabled;
        IERC20 token;
        uint8 decimals;
        uint40 prepayBuffer;
    }

    mapping(uint256 => StreamConfig) public streamConfigs;

    event StreamsConfigured(uint256 indexed allowanceId, LlamaPay streamer, ForwarderLib.Forwarder forwarder);
    event PrepayBufferSet(uint256 indexed allowanceId, uint40 prepayBuffer);
    event DepositRebalanced(uint256 indexed allowanceId, bool isDeposit, uint256 amount, address sender);

    error StreamsAlreadyConfigured(uint256 allowanceId);
    error NoStreamsToRebalance(uint256 allowanceId);
    error InvalidPrepayBuffer(uint256 allowanceId);
    error StreamsNotConfigured(uint256 allowanceId);
    error UnsupportedTokenDecimals();
    error ApproveFailed(uint256 allowanceId);

    constructor(LlamaPayFactory llamaPayFactory_) {
        // NOTE: This immutable value is set in the constructor of the implementation contract
        // and all proxies will read from it as it gets saved in the bytecode
        llamaPayFactory = llamaPayFactory_;
    }

    // Note: Initialization is done in the BudgetModule.initialize since
    // LlamaPayStreams doesn't have any other state that needs to be initialized

    ////////////////////////
    // Config
    ////////////////////////

    /**
     * @notice Configure the streams for the allowance
     * @param allowanceId The allowance ID
     * @param prepayBuffer The prepay buffer in seconds
     */
    function configure(uint256 allowanceId, uint40 prepayBuffer) external onlyAllowanceAdmin(allowanceId) {
        StreamConfig storage streamConfig = streamConfigs[allowanceId];

        if (streamConfig.enabled) {
            revert StreamsAlreadyConfigured(allowanceId);
        }

        // Due to how LlamaPay v1 works, intermediate forwarder contracts are used to manage deposits
        // in LlamaPay separately for each allowance. These are the contracts that appear as payers on LlamaPay.
        (LlamaPay streamer, ForwarderLib.Forwarder forwarder) = _setupStreamsForAllowance(streamConfig, allowanceId);

        emit StreamsConfigured(allowanceId, streamer, forwarder);

        _setPrepayBuffer(allowanceId, streamConfig, prepayBuffer);
    }

    /**
     * @notice Set the prepay buffer for the allowance
     * @param allowanceId The allowance ID
     * @param prepayBuffer The prepay buffer in seconds
     */
    function setPrepayBuffer(uint256 allowanceId, uint40 prepayBuffer) external onlyAllowanceAdmin(allowanceId) {
        _setPrepayBuffer(allowanceId, _getStreamConfig(allowanceId), prepayBuffer);
        rebalance(allowanceId);
    }

    function _setPrepayBuffer(uint256 allowanceId, StreamConfig storage streamConfig, uint40 prepayBuffer) internal {
        if (prepayBuffer == 0) {
            revert InvalidPrepayBuffer(allowanceId);
        }

        streamConfig.prepayBuffer = prepayBuffer;

        emit PrepayBufferSet(allowanceId, prepayBuffer);
    }

    ////////////////////////
    // STREAM MANAGEMENT
    ////////////////////////

    /**
     * @notice Start a new stream from the allowance
     * @param allowanceId The allowance ID
     * @param to The recipient of the stream
     * @param amountPerSec The amount of tokens per second to stream (Always 20 decimals for LlamaPay)
     * @param description The description of the stream
     */
    function startStream(uint256 allowanceId, address to, uint256 amountPerSec, string calldata description)
        external
        onlyAllowanceAdmin(allowanceId)
    {
        _executeAndRebalance(
            allowanceId, abi.encodeCall(LlamaPay.createStreamWithReason, (to, uint216(amountPerSec), description))
        );
    }

    /**
     * @notice Modify an existing stream
     * @dev LlamaPay cancels and creates a new stream under the hood
     * @param allowanceId The allowance ID
     * @param oldTo The old recipient of the stream
     * @param oldAmountPerSec The old amount of tokens per second to stream (Always 20 decimals for LlamaPay)
     * @param newTo The new recipient of the stream
     * @param newAmountPerSec The new amount of tokens per second to stream (Always 20 decimals for LlamaPay)
     */
    function modifyStream(
        uint256 allowanceId,
        address oldTo,
        uint256 oldAmountPerSec,
        address newTo,
        uint256 newAmountPerSec
    ) external onlyAllowanceAdmin(allowanceId) {
        _executeAndRebalance(
            allowanceId,
            abi.encodeCall(LlamaPay.modifyStream, (oldTo, uint216(oldAmountPerSec), newTo, uint216(newAmountPerSec)))
        );
    }

    /**
     * @notice Pause a stream
     * @param allowanceId The allowance ID
     * @param to The recipient of the stream
     * @param amountPerSec The amount of tokens per second streamed (Always 20 decimals for LlamaPay)
     */
    function pauseStream(uint256 allowanceId, address to, uint256 amountPerSec)
        external
        onlyAllowanceAdmin(allowanceId)
    {
        _executeAndRebalance(allowanceId, abi.encodeCall(LlamaPay.pauseStream, (to, uint216(amountPerSec))));
    }

    /**
     * @notice Cancel a stream
     * @param allowanceId The allowance ID
     * @param to The recipient of the stream
     * @param amountPerSec The amount of tokens per second streamed (Always 20 decimals for LlamaPay)
     */
    function cancelStream(uint256 allowanceId, address to, uint256 amountPerSec)
        external
        onlyAllowanceAdmin(allowanceId)
    {
        _executeAndRebalance(allowanceId, abi.encodeCall(LlamaPay.cancelStream, (to, uint216(amountPerSec))));
    }

    function _executeAndRebalance(uint256 allowanceId, bytes memory data) internal {
        StreamConfig storage streamConfig = _getStreamConfig(allowanceId);
        IERC20 token = streamConfig.token;
        LlamaPay streamer = streamerForToken(token);
        ForwarderLib.Forwarder forwarder = ForwarderLib.getForwarder(_forwarderSalt(allowanceId, token));

        forwarder.forwardChecked(address(streamer), data);

        _rebalance(allowanceId, streamConfig, token, streamer, forwarder);
    }

    ////////////////////////
    // REBALANCING AND DEPOSIT MANAGEMENT
    ////////////////////////

    /**
     * @notice Rebalance LlamaPay deposit for streams from allowance
     * @dev This function is unprotected so it can be called by anyone who wishes to rebalance
     * @param allowanceId The allowance ID
     */
    function rebalance(uint256 allowanceId) public {
        StreamConfig storage streamConfig = _getStreamConfig(allowanceId);
        IERC20 token = streamConfig.token;

        _rebalance(
            allowanceId,
            streamConfig,
            token,
            streamerForToken(token),
            ForwarderLib.getForwarder(_forwarderSalt(allowanceId, token))
        );
    }

    /**
     * @dev Rebalances the amount that should be deposited to LlamaPay based on the current state of the streams
     */
    function _rebalance(
        uint256 allowanceId,
        StreamConfig storage streamConfig,
        IERC20 token,
        LlamaPay streamer,
        ForwarderLib.Forwarder forwarder
    ) internal {
        uint256 existingBalance;
        uint256 targetAmount;
        {
            (uint40 lastUpdate, uint216 paidPerSec) = streamer.payers(forwarder.addr());

            if (lastUpdate == 0) {
                revert NoStreamsToRebalance(allowanceId);
            }

            existingBalance = streamer.balances(forwarder.addr());
            uint256 secondsToFund = uint40(block.timestamp) + streamConfig.prepayBuffer - lastUpdate;
            targetAmount = secondsToFund * paidPerSec;
        }

        if (targetAmount > existingBalance) {
            uint256 amount = targetAmount - existingBalance;
            uint256 tokenAmount = amount / (10 ** (LLAMAPAY_DECIMALS - streamConfig.decimals));

            if (tokenAmount == 0) {
                return;
            }

            // The first time we do a deposit, we leave one token in the forwarder
            // as a gas optimization
            bool leaveExtraToken = existingBalance == 0 && token.balanceOf(forwarder.addr()) == 0;

            budget().executePayment(
                allowanceId, forwarder.addr(), tokenAmount + (leaveExtraToken ? 1 : 0), "Streams deposit"
            );
            forwarder.forwardChecked(address(streamer), abi.encodeCall(streamer.deposit, (tokenAmount)));

            emit DepositRebalanced(allowanceId, true, tokenAmount, msg.sender);
        } else {
            uint256 amount = existingBalance - targetAmount;
            uint256 tokenAmount = amount / (10 ** (LLAMAPAY_DECIMALS - streamConfig.decimals));

            if (tokenAmount == 0) {
                return;
            }

            forwarder.forwardChecked(address(streamer), abi.encodeCall(streamer.withdrawPayer, (amount)));

            Budget budget = budget();
            if (token.allowance(forwarder.addr(), address(budget)) < tokenAmount) {
                forwarder.forwardChecked(
                    address(token), abi.encodeCall(IERC20.approve, (address(budget), type(uint256).max))
                );
            }

            forwarder.forwardChecked(
                address(budget), abi.encodeCall(budget.debitAllowance, (allowanceId, tokenAmount, "Streams withdraw"))
            );

            emit DepositRebalanced(allowanceId, false, tokenAmount, msg.sender);
        }
    }

    function _getStreamConfig(uint256 allowanceId) internal view returns (StreamConfig storage streamConfig) {
        streamConfig = streamConfigs[allowanceId];

        if (!streamConfig.enabled) {
            revert StreamsNotConfigured(allowanceId);
        }
    }

    function _setupStreamsForAllowance(StreamConfig storage streamConfig, uint256 allowanceId)
        internal
        returns (LlamaPay streamer, ForwarderLib.Forwarder forwarder)
    {
        // NOTE: Caller must have used `onlyAllowanceAdmin` modifier to ensure that the allowance exists
        (,,, address token,,,,) = budget().allowances(allowanceId);

        uint8 decimals = IERC20Metadata(token).decimals();
        if (decimals > 20) {
            revert UnsupportedTokenDecimals();
        }

        streamConfig.enabled = true;
        streamConfig.token = IERC20(token);
        streamConfig.decimals = decimals;

        (address streamer_, bool isDeployed) = llamaPayFactory.getLlamaPayContractByToken(token);
        streamer = LlamaPay(streamer_);
        if (!isDeployed) {
            llamaPayFactory.createLlamaPayContract(token);
        }

        forwarder = ForwarderLib.create(_forwarderSalt(allowanceId, IERC20(token)));
        bytes memory retData =
            forwarder.forwardChecked(address(token), abi.encodeCall(IERC20.approve, (streamer_, type(uint256).max)));
        if (retData.length > 0) {
            if (retData.length != 32 || abi.decode(retData, (bool)) == false) {
                revert ApproveFailed(allowanceId);
            }
        }
    }

    function streamerForToken(IERC20 token) public view returns (LlamaPay) {
        (address streamer,) = llamaPayFactory.getLlamaPayContractByToken(address(token));
        return LlamaPay(streamer);
    }

    function forwarderForAllowance(uint256 allowanceId) public view returns (ForwarderLib.Forwarder) {
        StreamConfig storage streamConfig = _getStreamConfig(allowanceId);
        return ForwarderLib.getForwarder(_forwarderSalt(allowanceId, streamConfig.token));
    }

    function _forwarderSalt(uint256 allowanceId, IERC20 token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(allowanceId, token));
    }
}