// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './Constants.sol' as Constants;
import './DataStructures.sol' as DataStructures;

/**
 * @title CallerGuard
 * @notice Base contract to control access from other contracts
 */
abstract contract CallerGuard is ManagerRole {
    /**
     * @dev Caller guard mode enumeration
     */
    enum CallerGuardMode {
        ContractForbidden,
        ContractList,
        ContractAllowed
    }

    /**
     * @dev Caller guard mode value
     */
    CallerGuardMode public callerGuardMode = CallerGuardMode.ContractForbidden;

    /**
     * @dev Registered contract list for "ContractList" mode
     */
    address[] public listedCallerGuardContractList;

    /**
     * @dev Registered contract list indices for "ContractList" mode
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*index*/)
        public listedCallerGuardContractIndexMap;

    /**
     * @notice Emitted when the caller guard mode is set
     * @param callerGuardMode The caller guard mode
     */
    event SetCallerGuardMode(CallerGuardMode indexed callerGuardMode);

    /**
     * @notice Emitted when a registered contract for "ContractList" mode is added or removed
     * @param contractAddress The contract address
     * @param isListed The registered contract list inclusion flag
     */
    event SetListedCallerGuardContract(address indexed contractAddress, bool indexed isListed);

    /**
     * @notice Emitted when the caller is not allowed to perform the intended action
     */
    error CallerGuardError(address caller);

    /**
     * @dev Modifier to check if the caller is allowed to perform the intended action
     */
    modifier checkCaller() {
        if (msg.sender != tx.origin) {
            bool condition = (callerGuardMode == CallerGuardMode.ContractAllowed ||
                (callerGuardMode == CallerGuardMode.ContractList &&
                    isListedCallerGuardContract(msg.sender)));

            if (!condition) {
                revert CallerGuardError(msg.sender);
            }
        }

        _;
    }

    /**
     * @notice Sets the caller guard mode
     * @param _callerGuardMode The caller guard mode
     */
    function setCallerGuardMode(CallerGuardMode _callerGuardMode) external onlyManager {
        callerGuardMode = _callerGuardMode;

        emit SetCallerGuardMode(_callerGuardMode);
    }

    /**
     * @notice Updates the list of registered contracts for the "ContractList" mode
     * @param _items The addresses and flags for the contracts
     */
    function setListedCallerGuardContracts(
        DataStructures.AccountToFlag[] calldata _items
    ) external onlyManager {
        for (uint256 index; index < _items.length; index++) {
            DataStructures.AccountToFlag calldata item = _items[index];

            if (item.flag) {
                AddressHelper.requireContract(item.account);
            }

            DataStructures.uniqueAddressListUpdate(
                listedCallerGuardContractList,
                listedCallerGuardContractIndexMap,
                item.account,
                item.flag,
                Constants.LIST_SIZE_LIMIT_DEFAULT
            );

            emit SetListedCallerGuardContract(item.account, item.flag);
        }
    }

    /**
     * @notice Getter of the registered contract count
     * @return The registered contract count
     */
    function listedCallerGuardContractCount() external view returns (uint256) {
        return listedCallerGuardContractList.length;
    }

    /**
     * @notice Getter of the complete list of registered contracts
     * @return The complete list of registered contracts
     */
    function fullListedCallerGuardContractList() external view returns (address[] memory) {
        return listedCallerGuardContractList;
    }

    /**
     * @notice Getter of a listed contract flag
     * @param _account The contract address
     * @return The listed contract flag
     */
    function isListedCallerGuardContract(address _account) public view returns (bool) {
        return listedCallerGuardContractIndexMap[_account].isSet;
    }
}