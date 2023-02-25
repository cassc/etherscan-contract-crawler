// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {GnosisSafe} from "safe/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "safe/proxies/GnosisSafeProxyFactory.sol";

import {ISafe} from "../bases/interfaces/ISafe.sol";
import {Roles} from "../roles/Roles.sol";
import {Budget, EncodedTimeShift} from "../budget/Budget.sol";
import {Captable, IBouncer} from "../captable/Captable.sol";
import {Voting, NO_SEMAPHORE} from "../voting/Voting.sol";
import {Semaphore, ISemaphore} from "../semaphore/Semaphore.sol";

import {FirmRelayer} from "../metatx/FirmRelayer.sol";

import {UpgradeableModuleProxyFactory, LATEST_VERSION} from "./UpgradeableModuleProxyFactory.sol";
import {AddressUint8FlagsLib} from "../bases/utils/AddressUint8FlagsLib.sol";
import {FirmAddresses, SemaphoreTargetsFlag, SEMAPHORE_TARGETS_FLAG_TYPE, exceptionTargetFlagToAddress} from "./config/SemaphoreTargets.sol";

string constant ROLES_MODULE_ID =     "org.firm.roles";
string constant BUDGET_MODULE_ID =    "org.firm.budget";
string constant CAPTABLE_MODULE_ID =  "org.firm.captable";
string constant VOTING_MODULE_ID =    "org.firm.voting";
string constant SEMAPHORE_MODULE_ID = "org.firm.semaphore";

contract FirmFactory {
    using AddressUint8FlagsLib for address;

    GnosisSafeProxyFactory public immutable safeFactory;
    address public immutable safeImpl;

    UpgradeableModuleProxyFactory public immutable moduleFactory;
    FirmRelayer public immutable relayer;

    address internal immutable cachedThis;

    error EnableModuleFailed();
    error InvalidContext();
    error InvalidConfig();

    event NewFirmCreated(address indexed creator, GnosisSafe indexed safe);

    constructor(
        GnosisSafeProxyFactory _safeFactory,
        UpgradeableModuleProxyFactory _moduleFactory,
        FirmRelayer _relayer,
        address _safeImpl
    ) {
        safeFactory = _safeFactory;
        moduleFactory = _moduleFactory;
        relayer = _relayer;
        safeImpl = _safeImpl;

        cachedThis = address(this);
    }

    struct SafeConfig {
        address[] owners;
        uint256 requiredSignatures;
    }

    struct FirmConfig {
        // if false, only roles and budget are created
        bool withCaptableAndVoting;
        bool withSemaphore;
        // budget and roles are always created
        BudgetConfig budgetConfig;
        RolesConfig rolesConfig;
        // optional depending on 'withCaptableAndVoting'
        CaptableConfig captableConfig;
        VotingConfig votingConfig;
        // optional depending on 'withSemaphore'
        SemaphoreConfig semaphoreConfig;
    }

    struct BudgetConfig {
        AllowanceCreationInput[] allowances;
    }

    struct AllowanceCreationInput {
        uint256 parentAllowanceId;
        address spender;
        address token;
        uint256 amount;
        EncodedTimeShift recurrency;
        string name;
    }

    struct RolesConfig {
        RoleCreationInput[] roles;
    }

    struct RoleCreationInput {
        bytes32 roleAdmins;
        string name;
        address[] grantees;
    }

    struct CaptableConfig {
        string name;
        ClassCreationInput[] classes;
        ShareIssuanceInput[] issuances;
    }

    struct ClassCreationInput {
        string className;
        string ticker;
        uint128 authorized;
        uint32 convertsToClassId;
        uint16 votingWeight;
        IBouncer bouncer;
    }

    struct ShareIssuanceInput {
        uint256 classId;
        address account;
        uint256 amount;
    }

    struct VotingConfig {
        uint256 quorumNumerator;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThreshold;
    }

    struct SemaphoreConfig {
        bool safeDefaultAllowAll; // if true, Safe will allow all calls by default (if false, it will be Voting the default)
        bool safeAllowDelegateCalls;
        bool votingAllowValueCalls;
        SemaphoreException[] semaphoreExceptions; // exceptions for which calls are only allowed in the non-default executor
    }

    struct SemaphoreException {
        Semaphore.ExceptionType exceptionType;
        address target; // can use flags for target for Safe and Voting
        bytes4 sig;
    }

    function createBarebonesFirm(address owner, uint256 nonce) public returns (GnosisSafe safe) {
        return createFirm(defaultOneOwnerSafeConfig(owner), defaultBarebonesFirmConfig(), nonce);
    }

    function createFirm(SafeConfig memory safeConfig, FirmConfig memory firmConfig, uint256 nonce)
        public
        returns (GnosisSafe safe)
    {
        bytes memory setupFirmData = abi.encodeCall(this.setupFirm, (firmConfig, nonce));
        bytes memory safeInitData = abi.encodeCall(
            GnosisSafe.setup,
            (
                safeConfig.owners,
                safeConfig.requiredSignatures,
                address(this),
                setupFirmData,
                address(0),
                address(0),
                0,
                payable(0)
            )
        );

        safe = GnosisSafe(payable(safeFactory.createProxyWithNonce(safeImpl, safeInitData, nonce)));

        emit NewFirmCreated(msg.sender, safe);
    }

    // Safe will delegatecall here as part of its setup, can only run on a delegatecall
    function setupFirm(FirmConfig calldata config, uint256 nonce) external {
        // Ensure that we are running on a delegatecall and not in a direct call to this external function
        // cachedThis is set to the address of this contract in the constructor as an immutable
        GnosisSafe safe = GnosisSafe(payable(address(this)));
        if (address(safe) == cachedThis) {
            revert InvalidContext();
        }

        if (config.withSemaphore && !config.withCaptableAndVoting) {
            revert InvalidConfig();
        }

        Roles roles = setupRoles(config.rolesConfig, nonce);
        Budget budget = setupBudget(config.budgetConfig, roles, nonce);
        safe.enableModule(address(budget));

        if (!config.withCaptableAndVoting) {
            return;
        }

        ISemaphore semaphore = config.withSemaphore ? createSemaphore(config.semaphoreConfig, nonce) : NO_SEMAPHORE;

        Captable captable = setupCaptable(config.captableConfig, nonce);
        Voting voting = setupVoting(config.votingConfig, captable, semaphore, nonce);
        safe.enableModule(address(voting));

        if (semaphore == NO_SEMAPHORE) {
            return;
        }

        FirmAddresses memory firmAddresses = FirmAddresses({
            semaphore: Semaphore(address(semaphore)),
            safe: safe,
            voting: voting,
            budget: budget,
            roles: roles,
            captable: captable
        });
        configSemaphore(config.semaphoreConfig, firmAddresses);
        safe.setGuard(address(semaphore));
    }

    function setupBudget(BudgetConfig calldata config, Roles roles, uint256 nonce) internal returns (Budget budget) {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        budget = Budget(
            moduleFactory.deployUpgradeableModule(
                BUDGET_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Budget.initialize, (ISafe(payable(address(this))), roles, address(relayer))),
                nonce
            )
        );

        // As we are the safe, we can just create the top-level allowances as the safe has that power
        uint256 allowanceCount = config.allowances.length;
        for (uint256 i = 0; i < allowanceCount;) {
            AllowanceCreationInput memory allowance = config.allowances[i];

            budget.createAllowance(
                allowance.parentAllowanceId,
                allowance.spender,
                allowance.token,
                allowance.amount,
                allowance.recurrency,
                allowance.name
            );

            unchecked {
                ++i;
            }
        }
    }

    function setupRoles(RolesConfig calldata config, uint256 nonce) internal returns (Roles roles) {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        roles = Roles(
            moduleFactory.deployUpgradeableModule(
                ROLES_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Roles.initialize, (ISafe(payable(address(this))), address(relayer))),
                nonce
            )
        );

        // As we are the safe, we can just create the roles and assign them as the safe has the root role
        uint256 roleCount = config.roles.length;
        for (uint256 i = 0; i < roleCount;) {
            RoleCreationInput memory role = config.roles[i];
            uint8 roleId = roles.createRole(role.roleAdmins, role.name);

            uint256 granteeCount = role.grantees.length;
            for (uint256 j = 0; j < granteeCount;) {
                roles.setRole(role.grantees[j], roleId, true);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setupCaptable(CaptableConfig calldata config, uint256 nonce) internal returns (Captable captable) {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        captable = Captable(
            moduleFactory.deployUpgradeableModule(
                CAPTABLE_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Captable.initialize, (config.name, ISafe(payable(address(this))), address(relayer))),
                nonce
            )
        );

        // As we are the safe, we can just create the classes and issue shares
        uint256 classCount = config.classes.length;
        for (uint256 i = 0; i < classCount;) {
            ClassCreationInput memory class = config.classes[i];
            captable.createClass(
                class.className,
                class.ticker,
                class.authorized,
                class.convertsToClassId,
                class.votingWeight,
                class.bouncer
            );

            unchecked {
                ++i;
            }
        }

        uint256 issuanceCount = config.issuances.length;
        for (uint256 i = 0; i < issuanceCount;) {
            ShareIssuanceInput memory issuance = config.issuances[i];
            // it is possible that this reverts if the class does not exist or
            // the amount to be issued goes over the authorized amount
            captable.issue(issuance.account, issuance.classId, issuance.amount);

            unchecked {
                ++i;
            }
        }
    }

    function setupVoting(VotingConfig calldata config, Captable captable, ISemaphore semaphore, uint256 nonce)
        internal
        returns (Voting voting)
    {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        bytes memory votingInitData = abi.encodeCall(
            Voting.initialize,
            (
                ISafe(payable(address(this))),
                semaphore,
                captable,
                config.quorumNumerator,
                config.votingDelay,
                config.votingPeriod,
                config.proposalThreshold,
                address(relayer)
            )
        );
        voting = Voting(
            payable(moduleFactory.deployUpgradeableModule(VOTING_MODULE_ID, LATEST_VERSION, votingInitData, nonce))
        );
    }

    function defaultOneOwnerSafeConfig(address owner) public pure returns (SafeConfig memory) {
        address[] memory owners = new address[](1);
        owners[0] = owner;
        return SafeConfig({owners: owners, requiredSignatures: 1});
    }

    function defaultBarebonesFirmConfig() public pure returns (FirmConfig memory) {
        BudgetConfig memory budgetConfig = BudgetConfig({allowances: new AllowanceCreationInput[](0)});
        RolesConfig memory rolesConfig = RolesConfig({roles: new RoleCreationInput[](0)});
        CaptableConfig memory captableConfig;
        VotingConfig memory votingConfig;
        SemaphoreConfig memory semaphoreConfig;

        return FirmConfig({
            withCaptableAndVoting: false,
            withSemaphore: false,
            budgetConfig: budgetConfig,
            rolesConfig: rolesConfig,
            captableConfig: captableConfig,
            votingConfig: votingConfig,
            semaphoreConfig: semaphoreConfig
        });
    }

    function createSemaphore(SemaphoreConfig calldata config, uint256 nonce) internal returns (Semaphore semaphore) {
        semaphore = Semaphore(
            moduleFactory.deployUpgradeableModule(
                SEMAPHORE_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Semaphore.initialize, (ISafe(payable(address(this))), config.safeAllowDelegateCalls, address(relayer))),
                nonce
            )
        );
    }

    function configSemaphore(SemaphoreConfig calldata config, FirmAddresses memory firmAddresses) internal {
        Semaphore semaphore = firmAddresses.semaphore;
        Voting voting = firmAddresses.voting;

        if (!config.safeDefaultAllowAll) {
            semaphore.setSemaphoreState(address(voting), Semaphore.DefaultMode.Allow, false, config.votingAllowValueCalls);
            semaphore.setSemaphoreState(address(this), Semaphore.DefaultMode.Disallow, config.safeAllowDelegateCalls, true);
        } else {
            semaphore.setSemaphoreState(address(voting), Semaphore.DefaultMode.Disallow, false, config.votingAllowValueCalls);
            // Safe state is the same that was already set in the initializer, no need to set again
        }

        uint256 exceptionsLength = config.semaphoreExceptions.length;
        Semaphore.ExceptionInput[] memory exceptions = new Semaphore.ExceptionInput[](exceptionsLength * 2);

        for (uint256 i = 0; i < exceptionsLength;) {
            SemaphoreException memory exception = config.semaphoreExceptions[i];

            address target = exception.target;

            if (target.isFlag(SEMAPHORE_TARGETS_FLAG_TYPE)) {
                target = exceptionTargetFlagToAddress(firmAddresses, exception.target.flagValue());
            }

            exceptions[i * 2] = Semaphore.ExceptionInput(true, exception.exceptionType, address(voting), target, exception.sig);
            exceptions[i * 2 + 1] = Semaphore.ExceptionInput(true, exception.exceptionType, address(this), target, exception.sig);

            unchecked {
                i++;
            }
        }

        semaphore.addExceptions(exceptions);
    }
}