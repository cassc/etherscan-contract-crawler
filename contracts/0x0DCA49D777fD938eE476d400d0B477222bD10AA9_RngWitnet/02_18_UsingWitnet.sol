// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "WitnetRequestBoard.sol";

/// @title The UsingWitnet contract
/// @dev Witnet-aware contracts can inherit from this contract in order to interact with Witnet.
/// @author The Witnet Foundation.
abstract contract UsingWitnet {

    WitnetRequestBoard public immutable witnet;

    /// Include an address to specify the WitnetRequestBoard entry point address.
    /// @param _wrb The WitnetRequestBoard entry point address.
    constructor(WitnetRequestBoard _wrb)
    {
        require(address(_wrb) != address(0), "UsingWitnet: zero address");
        witnet = _wrb;
    }

    /// Provides a convenient way for client contracts extending this to block the execution of the main logic of the
    /// contract until a particular request has been successfully solved and reported by Witnet.
    modifier witnetRequestSolved(uint256 _id) {
        require(
                _witnetCheckResultAvailability(_id),
                "UsingWitnet: request not solved"
            );
        _;
    }

    /// Check if a data request has been solved and reported by Witnet.
    /// @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
    /// parties) before this method returns `true`.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return A boolean telling if the request has been already resolved or not. Returns `false` also, if the result was deleted.
    function _witnetCheckResultAvailability(uint256 _id)
        internal view
        virtual
        returns (bool)
    {
        return witnet.getQueryStatus(_id) == Witnet.QueryStatus.Reported;
    }

    /// Estimate the reward amount.
    /// @param _gasPrice The gas price for which we want to retrieve the estimation.
    /// @return The reward to be included when either posting a new request, or upgrading the reward of a previously posted one.
    function _witnetEstimateReward(uint256 _gasPrice)
        internal view
        virtual
        returns (uint256)
    {
        return witnet.estimateReward(_gasPrice);
    }

    /// Estimates the reward amount, considering current transaction gas price.
    /// @return The reward to be included when either posting a new request, or upgrading the reward of a previously posted one.
    function _witnetEstimateReward()
        internal view
        virtual
        returns (uint256)
    {
        return witnet.estimateReward(tx.gasprice);
    }

    /// Send a new request to the Witnet network with transaction value as a reward.
    /// @param _request An instance of `IWitnetRequest` contract.
    /// @return _id Sequential identifier for the request included in the WitnetRequestBoard.
    /// @return _reward Current reward amount escrowed by the WRB until a result gets reported.
    function _witnetPostRequest(IWitnetRequest _request)
        internal
        virtual
        returns (uint256 _id, uint256 _reward)
    {
        _reward = _witnetEstimateReward();
        require(
            _reward <= msg.value,
            "UsingWitnet: reward too low"
        );
        _id = witnet.postRequest{value: _reward}(_request);
    }

    /// Upgrade the reward for a previously posted request.
    /// @dev Call to `upgradeReward` function in the WitnetRequestBoard contract.
    /// @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
    /// @return Amount in which the reward has been increased.
    function _witnetUpgradeReward(uint256 _id)
        internal
        virtual
        returns (uint256)
    {
        uint256 _currentReward = witnet.readRequestReward(_id);        
        uint256 _newReward = _witnetEstimateReward();
        uint256 _fundsToAdd = 0;
        if (_newReward > _currentReward) {
            _fundsToAdd = (_newReward - _currentReward);
        }
        witnet.upgradeReward{value: _fundsToAdd}(_id); // Let Request.gasPrice be updated
        return _fundsToAdd;
    }

    /// Read the Witnet-provided result to a previously posted request.
    /// @param _id The unique identifier of a request that was posted to Witnet.
    /// @return The result of the request as an instance of `Witnet.Result`.
    function _witnetReadResult(uint256 _id)
        internal view
        virtual
        returns (Witnet.Result memory)
    {
        return witnet.readResponseResult(_id);
    }

    /// Retrieves copy of all response data related to a previously posted request, removing the whole query from storage.
    /// @param _id The unique identifier of a previously posted request.
    /// @return The Witnet-provided result to the request.
    function _witnetDeleteQuery(uint256 _id)
        internal
        virtual
        returns (Witnet.Response memory)
    {
        return witnet.deleteQuery(_id);
    }

}