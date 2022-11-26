// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Batchable
 * @author Rafał Kalinowski <[email protected]>
 * @dev This is BoringBatchable based function with a small twist: because delgatecall passes msg.value
 *      on each call, it may introduce double spending issue. To avoid that, we handle cases when msg.value matters separately.
 *      Please note that you'll have to pass msg.value in amount field for native currency per each call
 *      Additionally, please keep in mind that currently you cannot put payable and nonpayable calls in the same batch -
 *      - nonpayable functions will revert when receiving money
 */
abstract contract Batchable {
    uint256 internal _MSG_VALUE;
    uint256 internal constant _BATCH_NOT_ENTERED = 1;
    uint256 internal constant _BATCH_ENTERED = 2;
    uint256 internal _batchStatus;

    error BatchError(bytes innerError);

    constructor() {
        _batchStatus = _BATCH_NOT_ENTERED;
    }

    /**
    * @notice This function allows batched call to self (this contract).
    * @param _calls An array of inputs for each call.
    * @dev - it sets _MSG_VALUE variable for a call, if function is payable
     *       check if the function is payable is done in your implementation of function `isMsgValueOverride()`
     *       and _MSG_VALUE is set based on your `calculateMsgValueForACall()` implementation
    */
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is used on the same contract, and there is reentrancy guard in place
    function batchCall(bytes[] calldata _calls) internal {
        // bacause we already have reentrancy guard for functions, we set second kind of reentrancy guard
        require(_batchStatus != _BATCH_ENTERED, "ReentrancyGuard: reentrant call");
        uint256 msgValueSentAcc;

        _batchStatus = _BATCH_ENTERED;

        for (uint256 i = 0; i < _calls.length; i++) {
            bool success;
            bytes memory result;
            bytes memory data = _calls[i];
            bytes4 sig;

            assembly {
                sig := mload(add(data, add(0x20, 0)))
            }

            // set proper msg.value for payable function, as delegatecall can introduce double spending
            if (isMsgValueOverride(sig)) {
                uint256 currentCallPriceAmount = calculateMsgValueForACall(sig, data);

                _MSG_VALUE = currentCallPriceAmount;
                msgValueSentAcc += currentCallPriceAmount;

                require (msgValueSentAcc <= msg.value, "Can't send more than msg.value");

                (success, result) = address(this).delegatecall(data);

                _MSG_VALUE = 0;
            } else {
                (success, result) = address(this).delegatecall(data);
            }

            if (!success) {
                _getRevertMsg(result);
            }
        }

        _batchStatus = _BATCH_NOT_ENTERED;
    }

    /**
    * @notice This is part of BoringBatchable contract
    *         https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
    * @dev Helper function to extract a useful revert message from a failed call.
    * If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    */
    function _getRevertMsg(bytes memory _returnData) internal pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /**
    * @notice Checks if a function is payable, i.e. should _MSG_VALUE be set
    * @param _selector function selector
    * @dev Write your logic checking if a function is payable, e.g. this.<function-name>.selector == _selector
    *      WARNING - if you, or someone else if able to construct the same selector for a malicious function (which is not that hard),
    *      the logic may break and the msg.value may be exploited
    */
    function isMsgValueOverride(bytes4 _selector) virtual pure internal returns (bool);

    /**
    * @notice Calculates msg.value that should be sent with a call
    * @param _selector function selector
    * @param _calldata single call encoded data
    * @dev You should probably decode function parameters and check what value should be passed
    */
    function calculateMsgValueForACall(bytes4 _selector, bytes memory _calldata) virtual view internal returns (uint256);
}