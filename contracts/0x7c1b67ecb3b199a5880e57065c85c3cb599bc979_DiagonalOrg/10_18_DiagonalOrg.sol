// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { OrganizationManagement } from "./modules/OrganizationManagement.sol";
import { Base } from "./modules/Base.sol";
import { Charge } from "./modules/Charge.sol";
import { IDiagonalOrg } from "../../interfaces/core/organization/IDiagonalOrg.sol";
import { Initializable } from "openzeppelin-contracts/proxy/utils/Initializable.sol";

contract DiagonalOrg is IDiagonalOrg, Initializable, Base, Charge, OrganizationManagement {
    /*******************************
     * Constants *
     *******************************/

    string public constant VERSION = "1.0.0";

    /*******************************
     * State vars *
     *******************************/

    /**
     * @notice Gap array, for further state variable changes
     */
    uint256[50] private __gap;

    /*******************************
     * Constructor *
     *******************************/

    constructor() {
        // Prevent the implementation contract from being initilised and re-initilised
        _disableInitializers();
    }

    /*******************************
     * Functions start *
     *******************************/

    function initialize(address _signer) external onlyInitializing {
        signer = _signer;
    }
}