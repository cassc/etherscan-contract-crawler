//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/Withdrawable.sol";
import "./utils/AccessControlled.sol";

contract UpcadeVault is Ownable, Withdrawable, AccessControlled {
    using SafeERC20 for IERC20;

    IERC20 public token;

    mapping(address => uint256) public deposited;

    mapping(address => uint256) public rewarded;

    event Deposited(address indexed from, uint256 amount, bytes payload);

    event Rewarded(address indexed awarded, uint256 amount, string uuid);

    modifier protectedWithdrawal() override {
        _checkRole(MANAGER_ROLE);
        _;
    }

    constructor() {
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* Configuration
     ****************************************************************/

    function setToken(address token_) external onlyRole(MANAGER_ROLE) {
        token = IERC20(token_);
    }

    /* Domain
     ****************************************************************/

    function deposit(uint256 amount, bytes calldata payload) external {
        token.safeTransferFrom(_msgSender(), address(this), amount);

        deposited[_msgSender()] += amount;

        emit Deposited(_msgSender(), amount, payload);
    }

    function reward(address awarded, uint256 amount, string calldata uuid) external onlyRole(MANAGER_ROLE) {
        token.safeTransfer(awarded, amount);

        rewarded[_msgSender()] += amount;

        emit Rewarded(awarded, amount, uuid);
    }
}