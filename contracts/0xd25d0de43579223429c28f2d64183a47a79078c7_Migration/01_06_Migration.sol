// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/interfaces/IBaseVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Migration is Ownable, ReentrancyGuard {
    IBaseVault public vaultV1;
    IBaseVault public vaultV2;

    address public treasury;

    address[] public users;

    IERC20 public token;

    mapping(address user => uint256 balance) public userToBalance;

    address[] public notWithdrawnUsers;

    constructor(address _vaultV1, address[] memory _users, address _treasury) {
        vaultV1 = IBaseVault(_vaultV1);
        users = _users;
        treasury = _treasury;
        token = vaultV1.token();
        vaultV1.token().approve(treasury, type(uint256).max);
    }

    function setVaultV2(address _vaultV2) external onlyOwner {
        vaultV2 = IBaseVault(_vaultV2);
        vaultV1.token().approve(address(vaultV2), type(uint256).max);
    }

    function addUsers(address[] memory _newUsers) external onlyOwner {
        for (uint256 i = 0; i < _newUsers.length; i++) {
            users.push(_newUsers[i]);
        }
    }

    function withdraw() external nonReentrant {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 userBalance = IERC20(address(vaultV1)).balanceOf(users[i]);
            if (userBalance == 0) {
                continue;
            }
            if (
                IERC20(address(vaultV1)).allowance(users[i], address(this)) <
                userBalance
            ) {
                if (!checkUserExistence(users[i])) {
                    notWithdrawnUsers.push(users[i]);
                }
                continue;
            }
            IERC20(address(vaultV1)).transferFrom(
                users[i],
                address(this),
                userBalance
            );

            userToBalance[users[i]] += userBalance;
        }
        if (IERC20(address(vaultV1)).balanceOf(address(this)) > 0) {
            vaultV1.withdraw();
        }
    }

    function withdrawUsersWithDetectedError() external nonReentrant {
        for (uint256 i = 0; i < notWithdrawnUsers.length; i++) {
            if (notWithdrawnUsers[i] == address(0)) {
                continue;
            }
            uint256 userBalance = IERC20(address(vaultV1)).balanceOf(
                notWithdrawnUsers[i]
            );
            if (
                userBalance == 0 ||
                IERC20(address(vaultV1)).allowance(
                    notWithdrawnUsers[i],
                    address(this)
                ) <
                userBalance
            ) {
                continue;
            }
            IERC20(address(vaultV1)).transferFrom(
                notWithdrawnUsers[i],
                address(this),
                userBalance
            );

            userToBalance[notWithdrawnUsers[i]] += userBalance;

            notWithdrawnUsers[i] = address(0);
        }
        vaultV1.withdraw();
    }

    function deposit() external nonReentrant {
        vaultV2.deposit(token.balanceOf(address(this)), address(this));
    }

    function emergencyExit() external onlyOwner {
        vaultV1.token().transfer(treasury, token.balanceOf(address(this)));
        IERC20(address(vaultV2)).transfer(
            treasury,
            IERC20(address(vaultV2)).balanceOf(address(this))
        );
        IERC20(address(vaultV1)).transfer(
            treasury,
            IERC20(address(vaultV1)).balanceOf(address(this))
        );
    }

    function checkUserExistence(address _user) internal view returns (bool) {
        for (uint256 i = 0; i < notWithdrawnUsers.length; i++) {
            if (notWithdrawnUsers[i] == _user) {
                return true;
            }
        }
        return false;
    }
}