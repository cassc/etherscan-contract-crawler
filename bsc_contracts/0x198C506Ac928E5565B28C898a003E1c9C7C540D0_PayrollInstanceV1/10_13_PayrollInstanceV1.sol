// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './interfaces/IOwnerChanger.sol';
import './interfaces/IPayrollInstanceV1.sol';
import './libraries/Months.sol';

contract PayrollInstanceV1 is IPayrollInstanceV1, Ownable, Pausable, Initializable, Multicall {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private members;
    mapping(address => Employee) public employees;
    mapping(address => uint) public fines;
    mapping(address => uint) public claimTimes;
    uint public lastUpdateTime;

    address public factory;

    function initialize() external initializer {
        _transferOwnership(msg.sender);
        factory = msg.sender;
    }

    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setEmployee(address employee, Employee calldata data, bool skipPayment) external whenNotPaused onlyOwner {
        if (members.contains(employee)) {
            if (!skipPayment && _toPay(employee) > 0) {
                pay(employee);
            }
        } else {
            members.add(employee);
            claimTimes[employee] = 0;
            fines[employee] = 0;
        }

        employees[employee] = data;
        employees[employee].token.balanceOf(address(this));
        require(
            employees[employee].startTime < employees[employee].endTime,
            'PayrollInstanceV1(setEmployee): employee.startTime must be less than employee.endTime'
        );

        emit Set(employee, employees[employee], skipPayment);

        lastUpdateTime = block.timestamp;
    }

    function removeEmployee(address employee, bool skipPayment) external whenNotPaused onlyOwner {
        require(members.contains(employee), 'PayrollInstanceV1(removeEmployee): not a member');

        if (!skipPayment && _toPay(employee) > 0) {
            pay(employee);
        }

        members.remove(employee);

        emit Removed(employee, skipPayment);

        lastUpdateTime = block.timestamp;
    }

    function changeEmployeeAddress(address employee, address newAddress, bool skipPayment) external whenNotPaused onlyOwner {
        require(members.contains(employee), 'PayrollInstanceV1(changeEmployeeAddress): not a member');
        require(!members.contains(newAddress), 'PayrollInstanceV1(changeEmployeeAddress): the member already exists');

        if (!skipPayment && _toPay(employee) > 0) {
            pay(employee);
        }
        employees[newAddress] = employees[employee];
        claimTimes[newAddress] = claimTimes[employee];
        fines[newAddress] = fines[employee];
        members.add(newAddress);
        members.remove(employee);

        lastUpdateTime = block.timestamp;

        emit EmployeeAddressChanged(employee, newAddress, skipPayment);
    }

    function increaseFine(address employee, uint fine) external whenNotPaused onlyOwner {
        require(members.contains(employee), 'PayrollInstanceV1(increaseFine): not a member');
        fines[employee] += fine;
        emit FineIncreased(employee, employees[employee].token, fine);
    }

    function decreaseFine(address employee, uint fine) external whenNotPaused onlyOwner {
        require(members.contains(employee), 'PayrollInstanceV1(decreaseFine): not a member');
        fines[employee] -= fine;
        emit FineDecreased(employee, employees[employee].token, fine);
    }

    function withdraw(IERC20 token, uint amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(token, amount);
    }

    function pay(address employee) public whenNotPaused {
        require(members.contains(employee), 'PayrollInstanceV1(pay): employee must be a member of team');

        uint amount = _toPay(employee);
        require(amount > 0, 'PayrollInstanceV1(pay): nothing to pay');

        employees[employee].token.safeTransfer(employee, amount);
        claimTimes[employee] = block.timestamp;
        fines[employee] = 0;

        emit Payed(employee, employees[employee].token, amount);
    }

    function payBonus(address employee, uint bonus) external whenNotPaused onlyOwner {
        require(members.contains(employee), 'PayrollInstanceV1(payBonus): not a member');
        employees[employee].token.safeTransfer(employee, bonus);
        emit BonusPayed(employee, employees[employee].token, bonus);
    }

    function getEmployees() external view returns (EmployeeView[] memory) {
        EmployeeView[] memory list = new EmployeeView[](members.length());
        for (uint i = 0; i < members.length(); i++) {
            address addr = members.at(i);
            list[i] = EmployeeView(
                addr,
                employees[addr],
                fines[addr],
                claimTimes[addr]
            );
        }
        return list;
    }

    function pending(address employee) public view returns (uint) {
        return pendingTill(employee, block.timestamp);
    }

    function pendingTill(address employee, uint tillTime) public view returns (uint) {
        require(members.contains(employee), 'PayrollInstanceV1(pending): not a member');

        Employee storage empl = employees[employee];

        uint sinceTime = empl.startTime;
        if (claimTimes[employee] + 1 > sinceTime) {
            sinceTime = claimTimes[employee] + 1;
        }
        if (tillTime > empl.endTime) {
            tillTime = empl.endTime;
        }
        if (sinceTime >= tillTime) {
            return 0;
        }

        if (empl.period < Period.Month) {
            return empl.salary * (tillTime - sinceTime + 1) / (empl.period == Period.Day ? 1 days : 1 weeks);
        }

        uint8 deno = empl.period == Period.Month ? 1 : 12;

        Months.Month memory since = Months.getMonth(sinceTime);
        if (tillTime <= since.end) {
            return empl.salary * (tillTime - sinceTime + 1) / since.length / deno;
        }

        uint forThisMonth = empl.salary * (since.end - sinceTime + 1) / since.length;
        // try to optimize calculation if we are in next month
        if (tillTime <= since.end + 31 days) {
            Months.Month memory next = Months.nextMonth(since);
            if (tillTime <= next.end) {
                return (forThisMonth + empl.salary * (tillTime + next.length - next.end) / next.length) / deno;
            }
        }

        Months.Month memory till = Months.getMonth(tillTime);
        return (
            empl.salary * (till.month - since.month - 1) + forThisMonth +
            empl.salary * (tillTime + till.length - till.end) / till.length
        ) / deno;
    }

    function getBalance(IERC20 token) external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function _toPay(address employee) private view returns (uint) {
        uint amount = pending(employee);
        if (amount > fines[employee]) {
            return amount - fines[employee];
        } else {
            return 0;
        }
    }

    function _transferOwnership(address newOwner) internal virtual override {
        if (factory != address(0)) { // the factory is not set yet when the instance is deploying
            IOwnerChanger(factory).updateOwner(owner(), newOwner);
        }
        super._transferOwnership(newOwner);
    }
}