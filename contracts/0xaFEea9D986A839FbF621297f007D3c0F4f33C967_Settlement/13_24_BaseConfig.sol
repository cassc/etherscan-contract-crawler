//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Types.sol";
import "./libs/LibStorage.sol";
import "./libs/LibConfig.sol";
import "./BaseAccess.sol";

abstract contract BaseConfig is BaseAccess {
    using LibConfig for Types.Config;
   
    /**
     * Initialize config settings. This is called at initialization time when contracts 
     * are first deployed.
     */
    function initConfig(Types.Config memory config) internal {
        LibStorage.getConfigStorage().store(config);
        BaseAccess.initAccess();
    }

    /**
     * Get the current configuration struct
     */
    function getConfig() external view returns (Types.Config memory) {
        return LibStorage.getConfigStorage().copy();
    }

    
    
    //============== VIEWS ================/
    /**
     * Get the dev team wallet/multi-sig address
     */
    function getDevTeam() external view returns (address) {
        return LibStorage.getConfigStorage().devTeam;
    }

    /**
     * Get the number of blocks to wait before trader can withdraw gas tank funds 
     * marked for withdraw.
     */
    function getLockoutBlocks() external view returns (uint8) {
        return LibStorage.getConfigStorage().lockoutBlocks;
    }

    /**
     * Get the minimum fee required for all orders
     */
    function getMinFee() external view returns (uint128) {
        return LibStorage.getConfigStorage().minFee;
    }

    /**
     * Get the penalty fee to asses when trader removes tokens or funds after
     * Dexible submits orders on-chain.
     */
    function getPenaltyFee() external view returns (uint128) {
        return LibStorage.getConfigStorage().penaltyFee;
    }

    //=============== MUTATIONS ============/

    /**
     * Set the current configuration as a bulk setting
     */
    function setConfig(Types.Config memory config) public onlyAdmin {
        LibStorage.getConfigStorage().store(config);
    }

    /**
     * Set the dev team wallet/multi-sig address
     */
    function setDevTeam( address team) external onlyAdmin {
        LibStorage.getConfigStorage().devTeam = team;
    }

    /**
     * Set the number of blocks to wait before thawed withdraws are allowed
     */
    function setLockoutBlocks(uint8 blocks) external onlyAdmin {
        LibStorage.getConfigStorage().lockoutBlocks = blocks;
    }

    /**
     * Set the minimum fee for an order execution
     */
    function setMinFee(uint128 fee) external onlyAdmin {
        LibStorage.getConfigStorage().minFee = fee;
    }

    /**
     * Set the penalty assessed when a user removes tokens or gas tank funds
     */
    function setPenaltyFee(uint128 fee) external onlyAdmin {
        LibStorage.getConfigStorage().penaltyFee = fee;
    }
}