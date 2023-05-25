// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UriChangerBase.sol";

abstract contract UriChanger is UriChangerBase {

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _newUriChanger) {
        _updateUriChanger(_newUriChanger);
    }

}