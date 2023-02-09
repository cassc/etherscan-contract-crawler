// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IArbitrable } from "src/interfaces/IArbitrable.sol";
import { IAgreementFramework } from "src/interfaces/IAgreementFramework.sol";
import { Owned } from "src/utils/Owned.sol";

abstract contract AgreementFramework is IAgreementFramework, Owned {
    /// @inheritdoc IArbitrable
    address public arbitrator;

    /// @notice Raised when the arbitration power is transferred.
    /// @param newArbitrator Address of the new arbitrator.
    event ArbitrationTransferred(address indexed newArbitrator);

    /// @notice Transfer the arbitration power of the agreement.
    /// @param newArbitrator Address of the new arbitrator.
    function transferArbitration(address newArbitrator) public virtual onlyOwner {
        arbitrator = newArbitrator;

        emit ArbitrationTransferred(newArbitrator);
    }
}