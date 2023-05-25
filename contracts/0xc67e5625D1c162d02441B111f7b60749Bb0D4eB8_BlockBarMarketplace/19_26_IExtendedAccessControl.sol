// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;

import {IAccessControl} from "IAccessControl.sol";


/**
 * @title IExtendedAccessControl
 * @author aarora
 * @notice IExtendedAccessControl contains all external function interfaces and events
 */
interface IExtendedAccessControl is IAccessControl {
    /**
    * @notice get the owner of this contract
    *
    **/
    function getOwner() external returns(address owner);

    /**
     * @notice Pause contract modification activity
     */
    function pause() external;

    /**
     * @notice Unpause contract modification activity
     */
    function unpause() external;

}