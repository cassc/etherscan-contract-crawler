// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

/// @title Witnet Requestor Interface
/// @notice It defines how to interact with the Witnet Request Board in order to:
///   - request the execution of Witnet Radon scripts (data request);
///   - upgrade the resolution reward of any previously posted request, in case gas price raises in mainnet;
///   - read the result of any previously posted request, eventually reported by the Witnet DON.
///   - remove from storage all data related to past and solved data requests, and results.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardRequestor {
    /// Retrieves a copy of all Witnet-provided data related to a previously posted request, removing the whole query from the WRB storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId) external returns (Witnet.Response memory);

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided script is zero address.
    /// @dev - provided script bytecode is empty.
    /// @param _addr The address of the IWitnetRequest contract that can provide the actual Data Request bytecode.
    /// @return _queryId An unique query identifier.
    function postRequest(IWitnetRequest _addr) external payable returns (uint256 _queryId);

    /// Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId) external payable;
}