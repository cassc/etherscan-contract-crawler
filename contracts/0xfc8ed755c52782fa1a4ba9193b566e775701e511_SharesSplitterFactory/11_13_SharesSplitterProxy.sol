// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../release/utils/NonUpgradableProxy.sol";

/// @title SharesSplitterProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all SharesSplitterProxy instances
contract SharesSplitterProxy is NonUpgradableProxy {
    constructor(bytes memory _constructData, address _sharesSplitterLib)
        public
        NonUpgradableProxy(_constructData, _sharesSplitterLib)
    {}
}