// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UriChangerBase.sol";

abstract contract UriChangerUpgradeable is UriChangerBase {

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __UriChanger_init(address _newUriChanger) internal {
        __UriChanger_onlyInitializing();
        _updateUriChanger(_newUriChanger);
    }

    // override this function to limit to onlyInitializing
    function __UriChanger_onlyInitializing() internal virtual;

}