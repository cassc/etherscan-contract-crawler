// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBank.sol";

contract Bank is IBank, AccessControl {

    bytes32 public constant override OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IERC20 public override token;

    constructor(IERC20 _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        updateToken(_token);
    }

    function balance() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function updateToken(IERC20 _token) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        token = _token;
    }

    function recoverTokens(uint256 _amount) external override onlyRole(OPERATOR_ROLE) {
        token.transfer(msg.sender, _amount);
    }

    function recoverTokensFor(uint256 _amount, address _to) external override onlyRole(OPERATOR_ROLE) {
        token.transfer(_to, _amount);
    }

}