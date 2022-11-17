// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { IOrganizationManagement } from "../../../interfaces/core/organization/modules/IOrganizationManagement.sol";
import { Base } from "./Base.sol";
import { Signature } from "../../../static/Structs.sol";

import { ECDSA } from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

abstract contract OrganizationManagement is Base, IOrganizationManagement {
    using ECDSA for bytes32;

    /*******************************
     * Errors *
     *******************************/

    error InvalidNewSignerAddress();

    /*******************************
     * Events *
     *******************************/

    event SignerUpdated(address indexed newSigner);

    /*******************************
     * State vars *
     *******************************/

    /**
     * @notice Gap array, for further state variable changes
     */
    uint256[50] private __gap;

    /*******************************
     * Functions start *
     *******************************/

    function updateSigner(address newSigner) external onlyDiagonalAdmin {
        if (newSigner == address(0)) revert InvalidNewSignerAddress();
        signer = newSigner;
        emit SignerUpdated(newSigner);
    }
}