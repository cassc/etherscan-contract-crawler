//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ChainPortal
 * @author Oddcod3 (@oddcod3)
 * 
 * @dev This abstract contract contains the core logic for a generic chain portal.
 * @dev The ChainPortal empowers cross-chain communication and token bridging between
 *      different portals deployed across multiple EVM chains.
 * 
 * @notice Functionalities:
 * - send cross-chain actions to be executed by the portal on the destination chain
 * - receive and execute cross-chain actions sent from other portals deployed across chains 
 * - bridge allowed tokens to a receving portal on destination chain
 * - combine cross-chain actions and token bridging in a single message 
 *
 * @dev This contract is the base class inherited from BaseChainPortal and CrossChainPortal.
 */
abstract contract ChainPortal is CCIPReceiver, AutomationCompatibleInterface {

    using SafeERC20 for IERC20;
    
    ///////////////////////
    // Errors            //
    ///////////////////////

    error ChainPortal__ActionNotExecutable();
    error ChainPortal__ActionExecutionFailed();
    error ChainPortal__ActionNotPending(uint128 actionId);
    error ChainPortal__NoActionQueued();
    error ChainPortal__ZeroTargets();
    error ChainPortal__ZeroAddressTarget();
    error ChainPortal__LaneNotAvailable();
    error ChainPortal__InvalidPortal();
    error ChainPortal__InvalidChain(uint64 chainSelector);
    error ChainPortal__InvalidActionId(uint128 actionId);
    error ChainPortal__ArrayLengthMismatch();

    ///////////////////////
    // Types             //
    ///////////////////////

    struct CrossChainAction {
        address sender;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    struct ActionInfo {
        uint64 timestampQueued;
        uint64 sourceChainSelector;
        ActionState actionState;
    }

    struct ActionQueueState {
        uint64 nextActionId;
        uint64 lastActionId;
        uint64 executionDelay;
        uint64 lastTimePendingActionExecuted;    
    }

    enum ActionState {
        EMPTY,
        PENDING,
        EXECUTED,
        ABORTED
    }

    ///////////////////////
    // State Variables   //
    ///////////////////////

    ActionQueueState private s_queueState;
    LinkTokenInterface private immutable i_linkToken;

    /// @dev Mapping to action struct from action id
    mapping(uint64 actionId => CrossChainAction action) private s_actions;
    /// @dev Mapping to action state from action id
    mapping(uint64 actionId => ActionInfo actionInfo) private s_actionInfo;
    /// @dev Mapping to destination portal address from destination chain selector
    mapping(uint64 destChainSelector => address portal) internal s_chainPortal;
    /// @dev Nested mapping of authorized communication lanes (sender -> chainSelector -> target)
    mapping(address sender => mapping(uint64 destChainSelector => mapping(address target => bool))) private s_lanes;

    ///////////////////////
    // Events            //
    ///////////////////////

    event ExecutionDelayChanged(uint64 indexed executionDelay);
    event OutboundActionSent(bytes32 indexed messageId);
    event InboundActionQueued(uint256 indexed actionId, bytes32 indexed messageId);
    event ActionAborted(uint256 indexed actionId);
    event QueuedActionExecuted(uint256 indexed actionId);
    event InboundActionExecuted(bytes32 indexed messageId);
    event LanesChanged(
        address[] indexed senders,
        address[] indexed targets,
        uint64[] indexed chainSelectors,
        bool[] isEnabled
    );
    event ChainPortalsChanged(uint64[] indexed chainSelectors, address[] indexed portals);

    ///////////////////////
    // Modifiers         //
    ///////////////////////

    modifier onlyAuthorizedLanes(uint64 chainSelector, address[] memory targets) {
        _revertIfNotAuthorizedLanes(chainSelector, targets);
        _;
    }

    ////////////////////////
    // Functions          //
    ////////////////////////

    constructor(address ccipRouter, address linkToken, uint64 executionDelay) CCIPReceiver(ccipRouter) {
        i_linkToken = LinkTokenInterface(linkToken);
        i_linkToken.approve(ccipRouter, type(uint256).max);
        s_queueState.lastTimePendingActionExecuted = uint64(block.timestamp);
        _setExecutionDelay(executionDelay);
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    // @inheritdoc IChainPortal
    function abortAction(uint64 actionId) external virtual;

    // @inheritdoc IChainPortal
    function setExecutionDelay(uint64 executionDelay) external virtual;

    // @inheritdoc IChainPortal
    function setChainPortals(uint64[] calldata chainSelectors, address[] calldata portals) external virtual;

    // @inheritdoc IChainPortal
    function setLanes(
        address[] calldata senders,
        uint64[] calldata destChainSelectors,
        address[] calldata targets,
        bool[] calldata enableds
    ) external virtual;

    /**
     * @dev Sends a cross-chain action and/or bridges tokens to another portal on destination chain.
     * @param chainSelector: Chain selector of the destination chain
     * @param gasLimit: Gas limit for execution of the action on destination chain
     * @param targets: Array of target addresses to interact with
     * @param values: Array of values of native destination token to send to target addresses
     * @param signatures: Array of function signatures to be called for target addresses
     * @param calldatas: Array of calldatas for low level calls to target addresses
     * @param tokens: Array of tokens to be bridged to the destination chain
     * @param amounts: Array of token amounts to be bridged to destination chain
     * @notice Tokens are bridged to the destination portal address
     * @notice Approvals to this portal of token amounts to be bridged is required before calling this function
     */
    function teleport(
        uint64 chainSelector,
        uint64 gasLimit,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyAuthorizedLanes(chainSelector, targets) {
        if (
            targets.length != values.length || values.length != signatures.length
                || signatures.length != calldatas.length || tokens.length != amounts.length
        ) {
            revert ChainPortal__ArrayLengthMismatch();
        }
        if(targets.length == 0) {
            revert ChainPortal__ZeroTargets();
        }
        address chainPortal = s_chainPortal[chainSelector];
        if (chainPortal == address(0)) {
            revert ChainPortal__InvalidChain(chainSelector);
        }
        Client.EVM2AnyMessage memory message = _buildMessage(
            gasLimit, 
            chainPortal, 
            targets, 
            values, 
            signatures, 
            calldatas, 
            _handleTokensBridging(tokens, amounts)
        );
        bytes32 _messageId = IRouterClient(i_router).ccipSend(chainSelector, message);
        emit OutboundActionSent(_messageId);
    }

    /**
     * @notice Chainlink Automation
     * @inheritdoc AutomationCompatibleInterface
     */
    function performUpkeep(bytes calldata) external override {
        _executeNextPendingActionQueued();
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    /**
     * @notice This function is used by the CCIP router to deliver a message.
     * @notice If the execution delay is 0, this function immediately executes the received action.
     * @param message The Any2EVMMessage struct received from CCIP, containing a cross-chain action to be executed.
     */ 
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));
        address sourceChainPortal = s_chainPortal[message.sourceChainSelector];
        if (sourceChainPortal == address(0)) {
            revert ChainPortal__InvalidChain(message.sourceChainSelector);
        }
        if (sender != s_chainPortal[message.sourceChainSelector]) {
            revert ChainPortal__InvalidPortal();
        }
        ActionQueueState storage queueState = s_queueState;
        CrossChainAction memory action = abi.decode(message.data, (CrossChainAction));
        if(queueState.executionDelay > 0) {
            uint64 lastActionId = queueState.lastActionId;
            queueState.lastActionId = lastActionId + 1;
            s_actions[lastActionId] = action;
            s_actionInfo[lastActionId] = ActionInfo(uint64(block.timestamp), message.sourceChainSelector, ActionState.PENDING);
            emit InboundActionQueued(lastActionId, message.messageId);
        } else {
            _executeAction(message.sourceChainSelector, action);
            emit InboundActionExecuted(message.messageId);
        }
    }

    /**
     * @notice Executes the next pending action in the queue, skipping aborted actions.
     * @dev If there is no pending action queued, the function will revert.
     * @dev The first pending action that is not aborted will be executed.
     * @dev This function includes a call to the internal function _verifyActionRestrictions.
     * @dev Inheriting contracts can override _verifyActionRestrictions for additional checks before execution.
     */
    function _executeNextPendingActionQueued() internal {
        uint64 nextActionId = s_queueState.nextActionId;
        ActionInfo storage actionInfo = s_actionInfo[nextActionId];
        while(actionInfo.actionState == ActionState.ABORTED) {
            nextActionId += 1;
            actionInfo = s_actionInfo[nextActionId];
        }
        if(actionInfo.actionState == ActionState.EMPTY || actionInfo.actionState == ActionState.EXECUTED) {
            revert ChainPortal__NoActionQueued();
        }
        actionInfo.actionState = ActionState.EXECUTED;
        s_queueState.nextActionId = nextActionId + 1;
        s_queueState.lastTimePendingActionExecuted = uint64(block.timestamp);
        if (_isActionExecutable(actionInfo.timestampQueued)) {
            _executeAction(actionInfo.sourceChainSelector, s_actions[nextActionId]);
            emit QueuedActionExecuted(nextActionId);
        } else {
            revert ChainPortal__ActionNotExecutable();
        }
    }

    /**
     * @notice Executes the next pending action in the queue, skipping aborted actions.
     * @dev If there is no pending action queued, the function will revert.
     * @dev The first pending action that is not aborted will be executed.
     */
    function _executeAction(uint64 sourceChainSelector, CrossChainAction memory action) private {
        bool success;
        bytes memory callData;
        bytes memory resultData;
        _verifyActionRestrictions(action.sender, action.targets, sourceChainSelector);
        for (uint256 i; i < action.targets.length;) {
            if(bytes(action.signatures[i]).length == 0) {
                callData = action.calldatas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(action.signatures[i]))), action.calldatas[i]);
            }
            (success, resultData) = action.targets[i].call{value: action.values[i]}(callData);
            if (!success) {
                if (resultData.length > 0) {
                    assembly {
                        let size := mload(resultData)
                        revert(add(32, resultData), size)
                    }
                } else {
                    revert ChainPortal__ActionExecutionFailed();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param actionId: ID of the action to be aborted 
     */
    function _abortAction(uint64 actionId) internal {
        ActionQueueState memory queueState = s_queueState;
        if (actionId < queueState.nextActionId || actionId >= queueState.lastActionId) {
            revert ChainPortal__InvalidActionId(actionId);
        }
        ActionInfo storage actionInfo = s_actionInfo[actionId];
        if (actionInfo.actionState != ActionState.PENDING) {
            revert ChainPortal__ActionNotPending(actionId);
        }
        actionInfo.actionState = ActionState.ABORTED;
        emit ActionAborted(actionId);
    }

    /**
     * @param executionDelay The minimum execution delay that actions must be subjected to between being queued and being executed.
     */
    function _setExecutionDelay(uint64 executionDelay) internal {
        s_queueState.executionDelay = executionDelay;
        emit ExecutionDelayChanged(executionDelay);
    }

    /**
     * @param chainSelectors Array of chain selectors.
     * @param portals Array of portal addresses corresponding to each chain selector in the chainSelectors array.
     * @notice The chainSelectors and portals arrays must have the same length.
     */
    function _setChainPortals(uint64[] calldata chainSelectors, address[] calldata portals) internal {
        if (chainSelectors.length != portals.length) {
            revert ChainPortal__ArrayLengthMismatch();
        }
        for (uint256 i; i < chainSelectors.length;) {
            if(!IRouterClient(i_router).isChainSupported(chainSelectors[i])){
                revert IRouterClient.UnsupportedDestinationChain(chainSelectors[i]);
            }
            s_chainPortal[chainSelectors[i]] = portals[i];
            unchecked {
                ++i;
            }
        }
        emit ChainPortalsChanged(chainSelectors, portals);
    }

    // @inheritdoc IChainPortal
    function _setLanes(
        address[] calldata senders,
        uint64[] calldata destChainSelectors,
        address[] calldata targets,
        bool[] calldata enableds
    ) internal {
        if (
            senders.length != targets.length || 
            targets.length != destChainSelectors.length || 
            destChainSelectors.length != enableds.length
        ) {
            revert ChainPortal__ArrayLengthMismatch();
        }
        for (uint256 i; i < senders.length;) {
            if(targets[i] == address(0)) {
                revert ChainPortal__ZeroAddressTarget();
            }
            s_lanes[senders[i]][destChainSelectors[i]][targets[i]] = enableds[i];
            unchecked {
                ++i;
            }
        }
        emit LanesChanged(senders, targets, destChainSelectors, enableds);
    }

    ////////////////////////
    // Private Functions  //
    ////////////////////////

    /**
     * @param tokens Array of tokens to be bridged.
     * @param amounts Array of token amounts to be bridged.
     * @notice Transfer tokens from msg.sender to this portal and approve tokens to CCIP router.
     */
    function _handleTokensBridging(
        address[] memory tokens, 
        uint256[] memory amounts
    ) private returns(Client.EVMTokenAmount[] memory) {
        IERC20 token;
        Client.EVMTokenAmount[] memory tokensData = new Client.EVMTokenAmount[](tokens.length);
        for (uint256 i; i < tokens.length;) {
            tokensData[i].token = tokens[i];
            tokensData[i].amount = amounts[i];
            token = IERC20(tokens[i]);
            token.safeTransferFrom(msg.sender, address(this), amounts[i]);
            token.approve(i_router, amounts[i]);
            unchecked {
                ++i;
            }
        }
        return tokensData;
    }

    /////////////////////////////
    // Internal View Functions //
    /////////////////////////////

    function _getActionById(uint64 actionId) internal view returns (CrossChainAction memory) {
        return s_actions[actionId];
    }

    function _getActionStateById(uint64 actionId) internal view returns (ActionInfo memory) {
        return s_actionInfo[actionId];
    }

    function _getActionQueueState() internal view returns (ActionQueueState memory) {
        return s_queueState;
    }

    /**
     * @notice This function must be overridden by inheriting contracts to perform additional checks before executing an action.
     */
    function _verifyActionRestrictions(address sender, address[] memory targets, uint64 sourceChainSelector)
        internal
        view
        virtual;

    /////////////////////////////
    // Private View Functions  //
    /////////////////////////////

    /**
     * @param gasLimit Gas limit used for the execution of the action on the destination chain.
     * @param chainPortal Address of the portal on the destination chain.
     * @param targets Array of target addresses to interact with.
     * @param values Array of values of the native destination token to send to the target addresses.
     * @param signatures Array of function signatures to be called at the target addresses.
     * @param calldatas Array of encoded function call parameters.
     * @param tokensData Array of token addresses and amounts to be bridged to the destination chain.
     * @notice This function builds and returns the EVM2AnyMessage struct from the given parameters.
     */
    function _buildMessage(
        uint64 gasLimit,
        address chainPortal,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        Client.EVMTokenAmount[] memory tokensData
    ) private view returns (Client.EVM2AnyMessage memory) {
        CrossChainAction memory action = CrossChainAction({
            sender: msg.sender,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas
        });
        return Client.EVM2AnyMessage({
            receiver: abi.encode(chainPortal),
            data: abi.encode(action),
            tokenAmounts: tokensData,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})),
            feeToken: address(i_linkToken)
        });
    }

    /**
     * @param timestampQueued Timestamp of when the action has been queued.
     */
    function _isActionExecutable(uint64 timestampQueued) private view returns (bool) {
        return timestampQueued != 0 && block.timestamp - timestampQueued > s_queueState.executionDelay;
    }

    /**
     * @param chainSelector Selector of the destination chain.
     * @param targets Array of target addresses.
     * @notice Revert if the action includes targets on destination chains with no lanes available from this portal for msg.sender.
     * @notice Save gas by skipping storage loads if equal targets are in sequence.
     */
    function _revertIfNotAuthorizedLanes(uint64 chainSelector, address[] memory targets) private view {
        address tempTarget;
        for (uint256 i; i < targets.length;i++) {
            if(targets[i] != tempTarget) {
                if (!s_lanes[msg.sender][chainSelector][targets[i]]) {
                    revert ChainPortal__LaneNotAvailable();
                }
            }
            tempTarget = targets[i];
            unchecked {
                ++i;
            }
        }
    }

    /////////////////////////////
    // External View Functions //
    /////////////////////////////

    // @inheritdoc IChainPortal
    function getActionQueueState() external view returns(
        uint64 nextActionId,
        uint64 lastActionId,
        uint64 executionDelay,
        uint64 lastTimePendingActionExecuted
    ) {
        ActionQueueState memory queueState = s_queueState;
        nextActionId = queueState.nextActionId;
        lastActionId = queueState.lastActionId;
        executionDelay = queueState.executionDelay;
        lastTimePendingActionExecuted = queueState.lastTimePendingActionExecuted;
    }

    // @inheritdoc IChainPortal
    function getActionById(uint64 actionId) external view returns (
        address sender,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        CrossChainAction memory action = _getActionById(actionId);
        sender = action.sender;
        targets = action.targets;
        values = action.values;
        signatures = action.signatures;
        calldatas = action.calldatas;
    }

    // @inheritdoc IChainPortal
    function getActionInfoById(uint64 actionId) external view returns (
        uint64 timestampQueued,
        uint64 fromChainSelector,
        uint8 actionState
    ) {
        ActionInfo memory actionInfo = _getActionStateById(actionId);
        timestampQueued = actionInfo.timestampQueued;
        fromChainSelector = actionInfo.sourceChainSelector;
        actionState = uint8(actionInfo.actionState);
    }

    // @inheritdoc IChainPortal
    function isAuthorizedLane(address sender, uint64 destChainSelector, address target) external view returns (bool) {
        return s_lanes[sender][destChainSelector][target];
    }

    // @inheritdoc IChainPortal
    function getPortal(uint64 chainSelector) external view returns (address portal) {
        return s_chainPortal[chainSelector];
    } 

    /**
     * @inheritdoc AutomationCompatibleInterface
     * @dev This contract integrates with Chainlink Automation implementing the AutomationCompatibleInterface.
     */
    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        return (_isActionExecutable(s_actionInfo[s_queueState.nextActionId].timestampQueued), new bytes(0));
    }
}