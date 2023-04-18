// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EmergencyState
 * @dev Contract defining the emergency state.
 */
abstract contract EmergencyState is Ownable {
    /*
     * @dev Diagram of possible emergency states and transitions:
     *
     *            +-------------------+
     *            |       NORMAL      |
     *            +-------------------+
     *               |             |
     *               |             |
     *  setEmergencyState          setEmergencyState
     *  (NORMAL_FOREVER)           (EMERGENCY_FOREVER)
     *               |             |
     *               |             |
     *               v             v
     *  +-------------------+    +----------------------+
     *  |   NORMAL_FOREVER  |    |   EMERGENCY_FOREVER   |
     *  +-------------------+    +----------------------+
     *
     */

    /**
     * @dev Possible states of the emergency state variable.
     * NORMAL: no emergency is currently active.
     * NORMAL_FOREVER: no emergency is currently active and emergency state can never be set.
     * EMERGENCY_FOREVER: emergency is currently active and emergency state cannot be disabled.
     */
    enum EmergencyStateType {
        NORMAL,
        NORMAL_FOREVER,
        EMERGENCY_FOREVER
    }

    /**
     * @dev Current state of the emergency.
     */
    EmergencyStateType public emergencyState;

    event EmergencyStateSet(EmergencyStateType emergencyState);

    modifier notEmergency() {
        require(emergencyState < EmergencyStateType.EMERGENCY_FOREVER, "EmergencyState: emergency state is active");
        _;
    }

    modifier onlyEmergency() {
        require(emergencyState == EmergencyStateType.EMERGENCY_FOREVER, "EmergencyState: emergency state is not active");
        _;
    }

    /**
     * @dev Sets the emergency state.
     * @param _emergencyState The new emergency state.
     */
    function setEmergencyState(EmergencyStateType _emergencyState) external onlyOwner {
        require(emergencyState == EmergencyStateType.NORMAL, "EmergencyState: cannot change forever state");
        require(_emergencyState != EmergencyStateType.NORMAL, "EmergencyState: cannot set normal state");
        emergencyState = _emergencyState;
        emit EmergencyStateSet(_emergencyState);
    }
}