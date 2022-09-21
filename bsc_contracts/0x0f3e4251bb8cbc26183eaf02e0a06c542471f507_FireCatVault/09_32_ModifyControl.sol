// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FireCatAccessControl} from "./FireCatAccessControl.sol";


contract ModifyControl is FireCatAccessControl{
    event SetStakeOn(bool isStakeOn_);
    event SetClaimOn(bool isClaimOn_);
    
     /**
    * @dev switch on/off the stake function.
    */
    bool public isStakeOn = true;

    /**
    * @dev switch on/off the claim function.
    */
    bool public isClaimOn = true;

    modifier beforeStake() {
        require(isStakeOn, "stake is not on");
        _;
    }

    modifier beforeClaim() {
        require(isClaimOn, "claim is not on");
        _;
    }

    /**
    * @notice the stake switch, default is false
    * @param isStakeOn_ bool
    */    
    function setStakeOn(bool isStakeOn_) external onlyRole(DATA_ADMIN) {
        isStakeOn = isStakeOn_;
        emit SetStakeOn(isStakeOn_);
    }

    /**
    * @notice the claim switch, default is false
    * @param isClaimOn_ bool
    */
    function setClaimOn(bool isClaimOn_) external onlyRole(DATA_ADMIN) {
        isClaimOn = isClaimOn_;
        emit SetClaimOn(isClaimOn_);
    }
}