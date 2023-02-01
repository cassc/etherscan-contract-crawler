// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {CharlieHelpers} from "./CharlieHelpers.sol";

/**
 * @title Charlie
 * @dev This is a contract that serves as a call aggregator for Charlie, the governance aggregator.
 *      To do so, this contract does not implement any logic, and simply has authority checks and
 *      forwards calls to the target.
 * @notice To keep everything in one contract, available there is support for reads and writes.
 *         Because reads are free, and could be done anywhere, there is no limit on who can call
 *         a read. However, writes are limited to users that meet the authority requirements.
 */
contract Charlie is CharlieHelpers {
    /// @dev Load the backend of Charlie.
    constructor(address _authority) CharlieHelpers(_authority) {}

    /**
     * @dev Primary controller function of Charlie that allows users to bundle
     *      multiple calls into a single transaction. The caller can choose to
     *      block on a failed call, or continue on.
     * @param _calls The calls to make.
     * @param _blocking Whether or not to block on a failed call.
     * @return responses The responses from the calls.
     */
    function aggregate(
        Call[] calldata _calls,
        bool _blocking
    ) external payable requiresAuth returns (Response[] memory responses) {
        /// @dev The amount of ETH sent must be equal to the value of the calls.
        uint256 sum;
        
        /// @dev Instantiate the array used to store whether it was a success,
        ///      the block number, and the result.
        responses = new Response[](_calls.length);

        /// @dev Load the for loop counter.
        uint256 i;

        /// @dev Loop through the calls and make them.
        for (i; i < _calls.length; i++) {
            /// @dev Add the value of the call to the sum.
            sum += _calls[i].value;

            /// @dev Make the call and store the response.
            (bool success, bytes memory result) = _calls[i].target.call{
                value: _calls[i].value
            }(_calls[i].callData);

            /// @dev If the call was not successful and is blocking, revert.
            require(
                success || !_blocking,
                "Charlie: call failed"
            );

            /// @dev Store the response.
            responses[i] = Response(success, block.number, result);
        }

        /// @dev The amount of ETH sent must be equal to the value of the calls.
        require(msg.value >= sum, "Charlie: invalid ETH sent");

        /// @dev If there is ETH left over, send it back.
        if (msg.value > sum) {
            payable(msg.sender).transfer(msg.value - sum);
        }

        /// @dev Announce the use of Charlie.
        emit CharlieCalled(msg.sender, responses);
    }
}