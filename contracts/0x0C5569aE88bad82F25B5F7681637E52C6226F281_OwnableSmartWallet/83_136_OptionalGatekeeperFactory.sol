// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OptionalHouseGatekeeper } from "./OptionalHouseGatekeeper.sol";

contract OptionalGatekeeperFactory {

    event NewOptionalGatekeeperDeployed(address indexed keeper, address indexed manager);

    function deploy(address _liquidStakingManager) external returns (OptionalHouseGatekeeper) {
        OptionalHouseGatekeeper newKeeper = new OptionalHouseGatekeeper(_liquidStakingManager);

        emit NewOptionalGatekeeperDeployed(address(newKeeper), _liquidStakingManager);

        return newKeeper;
    }
}