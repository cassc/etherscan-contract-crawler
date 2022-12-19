//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibGroup} from "../../libraries/LibGroup.sol";
import {IGroup} from "../../interfaces/IGroup.sol";
import {IWallet} from "../../interfaces/IWallet.sol";
import {DiamondReentrancyGuard} from "../../access/DiamondReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Please see `IGroup` for docs
contract GroupFacet is IGroup, DiamondReentrancyGuard {
    function join(bytes memory data) external payable override {
        LibGroup._untrustedJoinDecode(data);
    }

    function acquireMore(bytes memory data) external payable override {
        LibGroup._untrustedAcquireMoreDecode(data);
    }

    function leave() external override nonReentrant {
        LibGroup._leave();
    }

    /// @dev Returns the value needed to send when a members wants to `join` the group, if the
    /// member wants to acquire `ownershipUnits` ownership units.
    /// You can use this function to know the value to pass to `join`/`acquireMore`.
    /// @return total The total value you need to pass on `join` (`ownershipUnits` + `anticFee` + `deploymentRefund`)
    /// @return anticFee The antic fee that will be collected
    /// @return deploymentRefund The deployment refund that will be passed to the group deployer
    function calculateValueToPass(uint256 ownershipUnits)
        public
        view
        returns (
            uint256 total,
            uint256 anticFee,
            uint256 deploymentRefund
        )
    {
        (anticFee, deploymentRefund) = LibGroup._calculateExpectedValue(
            ownershipUnits
        );
        total = anticFee + deploymentRefund + ownershipUnits;
    }

    /// @return true, if `proposition` is the forming proposition
    function isValidFormingProposition(IWallet.Proposition memory proposition)
        external
        view
        returns (bool)
    {
        return LibGroup._isValidFormingProposition(proposition);
    }
}