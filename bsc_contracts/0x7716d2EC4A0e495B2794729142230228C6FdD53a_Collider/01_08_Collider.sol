// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Collider is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    event Deposit(address indexed player, uint amount);

    IERC20 public lhc;

    constructor(address _lhc, address _admin) {
        lhc = IERC20(_lhc);

        _grantRole(ADMIN_ROLE, _admin);
        _setRoleAdmin(TRANSFER_ROLE, ADMIN_ROLE);
    }

    function deposit(uint _amount) external {
        require(lhc.transferFrom(msg.sender, address(this), _amount), "Deposit fail");
        emit Deposit(msg.sender, _amount);
    }

    function claim(address _to, uint _amount) external onlyRole(TRANSFER_ROLE) {
        require(lhc.transfer(_to, _amount), "Claim fail");
    }

    function batchClaim(address[] memory _toArr, uint[]  memory _amountArr) external onlyRole(TRANSFER_ROLE) {
        require(_toArr.length == _amountArr.length, "Invalid input");
        for (uint idx; idx < _toArr.length; idx++) {
            require(lhc.transfer(_toArr[idx], _amountArr[idx]), "Claim fail");
        }
    }
}