// SPDX-License-Identifier: CAL
pragma solidity ^0.8.17;

import "rain.interface.interpreter/IExpressionDeployerV1.sol";

library LibDeployerDiscoverable {
    /// Hack so that some deployer will emit an event with the sender as the
    /// caller of `touchDeployer`. This MAY be needed by indexers such as
    /// subgraph that can only index events from the first moment they are aware
    /// of some contract. The deployer MUST be registered in ERC1820 registry
    /// before it is touched, THEN the caller meta MUST be emitted after the
    /// deployer is touched. This allows indexers such as subgraph to index the
    /// deployer, then see the caller, then see the caller's meta emitted in the
    /// same transaction.
    /// This is NOT required if ANY other expression is deployed in the same
    /// transaction as the caller meta, there only needs to be one expression on
    /// ANY deployer known to ERC1820.
    function touchDeployer(address deployer_) internal {
        IExpressionDeployerV1(deployer_).deployExpression(
            new bytes[](0),
            new uint256[](0),
            new uint256[](0)
        );
    }
}