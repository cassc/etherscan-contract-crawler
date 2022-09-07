// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

import './PayrollFactory.sol';
import './interfaces/IPayrollInstanceV1.sol';

contract PayrollHelperV1 {
    PayrollFactory public factory;

    constructor(PayrollFactory _factory) {
        factory = _factory;
    }

    function getEmployees(address employer) external view returns (IPayrollInstanceV1.EmployeeView[] memory) {
        address instance = factory.instances(employer);
        require(instance != address(0), 'PayrollHelperV1(getEmployees): instance not found');
        return IPayrollInstanceV1(instance).getEmployees();
    }

    function getBalance(address employer, IERC20 token) external view returns (uint) {
        address instance = factory.instances(employer);
        require(instance != address(0), 'PayrollHelperV1(getBalance): instance not found');
        return IPayrollInstanceV1(instance).getBalance(token);
    }

    function getLastUpdateTime(address employer) external view returns (uint) {
        address instance = factory.instances(employer);
        require(instance != address(0), 'PayrollHelperV1(getLastUpdateTime): instance not found');
        return IPayrollInstanceV1(instance).lastUpdateTime();
    }
}