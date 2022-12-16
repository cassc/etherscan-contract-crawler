// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDistribution.sol";

contract Distribution is IDistribution, AccessControl {

    bytes32 public constant override OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    function recoverTokens(address _token, uint256 _amount) external override onlyRole(OPERATOR_ROLE) {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function recoverTokensFor(address _token, uint256 _amount, address _to) external override onlyRole(OPERATOR_ROLE) {
        IERC20(_token).transfer(_to, _amount);
    }

}