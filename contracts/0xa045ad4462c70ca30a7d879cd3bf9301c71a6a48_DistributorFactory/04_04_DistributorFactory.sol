pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {Clones} from "Clones.sol";
import {ITrueDistributor} from "ITrueDistributor.sol";

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract DistributorFactory {
    event DistributorCreated(ITrueDistributor distributor);

    address public implementation;
    address public multifarm;
    ITrueDistributor[] public distributors;

    constructor(address _implementation, address _multifarm) {
        implementation = _implementation;
        multifarm = _multifarm;
    }

    function create(
        uint256 _distributionStart,
        uint256 _duration,
        uint256 _amount,
        IERC20 _rewardToken
    ) external {
        ITrueDistributor deployed = ITrueDistributor(Clones.clone(implementation));
        deployed.initialize(_distributionStart, _duration, _amount, _rewardToken);
        deployed.setFarm(multifarm);
        IOwnable(address(deployed)).transferOwnership(msg.sender);
        distributors.push(deployed);

        emit DistributorCreated(deployed);
    }
}