// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

interface IPayrollInstanceV1 {
    enum Period {
        Day,
        Week,
        Month,
        Year
    }

    struct Employee {
        IERC20 token;
        Period period;
        uint salary;
        uint startTime;
        uint endTime;
    }

    struct EmployeeView {
        address addr;
        Employee employee;
        uint fine;
        uint claimTime;
    }

    event Set(address indexed employee, Employee data, bool skipPayment);
    event Removed(address indexed employee, bool skipPayment);
    event EmployeeAddressChanged(address indexed employee, address newAddress, bool skipPayment);
    event FineIncreased(address indexed employee, IERC20 token, uint amount);
    event FineDecreased(address indexed employee, IERC20 token, uint amount);
    event Withdrawn(IERC20 indexed token, uint amount);
    event Payed(address indexed employee, IERC20 token, uint amount);
    event BonusPayed(address indexed employee, IERC20 token, uint amount);

    function setPause(bool pause) external;
    function setEmployee(address employee, Employee calldata data, bool skipPayment) external;
    function removeEmployee(address employee, bool skipPayment) external;
    function changeEmployeeAddress(address employee, address newAddress, bool skipPayment) external;
    function increaseFine(address employee, uint fine) external;
    function decreaseFine(address employee, uint fine) external;
    function withdraw(IERC20 token, uint amount) external;
    function pay(address employee) external;
    function payBonus(address employee, uint bonus) external;

    function lastUpdateTime() external view returns (uint);
    function pending(address employee) external view returns (uint);
    function getEmployees() external view returns (EmployeeView[] memory);
    function getBalance(IERC20 token) external view returns (uint);
}