// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../utils/Proxy.sol";

/// @title ComptrollerProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy contract for all ComptrollerProxy instances
contract ComptrollerProxy is Proxy {
    constructor(bytes memory _constructData, address _comptrollerLib)
        public
        Proxy(_constructData, _comptrollerLib)
    {}
}