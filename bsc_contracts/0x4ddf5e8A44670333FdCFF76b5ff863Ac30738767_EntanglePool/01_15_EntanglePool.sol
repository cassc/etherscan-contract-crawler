//SPDX-License-Identifier: BSL 1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Lender.sol";
import "./PausableAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/EntangleData.sol";

contract EntanglePool is PausableAccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant DEPOSITER_ROLE = keccak256("DEPOSITER");


    constructor() {
        _setRoleAdmin(DEPOSITER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }
    
    event Deposit(uint256 amount, address token, uint256 opId);
    event Withdraw(uint256 amount, address token, uint256 opId);

    function depositToken(uint256 amount, IERC20 token, uint256 opId) external onlyRole(DEPOSITER_ROLE) whenNotPaused {
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(amount, address(token), opId);
    }

    function withdrawToken(uint256 amount, IERC20 token, address to, uint256 opId) external onlyRole(DEPOSITER_ROLE) whenNotPaused {
        token.safeTransfer(to, amount);
        emit Withdraw(amount, address(token), opId);
    }
}