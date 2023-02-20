//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LimeRank} from "./lib/LimeRank.sol";
import {Staking} from "./Staking.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
    @title StakingFactory
    @author iMe Lab

    @notice Factory for iMe Staking v2 programmes
 */
contract StakingFactory is AccessControl {
    /**
        @notice Event, typically fired when a new staking is created
     */
    event StakingCreated(address at);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
        @notice Role, typically assigned to accounts who actually
        create staking programmes
    */
    bytes32 public constant FACTORY_WORKER_ROLE =
        keccak256("FACTORY_WORKER_ROLE");

    /**
        @notice Create a new staking programme

        @dev Should fire StakingCreated event

        @param blueprint Blueprint to compose staking programme from
        @param manager Address to assign MANAGER_ROLE. Shouldn't be empty.
        @param partner Address to assign PARTNER_TOLE. Shouldn't be empty.
        @param arbiter Address to assign ARBITER_ROLE. Can be empty.
        This option is useful in cases when staking doesn't require LIME rank.
     */
    function create(
        Staking.StakingInfo calldata blueprint,
        address manager,
        address partner,
        address arbiter
    ) external onlyRole(FACTORY_WORKER_ROLE) {
        require(manager != address(0));
        require(partner != address(0));
        Staking staking = new Staking(blueprint);
        staking.grantRole(staking.MANAGER_ROLE(), manager);
        staking.grantRole(staking.PARTNER_ROLE(), partner);
        if (arbiter != address(0))
            staking.grantRole(staking.ARBITER_ROLE(), arbiter);
        staking.renounceRole(staking.MANAGER_ROLE(), address(this));
        staking.renounceRole(staking.PARTNER_ROLE(), address(this));
        emit StakingCreated(address(staking));
    }

    receive() external payable {
        revert();
    }
}