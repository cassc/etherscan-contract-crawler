// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./lib/IERC20.sol";
import "./lib/Ownable.sol";

interface IAmbassadors {
    function deposit(address, uint256, uint256) external;
    function withdraw(uint256) external;
    function emergencyWithdraw(uint256) external;

    event Deposit(address, uint256, uint256);
    event Withdraw(uint256);
    event EmergencyWithdraw(uint256);
}

contract Ambassadors is IAmbassadors, Ownable {
    address public token;

    struct DepositStruct {
        address wallet;
        uint256 amount;
        uint256 unlockBlock;
        bool status;
    }

    mapping(uint256 => DepositStruct) public deposits;
    uint256 public depositsLength = 0;

    mapping(address => uint256[]) public depositsByWallet;

    constructor(address _token) public {
        token = _token;
    }

    modifier checkDeposit(uint256 id) {
        require(deposits[id].status, 'Deposit is already withdrawn');
        require(deposits[id].wallet == msg.sender, 'Wrong sender');
        require(deposits[id].unlockBlock <= block.number, 'Deposit is locked');
        _;
    }

    function deposit(address wallet, uint256 amount, uint256 unlockBlock) external override {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        deposits[depositsLength] = DepositStruct(wallet, amount, unlockBlock, true);
        depositsByWallet[wallet].push(depositsLength);
        depositsLength++;

        emit Deposit(wallet, amount, unlockBlock);
    }

    function withdraw(uint256 id) external override checkDeposit(id) {
        deposits[id].status = false;

        IERC20(token).transfer(deposits[id].wallet, deposits[id].amount);
        emit Withdraw(id);
    }

    function emergencyWithdraw(uint256 id) external override onlyOwner {
        deposits[id].status = false;

        IERC20(token).transfer(owner(), deposits[id].amount);
        emit EmergencyWithdraw(id);
    }
}