// SPDX-License-Identifier: MIT
/*
https://integroo.group/
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KangarooLearn is Ownable {
    IERC20 public immutable learnToken;
    uint256 public gasFee;
    uint256 public withdrawalLimit;

    mapping(address => User) public users;

    struct User {
        uint256 lastWithdrawTimestamp;
        bool inProcess;
    }

    event WithdrawalRequest(address user);
    event Withdrawal(address user, uint256 amount);
    event Replenishment(address user, uint256 amount);
    event GasFeeChanged(uint256 gasFee);
    event WithdrawalLimitChanged(uint256 withdrawalLimit);
    event OwnerWithdrawal(uint256 amount);

    constructor(
        address _rooToken,
        uint256 _gasFee,
        uint256 _withdrawalLimit
    ) {
        learnToken = IERC20(_rooToken);
        gasFee = _gasFee;
        withdrawalLimit = _withdrawalLimit;
    }

    function setGasFee(uint256 _gasFee) external onlyOwner {
        gasFee = _gasFee;
        emit GasFeeChanged(_gasFee);
    }

    function setWithdrawalLimit(uint256 _withdrawalLimit) external onlyOwner {
        withdrawalLimit = _withdrawalLimit;
        emit WithdrawalLimitChanged(_withdrawalLimit);
    }

    function ownerWithdraw(uint256 _amount) external onlyOwner {
        learnToken.transfer(msg.sender, _amount);
        emit OwnerWithdrawal(_amount);
    }

    function replenish(uint256 _amount) external {
        require(learnToken.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to replenishment!");

        learnToken.transferFrom(msg.sender, address(this), _amount);
        emit Replenishment(msg.sender, _amount);
    }

    function requestWithdrawal() external payable {
        require(msg.value >= gasFee, "Not enough gas to pay the fee!");
        require(users[msg.sender].inProcess == false, "Withdrawal in process!");
        require(
            block.timestamp - users[msg.sender].lastWithdrawTimestamp > 24 hours,
            "Withdrawal is allowed only once per 24 hours!"
        );

        users[msg.sender].lastWithdrawTimestamp = block.timestamp;
        users[msg.sender].inProcess = true;

        payable(owner()).transfer(msg.value);

        emit WithdrawalRequest(msg.sender);
    }

    function withdraw(address _user, uint256 _amount) external onlyOwner {
        require(users[_user].inProcess == true, "There were no withdrawal requests!");
        require(_amount <= withdrawalLimit, "Withdrawal limit exceeded!");

        users[_user].inProcess = false;

        learnToken.transfer(_user, _amount);

        emit Withdrawal(_user, _amount);
    }
}