// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IInterconnector.sol";
import "./ILinkageLeaf.sol";

interface IInterconnectorLeaf is ILinkageLeaf {
    function getInterconnector() external view returns (IInterconnector);
}