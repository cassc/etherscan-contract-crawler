pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT
import "Auth.sol";

contract SecretPool is Auth {
    uint256 public totalEthLent;
    uint256 public totalAvailableEth;
    uint256 public withdrawQueueCount;
    uint256 public withdrawQueueLower;
    uint256 public _tokenDecimals = 1 * 10 ** 16;
    mapping(address => uint256) public usersCurrentLentAmount;
    mapping(address => uint256) public usersPendingReturnAmount;
    mapping(address => bool) public authorizedFactoryAddresses;
    mapping(uint256 => QueuePosition) public withdrawQueue;

    struct QueuePosition {
        address lender;
        uint256 amount;
    }
    event newFactory(address newFactory);
    event removedFactory(address removedFactory);
    event ethLent(address lender, uint256 amount);
    event ethWithdrawn(address lender, uint256 amount);
    event ethReturned(address lender, uint256 amount);
    event queueReset(uint256 blocknumber);
    event queueAdded(address lender, uint256 amount, uint256 position);
    event factoryStatusChange(address factoryAddress, bool status);

    constructor() Auth(msg.sender) {}

    modifier onlyFactoryAuthorized() {
        require(
            authorizedFactoryAddresses[msg.sender],
            "only factory contracts can borrow eth"
        );
        _;
    }

    function updateFactoryAuthorization(
        address addy,
        bool status
    ) external onlyOwner {
        authorizedFactoryAddresses[addy] = status;
        emit factoryStatusChange(addy, status);
    }

    receive() external payable {}

    function lendEth() external payable {
        require(
            msg.value > 0 && msg.value % _tokenDecimals == 0,
            "Only send full ether"
        );
        uint256 amountReceived = msg.value / _tokenDecimals;
        emit ethLent(msg.sender, amountReceived);
        totalEthLent += amountReceived;
        totalAvailableEth += amountReceived;
        usersCurrentLentAmount[msg.sender] += amountReceived;
    }

    function addQueue(address _lender, uint256 _amount) internal {
        usersPendingReturnAmount[_lender] += _amount * _tokenDecimals;
        withdrawQueue[withdrawQueueCount] = QueuePosition(
            _lender,
            _amount * _tokenDecimals
        );
        emit queueAdded(_lender, _amount * _tokenDecimals, withdrawQueueCount);
        withdrawQueueCount += 1;
    }

    function borrowEth(uint256 _amount) external onlyFactoryAuthorized {
        require(_amount <= totalAvailableEth, "Not Enough eth to borrow");
        totalAvailableEth -= _amount;
        payable(msg.sender).transfer(_amount * _tokenDecimals);
    }

    function returnLentEth() external payable returns (bool) {
        if (withdrawQueueCount > 0) {
            uint256 leftAmount = msg.value % _tokenDecimals;
            for (uint256 i = withdrawQueueLower; i < withdrawQueueCount; i++) {
                QueuePosition memory tempQueue = withdrawQueue[i];
                if (tempQueue.amount <= leftAmount) {
                    usersPendingReturnAmount[tempQueue.lender] -= tempQueue
                        .amount;
                    payable(tempQueue.lender).transfer(
                        tempQueue.amount * _tokenDecimals
                    );
                    emit ethWithdrawn(tempQueue.lender, tempQueue.amount);
                    leftAmount = leftAmount - tempQueue.amount;
                    withdrawQueueLower += 1;
                } else {
                    uint256 leftoverAmount = tempQueue.amount - leftAmount;
                    usersPendingReturnAmount[tempQueue.lender] -= leftAmount;
                    payable(tempQueue.lender).transfer(
                        leftAmount * _tokenDecimals
                    );
                    emit ethWithdrawn(tempQueue.lender, leftAmount);
                    withdrawQueue[i] = QueuePosition(
                        tempQueue.lender,
                        leftoverAmount
                    );
                    leftAmount = 0;
                }
                if (withdrawQueueLower == withdrawQueueCount) {
                    emit queueReset(block.number);
                    withdrawQueueCount = 0;
                    withdrawQueueLower = 0;
                    if (leftAmount > 0) {
                        totalAvailableEth += leftAmount;
                        emit ethReturned(msg.sender, leftAmount);
                        leftAmount = 0;
                    }
                }
                if (leftAmount == 0) {
                    return true;
                }
            }
        } else {
            uint256 amountReceived = msg.value / _tokenDecimals;
            emit ethReturned(msg.sender, amountReceived);
            totalEthLent += amountReceived;
            totalAvailableEth += amountReceived;
            return true;
        }
    }

    function withdrawLentEth(uint256 _amountEther) external payable {
        require(
            usersCurrentLentAmount[msg.sender] >= _amountEther,
            "You Did not lend that much"
        );
        require(_amountEther > 0, "Cant withdraw 0");
        usersCurrentLentAmount[msg.sender] -= _amountEther;
        if (totalAvailableEth == 0) {
            addQueue(msg.sender, _amountEther);
        } else if (totalAvailableEth < _amountEther) {
            uint256 leftoverAmount = _amountEther - totalAvailableEth;
            _amountEther = totalAvailableEth;
            totalAvailableEth = 0;
            payable(msg.sender).transfer(_amountEther * _tokenDecimals);
            emit ethWithdrawn(msg.sender, _amountEther);
            addQueue(msg.sender, leftoverAmount);
        } else {
            totalAvailableEth -= _amountEther;
            payable(msg.sender).transfer(_amountEther * _tokenDecimals);
            emit ethWithdrawn(msg.sender, _amountEther);
        }
    }

    function removedExcess() external payable authorized {
        require(
            address(this).balance > totalAvailableEth,
            "There is no excess eth"
        );
        uint256 excessAmount = address(this).balance - totalAvailableEth;
        payable(owner).transfer(excessAmount);
    }

    function authorizeNewFactory(address _newFactory) external authorized {
        authorizedFactoryAddresses[_newFactory] = true;
        emit newFactory(_newFactory);
    }

    function removeAuthorizedFactory(address _newFactory) external authorized {
        authorizedFactoryAddresses[_newFactory] = false;
        emit removedFactory(_newFactory);
    }
}