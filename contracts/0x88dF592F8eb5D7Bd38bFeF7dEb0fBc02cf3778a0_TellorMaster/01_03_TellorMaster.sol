// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./TellorStorage.sol";
import "./TellorVariables.sol";

/**
 * @title Tellor Master
 * @dev This is the Master contract with all tellor getter functions and delegate call to Tellor.
 * The logic for the functions on this contract is saved on the TellorGettersLibrary, TellorTransfer,
 * TellorGettersLibrary, and TellorStake
 */
contract TellorMaster is TellorStorage, TellorVariables {
    event NewTellorAddress(address _newTellor);

    constructor(address _tContract, address _oTellor) {
        addresses[_OWNER] = msg.sender;
        addresses[_DEITY] = msg.sender;
        addresses[_TELLOR_CONTRACT] = _tContract;
        addresses[_OLD_TELLOR] = _oTellor;
        bytesVars[_CURRENT_CHALLENGE] = bytes32("1");
        uints[_DIFFICULTY] = 100;
        uints[_TIME_TARGET] = 240;
        uints[_TARGET_MINERS] = 200;
        uints[_CURRENT_REWARD] = 1e18;
        uints[_DISPUTE_FEE] = 500e18;
        uints[_STAKE_AMOUNT] = 500e18;
        uints[_TIME_OF_LAST_NEW_VALUE] = block.timestamp - 240;

        currentMiners[0].value = 1;
        currentMiners[1].value = 2;
        currentMiners[2].value = 3;
        currentMiners[3].value = 4;
        currentMiners[4].value = 5;

        // Bootstraping Request Queue
        for (uint256 index = 1; index < 51; index++) {
            Request storage req = requestDetails[index];
            req.apiUintVars[_REQUEST_Q_POSITION] = index;
            requestIdByRequestQIndex[index] = index;
        }

        assembly {
            sstore(_EIP_SLOT, _tContract)
        }

        emit NewTellorAddress(_tContract);
    }

    /**
     * @dev This function allows the Deity to set a new deity
     * @param _newDeity the new Deity in the contract
     */
    function changeDeity(address _newDeity) external {
        require(msg.sender == addresses[_DEITY]);
        addresses[_DEITY] = _newDeity;
    }

    /**
     * @dev This function allows the owner to set a new _owner
     * @param _newOwner the new Owner in the contract
     */
    function changeOwner(address _newOwner) external {
        require(msg.sender == addresses[_OWNER]);
        addresses[_OWNER] = _newOwner;
    }

    /**
     * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
     * @param _tContract the address of the new Tellor Contract
     */
    function changeTellorContract(address _tContract) external {
        require(msg.sender == addresses[_DEITY]);
        addresses[_TELLOR_CONTRACT] = _tContract;

        assembly {
            sstore(_EIP_SLOT, _tContract)
        }
    }

    /**
     * @dev This is the internal function that allows for delegate calls to the Tellor logic
     * contract address
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @dev This is the fallback function that allows contracts to call the tellor
     * contract at the address stored
     */
    fallback() external payable {
        address addr = addresses[_TELLOR_CONTRACT];
        _delegate(addr);
    }
}