// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDistribution.sol";

contract Distribution is IDistribution, AccessControl {

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function recoverTokensFor(address _token, uint256 _amount, address _to) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(_to, _amount);
    }

}