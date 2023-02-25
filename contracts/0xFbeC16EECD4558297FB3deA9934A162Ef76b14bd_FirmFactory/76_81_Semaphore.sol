// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {BaseGuard, Enum} from "safe/base/GuardManager.sol";

import {FirmBase, ISafe, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../bases/FirmBase.sol";

import {ISemaphore} from "./interfaces/ISemaphore.sol";

/**
 * @title Semaphore
 * @author Firm ([email protected])
 * @notice Simple access control system intended to balance permissions between pairs of accounts
 * Compliant with the Safe Guard interface and designed to limit power of Safe owners via multisig txs
 */
contract Semaphore is FirmBase, BaseGuard, ISemaphore {
    string public constant moduleId = "org.firm.semaphore";
    uint256 public constant moduleVersion = 1;

    enum DefaultMode {
        Disallow,
        Allow
    }

    struct SemaphoreState {
        // Configurable state
        DefaultMode defaultMode;
        bool allowDelegateCalls;
        bool allowValueCalls;
        
        // Counters
        uint64 numTotalExceptions;
        uint32 numSigExceptions;
        uint32 numTargetExceptions;
        uint32 numTargetSigExceptions;
    } // 1 slot

    enum ExceptionType {
        Sig,
        Target,
        TargetSig
    }

    struct ExceptionInput {
        bool add;
        ExceptionType exceptionType;
        address caller;
        address target;  // only used for Target and TargetSig (ignored for Sig)
        bytes4 sig;      // only used for Sig and TargetSig (ignored for Target)
    }

    // caller => state
    mapping (address => SemaphoreState) public state;
    // caller => sig => bool (whether executing functions with this sig on any target is an exception to caller's defaultMode)
    mapping (address => mapping (bytes4 => bool)) public sigExceptions;
    // caller => target => bool (whether calling this target is an exception to caller's defaultMode)
    mapping (address => mapping (address => bool)) public targetExceptions;
    // caller => target => sig => bool (whether executing functions with this sig on this target is an exception to caller's defaultMode)
    mapping (address => mapping (address => mapping (bytes4 => bool))) public targetSigExceptions;

    event SemaphoreStateSet(address indexed caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls);
    event ExceptionSet(address indexed caller, bool added, ExceptionType exceptionType, address target, bytes4 sig);

    error ExceptionAlreadySet(ExceptionInput exception);

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(IMPL_INIT_NOOP_SAFE, false, IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, bool safeAllowsDelegateCalls, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);

        // state[safe] represents the state when performing checks on the Safe multisig transactions checked via
        // Safe is marked as allowed by default (too dangerous to disallow by default or leave as an option)
        // Value calls are allowed by default for Safe
        _setSemaphoreState(address(safe_), DefaultMode.Allow, safeAllowsDelegateCalls, true);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // STATE AND EXCEPTIONS MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sets the base state for a caller
     * @dev Note: Use with extreme caution on live organizations, can lead to irreversible loss of access and funds
     * @param defaultMode Whether calls from this caller are allowed by default
     * @param allowDelegateCalls Whether this caller is allowed to perform delegatecalls
     * @param allowValueCalls Whether this caller is allowed to perform calls with non-zero value (native asset transfers)
     */
    function setSemaphoreState(address caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls) external onlySafe {
        _setSemaphoreState(caller, defaultMode, allowDelegateCalls, allowValueCalls);
    }

    function _setSemaphoreState(address caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls) internal {
        SemaphoreState storage s = state[caller];
        s.defaultMode = defaultMode;
        s.allowDelegateCalls = allowDelegateCalls;
        s.allowValueCalls = allowValueCalls;

        emit SemaphoreStateSet(caller, defaultMode, allowDelegateCalls, allowValueCalls);
    }

    /**
     * @notice Adds expections to the default mode for calls
     * @dev Note: Use with extreme caution on live organizations, can lead to irreversible loss of access and funds
     * @param exceptions Array of new exceptions to be applied
     */
    function addExceptions(ExceptionInput[] calldata exceptions) external onlySafe {
        for (uint256 i = 0; i < exceptions.length;) {
            ExceptionInput memory e = exceptions[i];
            SemaphoreState storage s = state[e.caller];

            if (e.exceptionType == ExceptionType.Sig) {
                if (e.add == sigExceptions[e.caller][e.sig]) {
                    revert ExceptionAlreadySet(e);
                }
                sigExceptions[e.caller][e.sig] = e.add;
                s.numSigExceptions = e.add ? s.numSigExceptions + 1 : s.numSigExceptions - 1;
            } else if (e.exceptionType == ExceptionType.Target) {
                if (e.add == targetExceptions[e.caller][e.target]) {
                    revert ExceptionAlreadySet(e);
                }
                targetExceptions[e.caller][e.target] = e.add;
                s.numTargetExceptions = e.add ? s.numTargetExceptions + 1 : s.numTargetExceptions - 1;
            } else if (e.exceptionType == ExceptionType.TargetSig) {
                if (e.add == targetSigExceptions[e.caller][e.target][e.sig]) {
                    revert ExceptionAlreadySet(e);
                }
                targetSigExceptions[e.caller][e.target][e.sig] = e.add;
                s.numTargetSigExceptions = e.add ? s.numTargetSigExceptions + 1 : s.numTargetSigExceptions - 1;
            }

            // A local counter for the specific exception type + the global exception type is added for the caller
            // Since per caller we need 1 slot of storage for its config, we can keep these counters within that same slot
            // As exception checking will be much more frequent and there will be many cases without exceptions,
            // it allows us to perform checks by just reading 1 slot if there are no exceptions and 2 if there's one
            // instead of always having to read 3 different slots (different mappings) for each possible exception that could be set
            s.numTotalExceptions = e.add ? s.numTotalExceptions + 1 : s.numTotalExceptions - 1;

            emit ExceptionSet(e.caller, e.add, e.exceptionType, e.target, e.sig);

            unchecked {
                i++;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // CALL CHECKS (ISEMAPHORE)
    ////////////////////////////////////////////////////////////////////////////////

    function canPerform(address caller, address target, uint256 value, bytes calldata data, bool isDelegateCall) public view returns (bool) {
        SemaphoreState memory s = state[caller];

        if ((isDelegateCall && !s.allowDelegateCalls) ||
            (value > 0 && !s.allowValueCalls)) {
            return false;
        }

        // If there's an exception for this call, we flip the default mode for the caller
        return isException(s, caller, target, data)
            ? s.defaultMode == DefaultMode.Disallow
            : s.defaultMode == DefaultMode.Allow;
    }

    function canPerformMany(address caller, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bool isDelegateCall) public view returns (bool) {
        if (targets.length != values.length || targets.length != calldatas.length) {
            return false;
        }
        
        SemaphoreState memory s = state[caller];

        if (isDelegateCall && !s.allowDelegateCalls) {
            return false;
        }
        
        for (uint256 i = 0; i < targets.length;) {
            if (values[i] > 0 && !s.allowValueCalls) {
                return false;
            }

            bool isAllowed = isException(s, caller, targets[i], calldatas[i])
                ? s.defaultMode == DefaultMode.Disallow
                : s.defaultMode == DefaultMode.Allow;

            if (!isAllowed) {
                return false;
            }

            unchecked {
                i++;
            }
        }

        return true;
    }

    function isException(SemaphoreState memory s, address from, address target, bytes calldata data) internal view returns (bool) {
        if (s.numTotalExceptions == 0) {
            return false;
        }

        bytes4 sig = data.length >= 4 ? bytes4(data[:4]) : bytes4(0);
        return
            (s.numSigExceptions > 0 && sigExceptions[from][sig]) ||
            (s.numTargetExceptions > 0 && targetExceptions[from][target]) ||
            (s.numTargetSigExceptions > 0 && targetSigExceptions[from][target][sig]);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // SAFE GUARD COMPLIANCE
    ////////////////////////////////////////////////////////////////////////////////

    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256, uint256, uint256, address, address payable, bytes memory, address
    ) external view {
        if (!canPerform(msg.sender, to, value, data, operation == Enum.Operation.DelegateCall)) {
            revert ISemaphore.SemaphoreDisallowed();
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {}
}