// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenRedemption is AccessControl, ReentrancyGuard {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR ROLE");

    event Redeem(
        uint256 redeemId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    function redeem(
        uint256 _redeemId,
        address _token,
        address _to,
        uint256 _amount
    ) external nonReentrant onlyRole(OPERATOR_ROLE) {
        transferERC20(_token, _to, _amount);
        emit Redeem(_redeemId, _token, _to, _amount);
    }

    function transferERC20(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 balance = balanceOfERC20(_token);
        require(balance >= _amount, "TokenRedemption: Insufficient balance");
        IERC20(_token).transfer(_to, _amount);
    }

    function balanceOfERC20(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdrawERC20(address _token, address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = balanceOfERC20(_token);
        transferERC20(_token, _to, balance);
    }
}