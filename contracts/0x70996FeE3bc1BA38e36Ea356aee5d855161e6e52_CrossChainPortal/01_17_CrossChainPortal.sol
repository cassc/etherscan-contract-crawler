//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CrossChainGovernable} from "./types/CrossChainGovernable.sol";
import {Guardable} from "./types/Guardable.sol";
import {ChainPortal} from "./ChainPortal.sol";

/**
 * @title CrossChainPortal
 * @author Oddcod3 (@oddcod3)
 *
 * @dev Cross-chain portals are not deployed on the same chain where the FlashLiquidity governor is deployed.
 * 
 * @notice This contract is used to communicate with other CrossChainPortals and with the BaseChainPortal.
 * @notice The FlashLiquidity governor can use the BaseChainPortal to govern this portal cross-chain.
 * @notice The FlashLiquidity governor can use the BaseChainPortal to govern cross-chain contracts indirectly with this portal (this portal must be the governor of the contracts).
 */
contract CrossChainPortal is CrossChainGovernable, Guardable, ChainPortal {

    error CrossChainPortal__NotSelfCall();
    error CrossChainPortal__NotFromBaseChainGovernor();
    error CrossChainPortal__GuardianGoneRogue();

    uint32 private s_intervalGuardianGoneRogue;

    modifier onlySelf() {
        _revertIfNotSelfCall();
        _;
    }

    event IntervalGuardianGoneRogueChanged(uint32 indexed newInterval);

    constructor(
        address governor,
        address guardian,
        address baseChainPortal,
        address ccipRouter,
        address linkToken,
        uint64 governorChainSelector,
        uint64 executionDelay,
        uint32 intervalGuardianGoneRogue,
        uint32 intervalCommunicationLost
    )
        CrossChainGovernable(governor, governorChainSelector, intervalCommunicationLost)
        Guardable(guardian)
        ChainPortal(ccipRouter, linkToken, executionDelay)
    {
        s_intervalGuardianGoneRogue = intervalGuardianGoneRogue;
        s_isGuardian[address(this)] = true;
        s_chainPortal[governorChainSelector] = baseChainPortal;
    }

    // inheritdoc ICrossChainGovernable
    function setPendingGovernor(address pendingGovernor, uint64 pendingGovernorChainSelector) external override onlySelf {
        _setPendingGovernor(pendingGovernor, pendingGovernorChainSelector);
    }

    // inheritdoc ICrossChainGovernable
    function setIntervalCommunicationLost(uint32 intervalCommunicationLost) external override onlySelf {
        _setIntervalCommunicationLost(intervalCommunicationLost);
    }

    /**
     * @param intervalGuardianGoneRogue The new interval between the last timestamp an action has been executed and the last timestamp an action has been received.
     * @notice This interval is used to determine if a guardian has gone rogue (aborting all actions received).
     */
    function setIntervalGuardianGoneRogue(uint32 intervalGuardianGoneRogue) external onlySelf {
        _setIntervalGuardianGoneRogue(intervalGuardianGoneRogue);
    }

    // inheritdoc IGuardable
    function setGuardians(address[] calldata guardians, bool[] calldata enableds) external override onlySelf {
        _setGuardians(guardians, enableds);
    }

    // @inheritdoc IChainPortal
    function abortAction(uint64 actionId) external override onlyGuardian {
        _revertIfGuardianGoneRogue();
        _abortAction(actionId);
    }

    // @inheritdoc IChainPortal
    function setExecutionDelay(uint64 executionDelay) external override onlySelf {
        _setExecutionDelay(executionDelay);
    }

    // @inheritdoc IChainPortal
    function setChainPortals(uint64[] calldata chainSelectors, address[] calldata portals) public override onlySelf {
        _setChainPortals(chainSelectors, portals);
    }

    // @inheritdoc IChainPortal
    function setLanes(
        address[] calldata senders,
        uint64[] calldata destChainSelectors,
        address[] calldata receivers,
        bool[] calldata enableds
    ) public override onlySelf {
        _setLanes(senders, destChainSelectors, receivers, enableds);
    }

    /**
     * @param message The Any2EVMMessage struct containing the emergency action.
     * @notice This function can be executed by guardians only if communication with the base portal has been lost.
     */
    function emergencyCommunicationLost(Client.Any2EVMMessage memory message) external onlyGuardian {
        if (!_isCommunicationLost()) {
            revert CrossChainGovernable__CommunicationNotLost();
        }
        _ccipReceive(message);
    }

    /**
     * @param intervalGuardianGoneRogue The new interval between the last timestamp an action has been executed and the last timestamp an action has been received.
     */
    function _setIntervalGuardianGoneRogue(uint32 intervalGuardianGoneRogue) internal {
        s_intervalGuardianGoneRogue = intervalGuardianGoneRogue;
        emit IntervalGuardianGoneRogueChanged(intervalGuardianGoneRogue);
    }

    /**
     * @notice This function is overridden to revert on self-calls if the sender of the action is not the cross-chain governor.
     */
    function _verifyActionRestrictions(
        address sender,
        address[] memory targets,
        uint64 sourceChainSelector
    ) internal view override {
        address governor = _getGovernor();
        uint64 governorChainSelector = _getGovernorChainSelector();
        for (uint256 i; i < targets.length; ) {
            if (targets[i] == address(this) && (sender != governor || sourceChainSelector != governorChainSelector)) {
                revert CrossChainPortal__NotFromBaseChainGovernor();
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function reverts if `msg.sender` is not the address of this portal.
     */
    function _revertIfNotSelfCall() internal view {
        if (msg.sender != address(this)) {
            revert CrossChainPortal__NotSelfCall();
        }
    }

    /**
     * @notice This function reverts if the portal assumes that one or more guardians have gone rogue.
     */
    function _revertIfGuardianGoneRogue() internal view {
        ActionQueueState memory queueState = _getActionQueueState();
        if (_getActionStateById(queueState.lastActionId - 1).timestampQueued - queueState.lastTimePendingActionExecuted > s_intervalGuardianGoneRogue) {
            revert CrossChainPortal__GuardianGoneRogue();
        }
    }

    /**
     * @notice This function returns true if the communication with the base portal has been lost.
     * @return True if communication with the base portal is lost; otherwise, false.
     */
    function _isCommunicationLost() internal view override returns (bool) {
        ActionQueueState memory queueState = _getActionQueueState();
        ActionInfo memory actionInfo = _getActionStateById(queueState.lastActionId - 1);
        if(queueState.lastActionId == 0 || actionInfo.timestampQueued == 0) return false;
        return
            block.timestamp - actionInfo.timestampQueued > _getIntervalCommunicationLost();
    }

    function getIntervalGuardianGoneRogue() external view returns (uint32) {
        return s_intervalGuardianGoneRogue;
    }
}