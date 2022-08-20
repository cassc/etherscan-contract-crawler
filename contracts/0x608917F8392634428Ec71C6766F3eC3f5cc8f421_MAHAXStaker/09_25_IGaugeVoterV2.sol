// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IRegistry} from "./IRegistry.sol";

interface IGaugeVoterV2 {
    function attachStakerToGauge(address account) external;

    function detachStakerFromGauge(address account) external;

    function distribute(address _gauge) external;

    function reset() external;

    function resetFor(address _who) external;

    function registry() external view returns (IRegistry);

    function notifyRewardAmount(uint256 amount) external;

    function attachments(address who) external view returns (uint256);

    event GaugeCreated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );
    event GaugeUpdated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );
    event Voted(address indexed voter, address tokenId, int256 weight);
    event Abstained(address tokenId, int256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint256 amount);
    event Withdraw(address indexed lp, address indexed gauge, uint256 amount);
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint256 amount
    );
    event Attach(address indexed owner, address indexed gauge);
    event Detach(address indexed owner, address indexed gauge);
    event Whitelisted(
        address indexed whitelister,
        address indexed token,
        bool value
    );
}