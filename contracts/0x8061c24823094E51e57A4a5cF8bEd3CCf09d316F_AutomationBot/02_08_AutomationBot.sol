// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBot.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "./interfaces/ICommand.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/BotLike.sol";
import "./AutomationBotStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AutomationBot is BotLike, ReentrancyGuard {
    struct TriggerRecord {
        bytes32 triggerHash;
        address commandAddress;
        bool continuous;
    }

    uint16 private constant SINGLE_TRIGGER_GROUP_TYPE = 2 ** 16 - 1;
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";
    string private constant AUTOMATION_EXECUTOR_KEY = "AUTOMATION_EXECUTOR_V2";

    ServiceRegistry public immutable serviceRegistry;
    AutomationBotStorage public immutable automationBotStorage;
    address public immutable self;
    uint256 private lockCount;

    constructor(ServiceRegistry _serviceRegistry, AutomationBotStorage _automationBotStorage) {
        serviceRegistry = _serviceRegistry;
        automationBotStorage = _automationBotStorage;
        self = address(this);
        lockCount = 0;
    }

    modifier auth(address caller) {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_EXECUTOR_KEY) == caller,
            "bot/not-executor"
        );
        _;
    }

    modifier onlyDelegate() {
        require(address(this) != self, "bot/only-delegate");
        _;
    }

    // works correctly in any context
    function getCommandAddress(uint256 triggerType) public view returns (address) {
        bytes32 commandHash = keccak256(abi.encode("Command", triggerType));

        address commandAddress = serviceRegistry.getServiceAddress(commandHash);

        return commandAddress;
    }

    function getAdapterAddress(
        address commandAddress,
        bool isExecute
    ) public view returns (address) {
        require(commandAddress != address(0), "bot/unknown-trigger-type");
        bytes32 adapterHash = isExecute
            ? keccak256(abi.encode("AdapterExecute", commandAddress))
            : keccak256(abi.encode("Adapter", commandAddress));
        address service = serviceRegistry.getServiceAddress(adapterHash);
        return service;
    }

    function clearLock() external {
        lockCount = 0;
    }

    // works correctly in any context
    function getTriggersHash(
        bytes memory triggerData,
        address commandAddress
    ) private view returns (bytes32) {
        bytes32 triggersHash = keccak256(
            abi.encodePacked(triggerData, serviceRegistry, commandAddress)
        );

        return triggersHash;
    }

    // works correctly in context of Automation Bot
    function checkTriggersExistenceAndCorrectness(
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) private view {
        (bytes32 triggersHash, , ) = automationBotStorage.activeTriggers(triggerId);
        require(
            triggersHash != bytes32(0) &&
                triggersHash == getTriggersHash(triggerData, commandAddress),
            "bot/invalid-trigger"
        );
    }

    // works correctly in context of automationBot
    function addRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 triggerType,
        bool continuous,
        uint256 replacedTriggerId,
        bytes memory triggerData,
        bytes memory replacedTriggerData
    ) external {
        lock();

        address commandAddress = getCommandAddress(triggerType);
        if (replacedTriggerId != 0) {
            (bytes32 replacedTriggersHash, address originalCommandAddress, ) = automationBotStorage
                .activeTriggers(replacedTriggerId);
            ISecurityAdapter originalAdapter = ISecurityAdapter(
                getAdapterAddress(originalCommandAddress, false)
            );
            require(
                originalAdapter.canCall(replacedTriggerData, msg.sender),
                "bot/no-permissions-replace"
            );
            require(
                replacedTriggersHash ==
                    getTriggersHash(replacedTriggerData, originalCommandAddress),
                "bot/invalid-trigger"
            );
        }

        require(
            ICommand(commandAddress).isTriggerDataValid(continuous, triggerData),
            "bot/invalid-trigger-data"
        );

        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        require(adapter.canCall(triggerData, msg.sender), "bot/no-permissions");

        automationBotStorage.appendTriggerRecord(
            AutomationBotStorage.TriggerRecord(
                getTriggersHash(triggerData, commandAddress),
                commandAddress,
                continuous
            )
        );

        if (replacedTriggerId != 0) {
            clearTrigger(replacedTriggerId);
            emit TriggerRemoved(replacedTriggerId);
        }

        emit TriggerAdded(
            automationBotStorage.triggersCounter(),
            commandAddress,
            continuous,
            triggerType,
            triggerData
        );
    }

    // works correctly in context of automationBot
    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        bytes memory triggerData,
        uint256 triggerId
    ) external {
        (, address commandAddress, ) = automationBotStorage.activeTriggers(triggerId);
        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        require(adapter.canCall(triggerData, msg.sender), "no-permit");
        checkTriggersExistenceAndCorrectness(triggerId, commandAddress, triggerData);

        clearTrigger(triggerId);
        emit TriggerRemoved(triggerId);
    }

    function clearTrigger(uint256 triggerId) private {
        automationBotStorage.updateTriggerRecord(
            triggerId,
            AutomationBotStorage.TriggerRecord(0, 0x0000000000000000000000000000000000000000, false)
        );
    }

    // works correctly in context of dsProxy
    function addTriggers(
        uint16 groupType,
        bool[] memory continuous,
        uint256[] memory replacedTriggerId,
        bytes[] memory triggerData,
        bytes[] memory replacedTriggerData,
        uint256[] memory triggerTypes
    ) external onlyDelegate {
        require(
            replacedTriggerId.length == replacedTriggerData.length &&
                triggerData.length == triggerTypes.length &&
                triggerTypes.length == continuous.length &&
                continuous.length == triggerData.length,
            "bot/invalid-input-length"
        );

        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        AutomationBot(automationBot).clearLock();

        if (groupType != SINGLE_TRIGGER_GROUP_TYPE) {
            IValidator validator = getValidatorAddress(groupType);
            require(
                validator.validate(continuous, replacedTriggerId, triggerData),
                "aggregator/validation-error"
            );
        }

        uint256 firstTriggerId = automationBotStorage.triggersCounter() + 1;
        uint256[] memory triggerIds = new uint256[](triggerData.length);

        for (uint256 i = 0; i < triggerData.length; i++) {
            ISecurityAdapter adapter = ISecurityAdapter(
                getAdapterAddress(getCommandAddress(triggerTypes[i]), false)
            );

            if (i == 0) {
                (bool status, ) = address(adapter).delegatecall(
                    abi.encodeWithSelector(
                        adapter.permit.selector,
                        triggerData[i],
                        address(automationBotStorage),
                        true
                    )
                );
                require(status, "bot/permit-failed-add");
                emit ApprovalGranted(triggerData[i], address(automationBotStorage));
            }

            AutomationBot(automationBot).addRecord(
                triggerTypes[i],
                continuous[i],
                replacedTriggerId[i],
                triggerData[i],
                replacedTriggerData[i]
            );

            triggerIds[i] = firstTriggerId + i;
        }

        AutomationBot(automationBot).emitGroupDetails(groupType, triggerIds);
    }

    function unlock() private {
        //To keep addRecord && emitGroupDetails atomic
        require(lockCount > 0, "bot/not-locked");
        lockCount = 0;
    }

    function lock() private {
        //To keep addRecord && emitGroupDetails atomic
        lockCount++;
    }

    function emitGroupDetails(uint16 triggerGroupType, uint256[] memory triggerIds) external {
        require(lockCount == triggerIds.length, "bot/group-inconsistent");
        unlock();

        emit TriggerGroupAdded(
            automationBotStorage.triggersGroupCounter(),
            triggerGroupType,
            triggerIds
        );
        automationBotStorage.increaseGroupCounter();
    }

    function getValidatorAddress(uint16 groupType) public view returns (IValidator) {
        bytes32 validatorHash = keccak256(abi.encode("Validator", groupType));
        return IValidator(serviceRegistry.getServiceAddress(validatorHash));
    }

    //works correctly in context of dsProxy
    function removeTriggers(
        uint256[] memory triggerIds,
        bytes[] memory triggerData,
        bool removeAllowance
    ) external onlyDelegate {
        require(triggerData.length > 0, "bot/remove-at-least-one");
        require(triggerData.length == triggerIds.length, "bot/invalid-input-length");

        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        AutomationBot(automationBot).clearLock();
        (, address commandAddress, ) = automationBotStorage.activeTriggers(triggerIds[0]);

        for (uint256 i = 0; i < triggerIds.length; i++) {
            removeTrigger(triggerIds[i], triggerData[i]);
        }

        if (removeAllowance) {
            ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
            (bool status, ) = address(adapter).delegatecall(
                abi.encodeWithSelector(
                    adapter.permit.selector,
                    triggerData[0],
                    address(automationBotStorage),
                    false
                )
            );

            require(status, "bot/permit-removal-failed");
            emit ApprovalRemoved(triggerData[0], address(automationBotStorage));
        }
    }

    function removeTrigger(uint256 triggerId, bytes memory triggerData) private {
        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        BotLike(automationBot).removeRecord(triggerData, triggerId);
    }

    //works correctly in context of automationBot
    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 coverageAmount,
        address coverageToken
    ) external auth(msg.sender) nonReentrant {
        checkTriggersExistenceAndCorrectness(triggerId, commandAddress, triggerData);
        ICommand command = ICommand(commandAddress);

        require(command.isExecutionLegal(triggerData), "bot/trigger-execution-illegal");
        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        IExecutableAdapter executableAdapter = IExecutableAdapter(
            getAdapterAddress(commandAddress, true)
        );

        automationBotStorage.executeCoverage(
            triggerData,
            msg.sender,
            address(executableAdapter),
            coverageToken,
            coverageAmount
        );
        {
            automationBotStorage.executePermit(triggerData, commandAddress, address(adapter), true);
        }
        {
            command.execute(executionData, triggerData); //command must be whitelisted
            (, , bool continuous) = automationBotStorage.activeTriggers(triggerId);
            if (!continuous) {
                clearTrigger(triggerId);
                emit TriggerRemoved(triggerId);
            }
        }
        {
            automationBotStorage.executePermit(
                triggerData,
                commandAddress,
                address(adapter),
                false
            );
            require(command.isExecutionCorrect(triggerData), "bot/trigger-execution-wrong");
        }

        emit TriggerExecuted(triggerId, executionData);
    }

    event ApprovalRemoved(bytes indexed triggerData, address approvedEntity);

    event ApprovalGranted(bytes indexed triggerData, address approvedEntity);

    event TriggerRemoved(uint256 indexed triggerId);

    event TriggerAdded(
        uint256 indexed triggerId,
        address indexed commandAddress,
        bool continuous,
        uint256 triggerType,
        bytes triggerData
    );

    event TriggerExecuted(uint256 indexed triggerId, bytes executionData);
    event TriggerGroupAdded(
        uint256 indexed groupId,
        uint16 indexed groupType,
        uint256[] triggerIds
    );
}