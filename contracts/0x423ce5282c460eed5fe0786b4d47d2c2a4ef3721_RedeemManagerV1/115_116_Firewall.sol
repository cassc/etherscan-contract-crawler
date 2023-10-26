//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IFirewall.sol";

import "./Administrable.sol";

/// @title Firewall
/// @author Figment
/// @notice This contract accepts calls to admin-level functions of an underlying contract, and
///         ensures the caller holds an appropriate role for calling that function. There are two roles:
///          - An Admin can call anything
///          - An Executor can call specific functions. The list of function is customisable.
///         Random callers cannot call anything through this contract, even if the underlying function
///         is unpermissioned in the underlying contract.
///         Calls to non-admin functions should be called at the underlying contract directly.
contract Firewall is IFirewall, Administrable {
    /// @inheritdoc IFirewall
    address public executor;

    /// @inheritdoc IFirewall
    address public destination;

    /// @inheritdoc IFirewall
    mapping(bytes4 => bool) public executorCanCall;

    /// @param _admin Address of the administrator, that is able to perform all calls via the Firewall
    /// @param _executor Address of the executor, that is able to perform only a subset of calls via the Firewall
    /// @param _executorCallableSelectors Initial list of allowed selectors for the executor
    constructor(address _admin, address _executor, address _destination, bytes4[] memory _executorCallableSelectors) {
        LibSanitize._notZeroAddress(_executor);
        LibSanitize._notZeroAddress(_destination);
        _setAdmin(_admin);
        executor = _executor;
        destination = _destination;

        emit SetExecutor(_executor);
        emit SetDestination(_destination);

        for (uint256 i; i < _executorCallableSelectors.length;) {
            executorCanCall[_executorCallableSelectors[i]] = true;
            emit SetExecutorPermissions(_executorCallableSelectors[i], true);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Prevents unauthorized calls
    modifier onlyAdminOrExecutor() {
        if (_getAdmin() != msg.sender && msg.sender != executor) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IFirewall
    function setExecutor(address _newExecutor) external onlyAdminOrExecutor {
        LibSanitize._notZeroAddress(_newExecutor);
        executor = _newExecutor;
        emit SetExecutor(_newExecutor);
    }

    /// @inheritdoc IFirewall
    function allowExecutor(bytes4 _functionSelector, bool _executorCanCall) external onlyAdmin {
        executorCanCall[_functionSelector] = _executorCanCall;
        emit SetExecutorPermissions(_functionSelector, _executorCanCall);
    }

    /// @inheritdoc IFirewall
    fallback() external payable virtual {
        _fallback();
    }

    /// @inheritdoc IFirewall
    receive() external payable virtual {
        _fallback();
    }

    /// @notice Performs call checks to verify that the caller is able to perform the call
    function _checkCallerRole() internal view {
        if (msg.sender == _getAdmin() || (executorCanCall[msg.sig] && msg.sender == executor)) {
            return;
        }
        revert LibErrors.Unauthorized(msg.sender);
    }

    /// @notice Forwards the current call parameters to the destination address
    /// @param _destination Address on which the forwarded call is performed
    /// @param _value Message value to attach to the call
    function _forward(address _destination, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the destination.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), _destination, _value, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Internal utility to perform authorization checks and forward a call
    function _fallback() internal virtual {
        _checkCallerRole();
        _forward(destination, msg.value);
    }
}