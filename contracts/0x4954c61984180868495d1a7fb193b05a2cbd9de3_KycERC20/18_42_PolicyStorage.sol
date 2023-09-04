// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./AddressSet.sol";
import "../interfaces/IRuleRegistry.sol";
import "../interfaces/IIdentityTree.sol";
import "../interfaces/IDegradable.sol";
import "../interfaces/IKeyringCredentials.sol";

/**
 @notice PolicyStorage attends to state management concerns for the PolicyManager. It establishes the
 storage layout and is responsible for internal state integrity and managing state transitions. The 
 PolicyManager is responsible for orchestration of the functions implemented here as well as access
 control. 
 */

library PolicyStorage {

    using AddressSet for AddressSet.Set;
    using Bytes32Set for Bytes32Set.Set;

    uint32 private constant MAX_POLICIES = 2 ** 20;
    uint32 private constant MAX_TTL = 2 * 365 days;
    uint256 public constant MAX_DISABLEMENT_PERIOD = 120 days;
    uint256 private constant MAX_BACKDOORS = 1;
    uint256 private constant UNIVERSAL_RULE = 0;
    address private constant NULL_ADDRESS = address(0);

    error Unacceptable(string reason);

    /// @dev The App struct contains the essential PolicyManager state including an array of Policies. 

    struct App {
        uint256 minimumPolicyDisablementPeriod;
        Policy[] policies;
        AddressSet.Set globalWalletCheckSet;
        AddressSet.Set globalAttestorSet;        
        mapping(address => string) attestorUris;
        Bytes32Set.Set backdoorSet;
        mapping(bytes32 => uint256[2]) backdoorPubKey;
    }

    /// @dev PolicyScalar contains the non-indexed values in a policy configuration.

    struct PolicyScalar {
        bytes32 ruleId;
        string descriptionUtf8;
        uint32 ttl;
        uint32 gracePeriod;
        bool allowApprovedCounterparties;
        uint256 disablementPeriod;
        bool locked;
    }

    /// @dev PolicyAttestors contains the active policy attestors as well as scheduled changes. 

    struct PolicyAttestors {
        AddressSet.Set activeSet;
        AddressSet.Set pendingAdditionSet;
        AddressSet.Set pendingRemovalSet;
    }

    /// @dev PolicyWalletChecks contains the active policy wallet checks as well as scheduled changes.

    struct PolicyWalletChecks {
        AddressSet.Set activeSet;
        AddressSet.Set pendingAdditionSet;
        AddressSet.Set pendingRemovalSet;
    }

    /// @dev PolicyBackdoors contain and active policy backdoors (identifiers) as well as scheduled changes. 

    struct PolicyBackdoors {
        Bytes32Set.Set activeSet;
        Bytes32Set.Set pendingAdditionSet;
        Bytes32Set.Set pendingRemovalSet;
    }

    /// @dev Policy contains the active and scheduled changes and the deadline when the changes will
    /// take effect.
    
    struct Policy {
        bool disabled;
        uint256 deadline;
        PolicyScalar scalarActive;
        PolicyScalar scalarPending;
        PolicyAttestors attestors;
        PolicyWalletChecks walletChecks;
        PolicyBackdoors backdoors;
    }

    /** 
     * @notice A policy can be disabled if the policy is deemed failed. 
     * @param policyObj The policy to disable.
     */
    function disablePolicy(
        Policy storage policyObj
    ) public 
    {
        if (!policyHasFailed(policyObj))
            revert Unacceptable({
                reason: "only failed policies can be disabled"
            });
        policyObj.disabled = true;
        policyObj.deadline = ~uint(0);
    }

    /**
     * @notice A policy is deemed failed if all attestors or any wallet check is inactive
     * over the policyDisablement period. 
     * @param policyObj The policy to inspect.
     * @return hasIndeed True if all attestors have failed or any wallet check has failed, 
     where "failure" is no updates over the policyDisablement period. 
     */
    function policyHasFailed(
        Policy storage policyObj
    ) public view returns (bool hasIndeed) 
    {
        if (policyObj.disabled == true) 
            revert Unacceptable({
                reason: "policy is already disabled"
            });
        
        uint256 i;
        uint256 disablementPeriod = policyObj.scalarActive.disablementPeriod;

        // If all attestors have failed
        bool allAttestorsHaveFailed = true;
        uint256 policyAttestorsCount = policyObj.attestors.activeSet.count();
        for (i=0; i<policyAttestorsCount; i++) {
            uint256 lastUpdate = IDegradable(policyObj.attestors.activeSet.keyAtIndex(i)).lastUpdate();
            // We ignore unitialized services to prevent interference with new policies.
            if (lastUpdate > 0) {
               if(block.timestamp < lastUpdate + disablementPeriod) {
                    allAttestorsHaveFailed = false;
               }
            } else {
                // No evidence of interrupted activity yet
                allAttestorsHaveFailed = false;
            }
        }

        if(!allAttestorsHaveFailed) {
            // If any wallet check has failed
            uint256 policyWalletChecksCount = policyObj.walletChecks.activeSet.count();
            for (i=0; i<policyWalletChecksCount; i++) {
                uint256 lastUpdate = IDegradable(policyObj.walletChecks.activeSet.keyAtIndex(i)).lastUpdate();
                if (lastUpdate > 0) {
                    if(block.timestamp > lastUpdate + disablementPeriod) return true;
                }
            }
        }
        hasIndeed = allAttestorsHaveFailed;
    }

    /**
     * @notice Updates the minimumPolicyDisablementPeriod property of the Policy struct.
     * @param self A storage reference to the App storage
     * @param minimumDisablementPeriod The new value for the minimumPolicyDisablementPeriod property.
     */
    function updateMinimumPolicyDisablementPeriod(
        App storage self, 
        uint256 minimumDisablementPeriod 
    ) public 
    {
        if (minimumDisablementPeriod >= MAX_DISABLEMENT_PERIOD) 
            revert Unacceptable({
                reason: "minimum disablement period is too long"
            });
        self.minimumPolicyDisablementPeriod = minimumDisablementPeriod;
    }

    /**
     * @notice The attestor admin can admit attestors into the global attestor whitelist. 
     * @param self PolicyManager App state.
     * @param attestor Address of the attestor's identity tree contract.
     * @param uri The URI refers to detailed information about the attestor.
     */
    function insertGlobalAttestor(
        App storage self,
        address attestor,
        string memory uri
    ) public
    {
        if (attestor == NULL_ADDRESS)
            revert Unacceptable({
                reason: "attestor cannot be empty"
            });
        if (bytes(uri).length == 0) 
            revert Unacceptable({
                reason: "uri cannot be empty"
            });        
        self.globalAttestorSet.insert(attestor, "PolicyStorage:insertGlobalAttestor");
        self.attestorUris[attestor] = uri;
    }

    /**
     * @notice The attestor admin can update the informational URIs for attestors on the whitelist.
     * @dev No onchain logic relies on the URI.
     * @param self PolicyManager App state.
     * @param attestor Address of an attestor's identity tree contract on the whitelist. 
     * @param uri The URI refers to detailed information about the attestor.
     */
    function updateGlobalAttestorUri(
        App storage self, 
        address attestor,
        string memory uri
    ) public
    {
        if (!self.globalAttestorSet.exists(attestor))
            revert Unacceptable({
                reason: "attestor not found"
            });
        if (bytes(uri).length == 0) 
            revert Unacceptable({
                reason: "uri cannot be empty"
            });  
        self.attestorUris[attestor] = uri;
    }

    /**
     * @notice The attestor admin can remove attestors from the whitelist.
     * @dev Does not remove attestors from policies that recognise the attestor to remove. 
     * @param self PolicyManager App state.
     * @param attestor Address of an attestor identity tree to remove from the whitelist. 
     */
    function removeGlobalAttestor(
        App storage self,
        address attestor
    ) public
    {
        self.globalAttestorSet.remove(attestor, "PolicyStorage:removeGlobalAttestor");
    }

    /**
     * @notice The wallet check admin can admit wallet check contracts into the system.
     * @dev Wallet checks implement the IWalletCheck interface.
     * @param self PolicyManager App state.
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function insertGlobalWalletCheck(
        App storage self,
        address walletCheck
    ) public
    {
        if (walletCheck == NULL_ADDRESS)
            revert Unacceptable({
                reason: "walletCheck cannot be empty"
            });
        self.globalWalletCheckSet.insert(walletCheck, "PolicyStorage:insertGlobalWalletCheck");
    }

    /**
     * @notice The wallet check admin can remove a wallet check from the system.
     * @dev Does not affect policies that utilize the wallet check. 
     * @param self PolicyManager App state.
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function removeGlobalWalletCheck(
        App storage self,
        address walletCheck
    ) public
    {
        self.globalWalletCheckSet.remove(walletCheck, "PolicyStorage:removeGlobalWalletCheck");
    }

    /**
     * @notice The backdoor admin can add a backdoor.
     * @dev pubKey must be unique.
     * @param self PolicyManager App state.
     * @param pubKey The public key for backdoor encryption. 
     */
    function insertGlobalBackdoor(
        App storage self, 
        uint256[2] calldata pubKey
    ) public returns (bytes32 id)
    {
        id = keccak256(abi.encodePacked(pubKey));
        self.backdoorPubKey[id] = pubKey;
        self.backdoorSet.insert(
                id,
                "PolicyStorage:insertGlobalBackdoor"
        );
    }

    /**
     * @notice Creates a new policy that is owned by the creator.
     * @dev Maximum unique policies is 2 ^ 20. Must be at least 1 attestor.
     * @param self PolicyManager App state.
     * @param policyScalar The new policy's non-indexed values. 
     * @param attestors A list of attestor identity tree contracts.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     * @param ruleRegistry The address of the deployed RuleRegistry contract.
     * @return policyId A PolicyStorage struct.Id The unique identifier of a Policy.
     */
    function newPolicy(
        App storage self,
        PolicyScalar calldata policyScalar,
        address[] memory attestors,
        address[] memory walletChecks,
        address ruleRegistry
    ) public returns (uint32 policyId) 
    {
        (bytes32 universeRule, bytes32 emptyRule) = IRuleRegistry(ruleRegistry).genesis();
        
        // Check that there is at least one attestor for the policy
        if (
            attestors.length < 1 && 
            policyScalar.ruleId != universeRule &&
            policyScalar.ruleId != emptyRule) 
        {
            revert Unacceptable({
                reason: "every policy needs at least one attestor"
            });
        }
        
        uint256 i;
        self.policies.push();
        policyId = uint32(self.policies.length - 1);
        if (policyId >= MAX_POLICIES)
            revert Unacceptable({
                reason: "max policies exceeded"
            });
        Policy storage policyObj = policyRawData(self, policyId);
        uint256 deadline = block.timestamp;

        writePolicyScalar(
            self,
            policyId,
            policyScalar,
            ruleRegistry,
            deadline
        );

        processStaged(policyObj);

        for (i=0; i<attestors.length; i++) {
            address attestor = attestors[i];
            if (!self.globalAttestorSet.exists(attestor))
                revert Unacceptable({
                    reason: "attestor not found"
                });
            policyObj.attestors.activeSet.insert(attestor, "PolicyStorage:newPolicy");
        }

        for (i=0; i<walletChecks.length; i++) {
            address walletCheck = walletChecks[i];
            if (!self.globalWalletCheckSet.exists(walletCheck))
                revert Unacceptable({
                    reason: "walletCheck not found"
                });
            policyObj.walletChecks.activeSet.insert(walletCheck, "PolicyStorage:newPolicy");
        }
    }

    /**
     * @notice Returns the internal policy state without processing staged changes. 
     * @dev Staged changes with deadlines in the past are presented as pending. 
     * @param self PolicyManager App state.
     * @param policyId A PolicyStorage struct.Id The unique identifier of a Policy.
     * @return policyInfo Policy info in the internal storage format without processing.
     */
    function policyRawData(
        App storage self, 
        uint32 policyId
    ) public view returns (Policy storage policyInfo) 
    {
        policyInfo = self.policies[policyId];
    }

    /**
     * @param activeSet The active set of addresses.
     * @param additionSet The set of pending addresses to add to the active set.
     */
    function _processAdditions(
    AddressSet.Set storage activeSet, 
    AddressSet.Set storage additionSet
    ) private {
        uint256 count = additionSet.count();
        while (count > 0) {
            address entity = additionSet.keyAtIndex(additionSet.count() - 1);
            activeSet.insert(entity, "policyStorage:_processAdditions");
            additionSet.remove(entity, "policyStorage:_processAdditions");
            count--;
        }
    }

    /**
     * @param activeSet The active set of bytes32.
     * @param additionSet The set of pending bytes32 to add to the active set.
     */
    function _processAdditions(
    Bytes32Set.Set storage activeSet, 
    Bytes32Set.Set storage additionSet
    ) private {
        uint256 count = additionSet.count();
        while (count > 0) {
            bytes32 entity = additionSet.keyAtIndex(additionSet.count() - 1);
            activeSet.insert(entity, "policyStorage:_processAdditions");
            additionSet.remove(entity, "policyStorage:_processAdditions");
            count--;
        }
    }

    /**
     * @param activeSet The active set of addresses.
     * @param removalSet The set of pending addresses to remove from the active set.
     */
    function _processRemovals(
        AddressSet.Set storage activeSet, 
        AddressSet.Set storage removalSet
    ) private {
        uint256 count = removalSet.count();
        while (count > 0) {
            address entity = removalSet.keyAtIndex(removalSet.count() - 1);
            activeSet.remove(entity, "policyStorage:_processRemovals");
            removalSet.remove(entity, "policyStorage:_processRemovals");
            count--;
        }
    }

    /**
     * @param activeSet The active set of bytes32.
     * @param removalSet The set of pending bytes32 to remove from the active set.
     */
    function _processRemovals(
        Bytes32Set.Set storage activeSet, 
        Bytes32Set.Set storage removalSet
    ) private {
        uint256 count = removalSet.count();
        while (count > 0) {
            bytes32 entity = removalSet.keyAtIndex(removalSet.count() - 1);
            activeSet.remove(entity, "policyStorage:_processRemovals");
            removalSet.remove(entity, "policyStorage:_processRemovals");
            count--;
        }
    }

    /**
     * @notice Processes staged changes to the policy state if the deadline is in the past.
     * @dev Always call this before inspecting the the active policy state. .
     * @param policyObj A Policy object.
     */
    function processStaged(Policy storage policyObj) public {
        uint256 deadline = policyObj.deadline;
        if (deadline > 0 && deadline <= block.timestamp) {
            policyObj.scalarActive = policyObj.scalarPending;

            _processAdditions(policyObj.attestors.activeSet, policyObj.attestors.pendingAdditionSet);
            _processRemovals(policyObj.attestors.activeSet, policyObj.attestors.pendingRemovalSet);

            _processAdditions(policyObj.walletChecks.activeSet, policyObj.walletChecks.pendingAdditionSet);
            _processRemovals(policyObj.walletChecks.activeSet, policyObj.walletChecks.pendingRemovalSet);

            _processAdditions(policyObj.backdoors.activeSet, policyObj.backdoors.pendingAdditionSet);
            _processRemovals(policyObj.backdoors.activeSet, policyObj.backdoors.pendingRemovalSet);

            policyObj.deadline = 0;
        }
    }


    /**
     * @notice Prevents changes to locked and disabled Policies.
     * @dev Reverts if the active policy lock is set to true or the Policy is disabled.
     * @param policyObj A Policy object.
     */
    function checkLock(
        Policy storage policyObj
    ) public view 
    {
        if (isLocked(policyObj) || policyObj.disabled)
            revert Unacceptable({
                reason: "policy is locked"
            });
    }

    /**
     * @notice Inspect the active policy lock.
     * @param policyObj A Policy object.
     * @return isIndeed True if the active policy locked parameter is set to true. True value if PolicyStorage
     is locked, otherwise False.
     */
    function isLocked(Policy storage policyObj) public view returns(bool isIndeed) {
        isIndeed = policyObj.scalarActive.locked;
    }

    /**
     * @notice Processes staged changes if the current deadline has passed and updates the deadline. 
     * @dev The deadline must be at least as far in the future as the active policy gracePeriod. 
     * @param policyObj A Policy object.
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function setDeadline(
        Policy storage policyObj, 
        uint256 deadline
    ) public
    {
        checkLock(policyObj);

        // Deadline of 0 allows staging of changes with no implementation schedule.
        // Positive deadlines must be at least graceTime seconds in the future.
     
        if (deadline != 0 && 
            (deadline < block.timestamp + policyObj.scalarActive.gracePeriod)
        )
            revert Unacceptable({
                reason: "deadline in the past or too soon"
        });
        policyObj.deadline = deadline;
    }

    /**
     * @notice Non-indexed Policy values can be updated in one step. 
     * @param self PolicyManager App state.
     * @param policyId A PolicyStorage struct.Id The unique identifier of a Policy.
     * @param policyScalar The new non-indexed properties. 
     * @param ruleRegistry The address of the deployed RuleRegistry contract. 
     * @param deadline The timestamp when the staged changes will take effect. Overrides previous deadline.
     */
    function writePolicyScalar(
        App storage self,
        uint32 policyId,
        PolicyStorage.PolicyScalar calldata policyScalar,
        address ruleRegistry,
        uint256 deadline
    ) public {
        PolicyStorage.Policy storage policyObj = policyRawData(self, policyId);
        processStaged(policyObj);
        writeRuleId(policyObj, policyScalar.ruleId, ruleRegistry);
        writeDescription(policyObj, policyScalar.descriptionUtf8);
        writeTtl(policyObj, policyScalar.ttl);
        writeGracePeriod(policyObj, policyScalar.gracePeriod);
        writeAllowApprovedCounterparties(policyObj, policyScalar.allowApprovedCounterparties);
        writePolicyLock(policyObj, policyScalar.locked);
        writeDisablementPeriod(self, policyId, policyScalar.disablementPeriod);
        setDeadline(policyObj, deadline);
    }

    /**
     * @notice Writes a new RuleId to the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param ruleId The unique identifier of a Rule.
     * @param ruleRegistry The address of the deployed RuleRegistry contract. 
     */
    function writeRuleId(
        Policy storage self, 
        bytes32 ruleId, 
        address ruleRegistry
    ) public
    {
        if (!IRuleRegistry(ruleRegistry).isRule(ruleId))
            revert Unacceptable({
                reason: "rule not found"
            });
        self.scalarPending.ruleId = ruleId;
    }

    /**
     * @notice Writes a new descriptionUtf8 to the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param descriptionUtf8 Policy description in UTF-8 format. 
     */
    function writeDescription(
        Policy storage self, 
        string memory descriptionUtf8
    ) public
    {
        if (bytes(descriptionUtf8).length == 0) 
            revert Unacceptable({
                reason: "descriptionUtf8 cannot be empty"
            });
        self.scalarPending.descriptionUtf8 = descriptionUtf8;
    }

    /**
     * @notice Writes a new ttl to the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param ttl The maximum acceptable credential age in seconds.
     */
    function writeTtl(
        Policy storage self,
        uint32 ttl
    ) public
    {
        if (ttl > MAX_TTL) 
            revert Unacceptable({ reason: "ttl exceeds maximum duration" });
        self.scalarPending.ttl = ttl;
    }

    /**
     * @notice Writes a new gracePeriod to the pending Policy changes in a Policy. 
     * @dev Deadlines must always be >= the active policy grace period. 
     * @param self A Policy object.
     * @param gracePeriod The minimum acceptable deadline.
     */
    function writeGracePeriod(
        Policy storage self,
        uint32 gracePeriod
    ) public
    {
        // 0 is acceptable
        self.scalarPending.gracePeriod = gracePeriod;
    }

    /**
     * @notice Writes a new allowApprovedCounterparties state in the pending Policy changes in a Policy. 
     * @param self A Policy object.
     * @param allowApprovedCounterparties True if whitelists are allowed, otherwise false.
     */
    function writeAllowApprovedCounterparties(
        Policy storage self,
        bool allowApprovedCounterparties
    ) public
    {
        self.scalarPending.allowApprovedCounterparties = allowApprovedCounterparties;
    }

    /**
     * @notice Writes a new locked state in the pending Policy changes in a Policy.
     * @param self A Policy object.
     * @param setPolicyLocked True if the policy is to be locked, otherwise false.
     */
    function writePolicyLock(
        Policy storage self,
        bool setPolicyLocked
    ) public
    {
        self.scalarPending.locked = setPolicyLocked;
    }

    /**
     * @notice Writes a new disablement deadline to the pending Policy changes of a Policy.
     * @dev If the provided disablement deadline is in the past, this function will revert. 
     * @param self A PolicyStorage object.
     * @param disablementPeriod The new disablement deadline to set, in seconds since the Unix epoch.
     *   If set to 0, the policy can be disabled at any time.
     *   If set to a non-zero value, the policy can only be disabled after that time.
     */

    function writeDisablementPeriod(
        App storage self,
        uint32 policyId,
        uint256 disablementPeriod
    ) public {
        // Check that the new disablement period is greater than or equal to the minimum
        if (disablementPeriod < self.minimumPolicyDisablementPeriod) {
            revert Unacceptable({
                reason: "disablement period is too short"
            });
        }
        if (disablementPeriod >= MAX_DISABLEMENT_PERIOD) {
            revert Unacceptable({
                reason: "disablement period is too long"
            });
        }
        Policy storage policyObj = self.policies[policyId];
        policyObj.scalarPending.disablementPeriod = disablementPeriod;
    }

    /**
     * @notice Writes attestors to pending Policy attestor additions. 
     * @param self PolicyManager App state.
     * @param policyObj A Policy object.
     * @param attestors The address of one or more Attestors to add to the Policy.
     */
    function writeAttestorAdditions(
        App storage self,
        Policy storage policyObj,
        address[] calldata attestors
    ) public
    {
        for (uint i = 0; i < attestors.length; i++) {
            _writeAttestorAddition(self, policyObj, attestors[i]);
        }        
    }

    /**
     * @notice Writes an attestor to pending Policy attestor additions. 
     * @dev If the attestor is scheduled to be remove, unschedules the removal. 
     * @param self PolicyManager App state.
     * @param policyObj A Policy object. 
     * @param attestor The address of an Attestor to add to the Policy.
     */
    function _writeAttestorAddition(
        App storage self,
        Policy storage policyObj,
        address attestor
    ) private
    {
        if (!self.globalAttestorSet.exists(attestor))
            revert Unacceptable({
                reason: "attestor not found"
            });
        if (policyObj.attestors.pendingRemovalSet.exists(attestor)) {
            policyObj.attestors.pendingRemovalSet.remove(attestor, "PolicyStorage:_writeAttestorAddition");
        } else {
            if (policyObj.attestors.activeSet.exists(attestor)) {
                revert Unacceptable({
                    reason: "attestor already in policy"
                });
            }
            policyObj.attestors.pendingAdditionSet.insert(attestor, "PolicyStorage:_writeAttestorAddition");
        }
    }

    /**
     * @notice Writes attestors to pending Policy attestor removals. 
     * @param self A Policy object.
     * @param attestors The address of one or more Attestors to remove from the Policy.
     */
    function writeAttestorRemovals(
        Policy storage self,
        address[] calldata attestors
    ) public
    {
        for (uint i = 0; i < attestors.length; i++) {
            _writeAttestorRemoval(self, attestors[i]);
        }
    }

    /**
     * @notice Writes an attestor to a Policy's pending attestor removals. 
     * @dev Cancels the addition if the attestor is scheduled to be added. 
     * @param self PolicyManager App state.
     * @param attestor The address of a Attestor to remove from the Policy.
     */
    function _writeAttestorRemoval(
        Policy storage self,
        address attestor
    ) private
    {
        
        uint currentAttestorCount = self.attestors.activeSet.count();
        uint pendingAdditionsCount = self.attestors.pendingAdditionSet.count();
        uint pendingRemovalsCount = self.attestors.pendingRemovalSet.count();

        if (currentAttestorCount + pendingAdditionsCount - pendingRemovalsCount < 2) {
            revert Unacceptable({
                reason: "Cannot remove the last attestor. Add a replacement first"
            });
        }
        
        if (self.attestors.pendingAdditionSet.exists(attestor)) {
            self.attestors.pendingAdditionSet.remove(attestor, "PolicyStorage:_writeAttestorRemoval");
        } else {
            if (!self.attestors.activeSet.exists(attestor)) {
                revert Unacceptable({
                    reason: "attestor not found"
                });
            }
            self.attestors.pendingRemovalSet.insert(attestor, "PolicyStorage:_writeAttestorRemoval");
        }
    }

    /**
     * @notice Writes wallet checks to a Policy's pending wallet check additions.
     * @param self PolicyManager App state.
     * @param policyObj A PolicyStorage object.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     */
    function writeWalletCheckAdditions(
        App storage self,
        Policy storage policyObj,
        address[] memory walletChecks
    ) public
    {
        for (uint i = 0; i < walletChecks.length; i++) {
            _writeWalletCheckAddition(self, policyObj, walletChecks[i]);
        }
    }

    /**
     * @notice Writes a wallet check to a Policy's pending wallet check additions. 
     * @dev Cancels removal if the wallet check is scheduled for removal. 
     * @param self PolicyManager App state.
     * @param policyObj A Policy object. 
     * @param walletCheck The address of a Wallet Check to admit into the global whitelist.
     */
    function _writeWalletCheckAddition(
        App storage self,
        Policy storage policyObj,
        address walletCheck
    ) private
    {
        if (!self.globalWalletCheckSet.exists(walletCheck))
            revert Unacceptable({
                reason: "walletCheck not found"
            });
        if (policyObj.walletChecks.pendingRemovalSet.exists(walletCheck)) {
            policyObj.walletChecks.pendingRemovalSet.remove(walletCheck, "PolicyStorage:_writeWalletCheckAddition");
        } else {
            if (policyObj.walletChecks.activeSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck already in policy"
                });
            }
            if (policyObj.walletChecks.pendingAdditionSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck addition already scheduled"
                });
            }
            policyObj.walletChecks.pendingAdditionSet.insert(walletCheck, "PolicyStorage:_writeWalletCheckAddition");
        }
    }

    /**
     * @notice Writes wallet checks to a Policy's pending wallet check removals. 
     * @param self A Policy object.
     * @param walletChecks The address of one or more Wallet Checks to add to the Policy.
     */
    function writeWalletCheckRemovals(
        Policy storage self,
        address[] memory walletChecks
    ) public
    {
        for (uint i = 0; i < walletChecks.length; i++) {
            _writeWalletCheckRemoval(self, walletChecks[i]);
        }
    }

    /**
     * @notice Writes a wallet check to a Policy's pending wallet check removals. 
     * @dev Unschedules addition if the wallet check is present in the Policy's pending wallet check additions. 
     * @param self A Policy object.
     * @param walletCheck The address of a Wallet Check to remove from the Policy. 
     */
    function _writeWalletCheckRemoval(
        Policy storage self,
        address walletCheck
    ) private
    {
        if (self.walletChecks.pendingAdditionSet.exists(walletCheck)) {
            self.walletChecks.pendingAdditionSet.remove(walletCheck, "PolicyStorage:_writeWalletCheckRemoval");
        } else {
            if (!self.walletChecks.activeSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck is not in policy"
                });
            }
            if (self.walletChecks.pendingRemovalSet.exists(walletCheck)) {
                revert Unacceptable({
                    reason: "walletCheck removal already scheduled"
                });
            }
            self.walletChecks.pendingRemovalSet.insert(walletCheck, "PolicyStorage:_writeWalletCheckRemoval");
        }
    }

    /**
     * @notice Add a backdoor to a policy.
     * @param self The application state. 
     * @param policyObj A Policy object.
     * @param backdoorId The ID of a backdoor. 
     */
    function writeBackdoorAddition(
        App storage self,
        Policy storage policyObj,
        bytes32 backdoorId
    ) public {
        if (!self.backdoorSet.exists(backdoorId)) {
            revert Unacceptable({
                reason: "unknown backdoor"
            });
        }
        if (policyObj.backdoors.pendingRemovalSet.exists(backdoorId)) {
            policyObj.backdoors.pendingRemovalSet.remove(backdoorId, 
            "PolicyStorage:writeBackdoorAddition");
        } else {
            if (policyObj.backdoors.activeSet.exists(backdoorId)) {
                revert Unacceptable({
                    reason: "backdoor exists in policy"
                });
            }
            if (policyObj.backdoors.pendingAdditionSet.exists(backdoorId)) {
                revert Unacceptable({
                    reason: "backdoor addition already scheduled"
                });
            }
            policyObj.backdoors.pendingAdditionSet.insert(backdoorId, 
            "PolicyStorage:_writeWalletCheckAddition");
            _checkBackdoorConfiguration(policyObj);
        }
    }

    /**
     * @notice Writes a wallet check to a Policy's pending wallet check removals. 
     * @dev Unschedules addition if the wallet check is present in the Policy's pending wallet check additions. 
     * @param self A Policy object.
     * @param backdoorId The address of a Wallet Check to remove from the Policy. 
     */
    function writeBackdoorRemoval(
        Policy storage self,
        bytes32 backdoorId
    ) public
    {
        if (self.backdoors.pendingAdditionSet.exists(backdoorId)) {
            self.backdoors.pendingAdditionSet.remove(backdoorId, 
            "PolicyStorage:writeBackdoorRemoval");
        } else {
            if (!self.backdoors.activeSet.exists(backdoorId)) {
                revert Unacceptable({
                    reason: "backdoor is not in policy"
                });
            }
            if (self.backdoors.pendingRemovalSet.exists(backdoorId)) {
                revert Unacceptable({
                    reason: "backdoor removal already scheduled"
                });
            }
            self.backdoors.pendingRemovalSet.insert(backdoorId, 
            "PolicyStorage:writeBackdoorRemoval");
        }
    }

    /**
     * @notice Checks the net count of backdoors.
     * @dev Current zkVerifier supports only one backdoor per policy.
     * @param self A policy object.
     */
    function _checkBackdoorConfiguration(
        Policy storage self
    ) internal view {
        uint256 activeCount = self.backdoors.activeSet.count();
        uint256 pendingAdditionsCount = self.backdoors.pendingAdditionSet.count();
        uint256 pendingRemovalsCount = self.backdoors.pendingRemovalSet.count();
        if(activeCount + pendingAdditionsCount - pendingRemovalsCount > MAX_BACKDOORS) {
            revert Unacceptable({ reason: "too many backdoors requested" });
        }
    }

    /**********************************************************
     Inspection
     **********************************************************/

    /**
     * @param self Application state.
     * @param policyId The unique identifier of a Policy.
     * @return policyObj Policy object with staged updates processed.
     */
    function policy(App storage self, uint32 policyId)
        public
        returns (Policy storage policyObj)
    {
        policyObj = self.policies[policyId];
        processStaged(policyObj);
    }

}