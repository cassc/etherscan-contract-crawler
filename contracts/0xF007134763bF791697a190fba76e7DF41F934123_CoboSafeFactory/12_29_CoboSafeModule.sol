// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "CoboSafeModuleBase.sol";
import "CoboSubSafe.sol";
import "CoboSubSafeFactory.sol";

/// @title A GnosisSafe module to extend the original CoboSafe that implements Cobo SubSafe and strategy.
///        `SubSafe` is used to separate the fund and to execute the strategy.
/// @author Cobo Safe Dev Team ([email protected])
/// @notice Use this module to access Gnosis Safe with sub-safe and strategy
/// @dev This contract implements the core data structure and its related features.
contract CoboSafeModule is CoboSafeModuleBase {
    /// @dev the subSafe factory to work with
    address public subSafeFactory;

    /// @notice Initializer function for CoboSafeModule
    /// @dev When this module is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance. The instance is
    ///      supposed to call `enableModule` on the constructed module instance
    ///      in order for it to function properly.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    /// @param _subSafeFactory the SubSafeFactory instance's address
    function initialize(address payable _safe, address _subSafeFactory) initializer public {
        require(_subSafeFactory != address(0), "invalid subSafeFactory address");
        __CoboSafeModule_init(_safe);
        subSafeFactory = _subSafeFactory;
    }

    /// @notice Batch call Gnosis Safe to execute transactions through subSafe or not
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract method `to`::`func` in target subSafe,
    ///      where `func` is the function selector contained in first 4 bytes of `data`.
    ///      The function can only be called by delegates.
    /// @param subSafeList The target subSafes to be called, address(0) for bypass subSafe
    /// @param toList The target contracts to be called by subSafe
    /// @param valueList The value data to be transferred by subSafe
    /// @param dataList The input data to be called by subSafe
    function batchExecTransactionsV2(
        address[] calldata subSafeList,
        address[] calldata toList,
        uint256[] calldata valueList,
        bytes[] calldata dataList)
        external
        onlyDelegate
    {
        require(
            subSafeList.length > 0 && subSafeList.length == toList.length && toList.length == valueList.length && toList.length == dataList.length,
            "invalid inputs"
        );

        for (uint256 i = 0; i < toList.length; i++) {
            if(subSafeList[i] != address(0)) {
                _execTransactionBySubSafe(subSafeList[i],toList[i], valueList[i], dataList[i]);
            } else {
                _execTransaction(toList[i], valueList[i], dataList[i]);
            }
        }
    }

    /// @notice Call Gnosis Safe to execute a transaction through subSafe
    /// @param subSafe The target subSafe to be called
    /// @param to The target contract to be called by Gnosis Safe
    /// @param value The value data to be transferred by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    function _execTransactionBySubSafe(address subSafe, address to, uint256 value, bytes calldata data) internal {
        require(subSafe != address(0), "invalid subSafe address");
        require(_isOwnedSubSafe(subSafe), "not owned subSafe");
        require(_hasPermission(_msgSender(), to, value, data), "permission denied");
        bytes memory data = abi.encodeWithSignature('execTransaction(address,uint256,bytes)', to, value, data);

        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        require(
            GnosisSafe(payable(owner())).execTransactionFromModule(
                subSafe,
                value,
                data,
                Enum.Operation.Call
            ),
            "failed in execution for subSafe in safe"
        );
        emit ExecTransaction(subSafe, value, Enum.Operation.Call, data, _msgSender());
    }

    /// @notice Internal function to check if the subSafe owned by the module's owner
    /// @dev Only owned subSafe can be handled by the module
    /// @param subSafe the address of subSube to be checked
    /// @return true|false
    function _isOwnedSubSafe(
        address subSafe
    )  internal view returns (bool) {
        return CoboSubSafeFactory(subSafeFactory).subSafeToSafe(subSafe) == owner();
    }

    /// @notice Return the name of module
    /// @dev reflect the new name
    /// @return name
    function NAME() public override pure returns (string memory) {
        return "Cobo Safe Module";
    }

    /// @notice Return the version of module
    /// @dev reflect the new version
    /// @return version
    function VERSION() public override pure returns (string memory){
        return "0.5.0";
    }
}