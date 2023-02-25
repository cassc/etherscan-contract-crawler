// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/* --- External dependencies --- */
/* --- ENS --- */
import {
    BaseRegistrarImplementation,
    ETHRegistrarController
} from "../lib/ens-contracts/contracts/ethregistrar/ETHRegistrarController.sol";
/* --- Openzeppelin --- */
import {Multicall} from "../lib/openzeppelin/contracts/utils/Multicall.sol";
/* --- Gelato --- */
import {LibDataTypes, Ops} from "../lib/ops/contracts/Ops.sol";
import {ProxyModule} from "../lib/ops/contracts/taskModules/ProxyModule.sol";
import {IOpsProxyFactory} from "../lib/ops/contracts/interfaces/IOpsProxyFactory.sol";
/* --- Self Repaying ENS --- */
import {IAlchemistV2, ICurveCalc, ICurvePool, SelfRepayingETH} from "../lib/self-repaying-eth/src/SelfRepayingETH.sol";
/* --- Solmate --- */
import {toDaysWadUnsafe, wadDiv, wadExp} from "../lib/solmate/src/utils/SignedWadMath.sol";

/* --- Internal dependencies --- */
import {EnumerableSet} from "./libraries/EnumerableSet.sol";

/// @title SelfRepayingENS
/// @author Wary
contract SelfRepayingENS is SelfRepayingETH, Multicall {
    using EnumerableSet for EnumerableSet.StringSet;

    /// @notice The ENS name renewal duration in seconds.
    uint256 constant renewalDuration = 365 days;

    /// @notice The ENS ETHRegistrarController (i.e. .eth controller) contract.
    ETHRegistrarController immutable controller;

    /// @notice The ENS BaseRegistrarImplementation (i.e. .eth registrar) contract.
    BaseRegistrarImplementation immutable registrar;

    /// @notice The Gelato contract.
    address payable immutable gelato;

    /// @notice The Gelato Ops contract.
    Ops immutable gelatoOps;

    /// @notice The Gelato address for ETH.
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The Set of names to renew per subscriber.
    mapping(address => EnumerableSet.StringSet) internal _subscribedNames;

    /// @notice An event which is emitted when a user subscribe for an self repaying ENS name renewals.
    ///
    /// @param subscriber The address of the user subscribed to this service.
    /// @param indexedName The ENS name to renew.
    /// @param name The ENS name to renew.
    /// @dev We also expose the non indexed name for consumers (e.g. UI).
    event Subscribe(address indexed subscriber, string indexed indexedName, string name);

    /// @notice An event which is emitted when a user unsubscribe to the self repaying ENS name renewal service.
    ///
    /// @param subscriber The address of the user unsubscribed from this service.
    /// @param indexedName The ENS name to renew.
    /// @param name The ENS name to not renew anymore.
    /// @dev We also expose the non i
    /// ndexed name for consumers.
    event Unsubscribe(address indexed subscriber, string indexed indexedName, string name);

    /// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed to the function.
    error IllegalArgument();

    /// @notice An error used to indicate that a transfer failed.
    error FailedTransfer();

    /// @notice Initialize the contract.
    ///
    /// @dev We annotate it payable to make it cheaper. Do not send ETH.
    constructor(
        ETHRegistrarController _controller,
        BaseRegistrarImplementation _registrar,
        Ops _gelatoOps,
        IAlchemistV2 _alchemist,
        ICurvePool _alETHPool,
        ICurveCalc _curveCalc
    ) payable SelfRepayingETH(_alchemist, _alETHPool, _curveCalc) {
        controller = _controller;
        registrar = _registrar;
        gelatoOps = _gelatoOps;

        gelato = _gelatoOps.gelato();
    }

    /// @notice Subscribe to the self repaying ENS renewals service for `name`.
    ///
    /// @dev It creates ONCE a Gelato task to monitor `subscriber`'s subscribed names expiry. Fees are paid on task execution.
    ///
    /// @notice `name` must exist and not be in `subscriber`'s to be renewed list or this call will revert an {IllegalArgument} error.
    /// @notice Emits a {Subscribed} event.
    ///
    /// @notice **_NOTE:_** The `SelfRepayingENS` contract must have enough `AlchemistV2.mintAllowance()` to renew `name`. The can be done via the `AlchemistV2.approveMint()` method.
    /// @notice **_NOTE:_** The `msg.sender` must make sure they have enough `AlchemistV2.totalValue()` to cover `name` renewal fee.
    ///
    /// @param name The ENS name to monitor and renew.
    /// @return taskId The Gelato task id.
    /// @dev We return the generated task id ONCE to simplify the `this.getTaskId()` Solidity test.
    function subscribe(string memory name) external returns (bytes32 taskId) {
        EnumerableSet.StringSet storage subNames = _subscribedNames[msg.sender];
        // Check `name` exists and is within its grace period if expired.
        // The ENS grace period is 90 days.
        // Checks if `subscriber` already subscribed to renew `name`.
        if (
            registrar.nameExpires(uint256(keccak256(bytes(name)))) + 90 days < block.timestamp
                || subNames.contains(name)
        ) {
            revert IllegalArgument();
        }

        // Create ONCE a gelato task to monitor `subscriber`'s names expiry and renew them.
        // We choose to pay Gelato when executing the task.
        if (subNames.length() == 0) {
            taskId =
                gelatoOps.createTask(address(this), abi.encode(this.renew.selector), _getModuleData(msg.sender), ETH);
        }

        // Add `name` to `subscriber`'s names to renew.
        subNames.add(name);

        emit Subscribe(msg.sender, name, name);
    }

    /// @notice Unsubscribe to the self repaying ENS renewals service for `name`.
    ///
    /// @notice Emits a {Unsubscribed} event.
    ///
    /// @notice **_NOTE:_** The `subscriber` (i.e. caller) can only unsubscribe from one of their renewals.
    ///
    /// @param name The ENS name to not monitor anymore.
    function unsubscribe(string memory name) external {
        // Not cancelling `msg.sender`'s Gelato task make the last unsubscribe and its following subscribe cheaper.

        // Remove `name` from `subscriber`'s names to renew.
        bool removed = _subscribedNames[msg.sender].remove(name);
        // Revert if `name` was not part of `subscriber`'s names to renew.
        if (!removed) {
            revert IllegalArgument();
        }

        emit Unsubscribe(msg.sender, name, name);
    }

    /// @notice Check if some of `subscriber`'s names should be renewed.
    ///
    /// @dev This is a Gelato resolver function. It is called by their network to know when and how to execute the renew task.
    ///
    /// @param subscriber The address of the subscriber.
    ///
    /// @return canExec The bool is true when some name is expired.
    /// @dev It tells Gelato when to execute the task (i.e. when it is true).
    /// @return execPayload The abi encoded call to execute.
    /// @dev It tells Gelato how to execute the task.
    function checker(address subscriber) external view returns (bool canExec, bytes memory execPayload) {
        unchecked {
            // We loop over `subscriber`'s names to find the most expensive renewable name since it is the closest to its expiry.
            EnumerableSet.StringSet storage subNames = _subscribedNames[subscriber];
            uint256 len = subNames.length();
            uint256 highestLimit;
            string memory mostExpensiveNameToRenew;

            // ⚠️ The loop is unbounded but we access each element from storage to avoid the in memory copy of the entire array.
            for (uint256 i; i < len; i++) {
                string memory name = subNames.at(i);
                // Try to limit the renew transaction gas price which means limiting the gelato fee.
                uint256 nameGasPriceLimit = getVariableMaxGasPrice(name);
                if (tx.gasprice <= nameGasPriceLimit && nameGasPriceLimit > highestLimit) {
                    highestLimit = nameGasPriceLimit;
                    mostExpensiveNameToRenew = name;
                }
            }

            return highestLimit == 0
                // Log the reason.
                ? (false, bytes("no names to renew"))
                // Return the Gelato task payload to execute. It must call `this.renew(name, subscriber)`.
                : (true, abi.encodeCall(this.renew, (mostExpensiveNameToRenew, subscriber)));
        }
    }

    /// @notice Renew `name` by minting new debt from `subscriber`'s Alchemix account.
    ///
    /// @notice **_NOTE:_** When renewing, the `SelfRepayingENS` contract must have **mintAllowance()** to mint new alETH debt tokens on behalf of **subscriber** to cover **name** renewal and the Gelato fee costs. This can be done via the `AlchemistV2.approveMint()` method.
    ///
    /// @dev It is called by the `GelatoOps` contract.
    /// @dev We annotate it payable to make it cheaper. Do not send ETH.
    ///
    /// @param name The ENS name to renew.
    /// @param subscriber The address of the subscriber.
    function renew(string calldata name, address subscriber) external payable {
        unchecked {
            // We do not trust the Gelato Executors to execute the task with the correct payload. We check it ourselves.
            // Checks `name` is one of `subscriber`'s names to renew and `tx.gasprice` is lower or equal to `name`'s gas price limit.
            if (!_subscribedNames[subscriber].contains(name) || tx.gasprice > getVariableMaxGasPrice(name)) {
                revert IllegalArgument();
            }

            // Get `name` rent price.
            uint256 namePrice = controller.rentPrice(name, renewalDuration);
            // Get the gelato fee in ETH.
            (uint256 gelatoFee,) = gelatoOps.getFeeDetails();
            // The amount of ETH needed to pay the ENS renewal using Gelato.
            uint256 neededETH = namePrice + gelatoFee;

            // Borrow `neededETH` amount of ETH from `subscriber` Alchemix account.
            _borrowSelfRepayingETHFrom(subscriber, neededETH);

            // Renew `name` for its expiry data + `renewalDuration` first.
            controller.renew{value: namePrice}(name, renewalDuration);

            // Pay the Gelato executor with all the ETH left. No ETH will be stuck in this contract.
            // Do not pay Gelato if `renew()` was called by someone else.
            if (msg.sender != address(gelatoOps)) return;
            (bool success,) = gelato.call{value: address(this).balance}("");
            if (!success) revert FailedTransfer();
        }
    }

    /// @notice Get the Set of names to renew for a subscriber.
    ///
    /// @param subscriber The address of the subscriber.
    /// @return names The Set of names to renew for `subscriber`.
    function subscribedNames(address subscriber) external view returns (string[] memory names) {
        return _subscribedNames[subscriber].values();
    }

    /// @notice Get the Self Repaying ENS task id created by `subscriber`.
    ///
    /// @dev This is a helper function to get a Gelato task id.
    ///
    /// @notice **_NOTE:_** This function returns a "random" value if the task does not exists. Make sure you call it with a subscribed `subscriber`.
    ///
    /// @param subscriber The address of the subscriber.
    /// @return taskId The Gelato task id.
    function getTaskId(address subscriber) public view returns (bytes32 taskId) {
        LibDataTypes.ModuleData memory moduleData = _getModuleData(subscriber);
        return gelatoOps.getTaskId(address(this), address(this), this.renew.selector, moduleData, ETH);
    }

    /// @dev Helper function to get the Gelato module data.
    function _getModuleData(address subscriber) internal view returns (LibDataTypes.ModuleData memory moduleData) {
        moduleData = LibDataTypes.ModuleData({modules: new LibDataTypes.Module[](1), args: new bytes[](1)});

        moduleData.modules[0] = LibDataTypes.Module.RESOLVER;

        moduleData.args[0] = abi.encode(address(this), abi.encodeCall(this.checker, (subscriber)));
    }

    /// @dev Get the variable maximum gas price for this name.
    ///
    /// @notice **_NOTE:_** Returns type(uint256).max when called with a name that doesn't exist or that is expired.
    ///
    /// @param name The ENS name to renew.
    /// @return The maximum gas price in wei allowed to renew `name`.
    function getVariableMaxGasPrice(string memory name) public view returns (uint256) {
        unchecked {
            uint256 expiryDate = registrar.nameExpires(uint256(keccak256(bytes(name))));
            return _getVariableMaxGasPrice(int256(block.timestamp) - int256(expiryDate));
        }
    }

    /// @dev Get the variable maximum gas price allowed to renew a name depending on its expiry time.
    ///
    /// @dev The formula is: y = x + e^(x / 2.62 - 30); where y is the gas price limit in gwei and x is the number of days before (expiry time - 90 days).
    ///
    /// @param expiredDuration The expired time in seconds of an ENS name.
    /// @dev expiredDuration can be negative since we want to try to renew BEFORE the ENS name is expired.
    /// @return The maximum gas price allowed in wei.
    function _getVariableMaxGasPrice(int256 expiredDuration) internal pure returns (uint256) {
        unchecked {
            if (expiredDuration < -90 days) {
                // We don't want to try to renew before.
                return 0;
            } else if (expiredDuration > 0) {
                // Remove the gas price limit after expiry.
                return type(uint256).max;
            }
            // Between 90 and 0 days before expiry.
            // x = (expiredDuration + 90 days) / 1 days; in wad.
            uint256 x = uint256(toDaysWadUnsafe(uint256(expiredDuration + int256(90 days)))); // Safe here.
            // exp = x / 2.62 - 30; can be negative, in wad.
            int256 exponant = wadDiv(int256(x), 2.62e18) - 30e18;
            // a = e^exp; in wad.
            uint256 a = uint256(wadExp(exponant));
            // y = x + a; in wad.
            uint256 maxGasPriceWad = x + a;
            // In gwei;
            return maxGasPriceWad / 1e9;
        }
    }

    /// @notice To receive ETH payments.
    /// @dev See {SelfRepayingETH.receive}.
    receive() external payable override {}
}