// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "torn-token/contracts/ENS.sol";

/**
 * @dev TransparentUpgradeableProxy that sets its admin to the implementation itself.
 * It is also allowed to call implementation methods.
 */
contract LoopbackProxy is TransparentUpgradeableProxy, EnsResolve {
    /**
     * @dev Initializes an upgradeable proxy backed by the implementation at `_logic`.
     */
    constructor(address _logic, bytes memory _data)
        public
        payable
        TransparentUpgradeableProxy(_logic, address(this), _data)
    { }

    /**
     * @dev Override to allow admin (itself) access the fallback function.
     */
    function _beforeFallback() internal override { }
}