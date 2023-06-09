// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface INonTransparentProxied {

    /**
     *  @dev    Returns the proxy's admin address.
     *  @return admin_ The address of the admin.
     */
    function admin() external view returns (address admin_);

    /**
     *  @dev    Returns the proxy's implementation address.
     *  @return implementation_ The address of the implementation.
     */
    function implementation() external view returns (address implementation_);

}