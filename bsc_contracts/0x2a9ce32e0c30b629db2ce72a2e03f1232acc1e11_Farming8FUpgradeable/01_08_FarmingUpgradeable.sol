// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ERC20Interface {
    function balanceOf(address whom) view virtual public returns (uint);

    function transfer(address to, uint256 amount) public virtual returns (bool);

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool);
}

contract Farming8FUpgradeable is Initializable, OwnableUpgradeable {
    address public rewardTokenAddress;
    address lpTokenAddress;
    uint256 public currentRewardTime;
    uint256 public currentRewardAmount;
    uint256 public currentRewardPerSecond;
    uint public lockTime;

    function initialize(
        address _rewardTokenAddress,
        address _lpTokenAddress,
        uint256 _rewardTime,
        uint256 _rewardAmount,
        uint _lockTime
    ) initializer public {
        __Ownable_init();
        rewardTokenAddress = _rewardTokenAddress;
        lpTokenAddress = _lpTokenAddress;
        require(_rewardAmount > 0, 'rewardAmount >0');
        require(_rewardTime > 0, 'rewardTime >0');
        changeRewardSystem(_rewardTime, _rewardAmount, _lockTime);
    }

    event RewardSystemChanged(uint256 rewardTime, uint256 rewardAmount, uint256 _lockTime);
    event RewardClaimed(address account, uint256 amount);
    event BodyClaimed(address account, uint256 amount);
    event Farmed(address account, uint256 amount);



    struct Payment {
        address account;
        uint256 amount;
        uint timestamp;
        uint256 withdrawed;
        bool locked;
        uint256 rewardPerSecond;
    }

    mapping(address => uint256) userFarmBalances;
    mapping(address => uint256) userStakeTaken;

    function decimals() public pure returns (uint256) {
        return 10 ** 18;
    }

    function currentUserAddress() public view returns (address) {
        return tx.origin;
    }

    Payment[] payments;

    function getPayment(address account) public view returns (Payment[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.account == account) {
                count++;
            }
        }

        Payment[] memory _tokensOfOwner = new Payment[](count);
        uint256 addedPayments = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.account == account) {
                _tokensOfOwner[addedPayments] = payment;
                addedPayments++;
            }
        }

        return _tokensOfOwner;
    }

    function getBody(address account) public view returns (uint256 body) {
        Payment[] memory accountPayments = getPayment(account);
        for (uint256 i = 0; i < accountPayments.length; i++) {
            body += accountPayments[i].amount - accountPayments[i].withdrawed;
        }
    }

    function farm(uint256 amount, bool locked) public {
        bool s = ERC20Interface(lpTokenAddress).transferFrom(currentUserAddress(), address(this), amount);
        require(s, "transfer error");

        Payment memory newPayment = Payment(
            currentUserAddress(),
            amount,
            block.timestamp,
            0,
            locked,
            0
        );

        payments.push(newPayment);
        userFarmBalances[currentUserAddress()] += amount;
        emit Farmed(currentUserAddress(), amount);
    }

    function calculateResult(uint256 amount, uint256 timestampStart, uint256 currentTimestamp, uint256 rewardPerSecond) public view returns (uint256) {
        return amount * (currentTimestamp - timestampStart) * (rewardPerSecond);
    }

    function rewardTokenBalance() public view onlyOwner returns (uint256) {
        return ERC20Interface(rewardTokenAddress).balanceOf(address(this));
    }

    function getCurrentRewardAmount(address account) public view returns (uint256 fullAmount, uint256 timestamp) {
        timestamp = block.timestamp;
        uint256 prevAmount = 0;
        uint256 neededAccountAmount = 0;
        uint256 prevTxTimestamp = payments[0].timestamp;
        uint256 rewardPerSecond = 0;
        uint256 decimalsDelimiter = decimals();
        uint256 currentPercentOfReward = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (neededAccountAmount != 0 && prevAmount != 0) {
                currentPercentOfReward = decimalsDelimiter * neededAccountAmount / prevAmount;
            }
            if (payment.rewardPerSecond > 0) {
                rewardPerSecond = payment.rewardPerSecond;
            } else {
                uint256 secondsPassed = payment.timestamp - prevTxTimestamp;
                uint256 increaseValue = secondsPassed * rewardPerSecond * currentPercentOfReward;
                fullAmount += increaseValue / decimalsDelimiter;
                if (payment.account == account) {
                    neededAccountAmount += payment.amount - payment.withdrawed;
                    if (payment.locked) {
                        neededAccountAmount += payment.amount;
                    }
                    fullAmount -= payment.withdrawed;
                }
            }
            prevAmount += payment.amount;
            prevTxTimestamp = payment.timestamp;
        }
        uint256 addAmount = (timestamp - prevTxTimestamp) * rewardPerSecond *
        (decimalsDelimiter * neededAccountAmount / prevAmount)
        /
        decimalsDelimiter;
        fullAmount += addAmount;
    }

    function changeRewardSystem(uint256 rewardTime, uint256 rewardAmount, uint256 _lockTime) public onlyOwner {
        currentRewardPerSecond = rewardAmount / rewardTime;
        Payment memory newPayment = Payment(
            _msgSender(),
            0,
            block.timestamp,
            0,
            false,
            currentRewardPerSecond
        );
        payments.push(newPayment);
        lockTime = _lockTime;
        emit RewardSystemChanged(rewardTime, rewardAmount, _lockTime);
    }

    function claimMyReward() public {
        (uint256 fullAmount,) = getCurrentRewardAmount(currentUserAddress());
        fullAmount -= userStakeTaken[currentUserAddress()];
        require(fullAmount > 0, "Nothing to claim");
        bool status = ERC20Interface(rewardTokenAddress).transfer(currentUserAddress(), fullAmount);
        require(status, 'transfer error');
        userStakeTaken[currentUserAddress()] += fullAmount;
        emit RewardClaimed(currentUserAddress(), fullAmount);
    }

    function claimMyBody(uint256 amount) public {
        address userAddress = currentUserAddress();
        uint256 currentBody = userFarmBalances[userAddress] - getLockedAccountAmount(userAddress);
        require(currentBody >= amount, 'not enough money to withdraw');
        bool status = ERC20Interface(lpTokenAddress).transfer(userAddress, amount);
        require(status, 'transfer error');
        Payment memory newPayment = Payment(
            userAddress,
            0,
            block.timestamp,
            amount,
            false,
            0
        );
        payments.push(newPayment);
        emit BodyClaimed(currentUserAddress(), amount);
    }

    function getLockedAccountAmount(address account) public view returns (uint256 locked) {
        Payment[] memory payments = getPayment(account);
        uint lockBeforeTime = block.timestamp - lockTime;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.locked && payment.timestamp < lockBeforeTime) {
                locked += payment.amount;
            }
        }
    }

    function version() public view returns (uint) {
        return 1;
    }
}