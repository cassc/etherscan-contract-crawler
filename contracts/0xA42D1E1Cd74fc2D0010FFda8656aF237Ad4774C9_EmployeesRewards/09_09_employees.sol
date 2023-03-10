// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";
import "@openzeppelin/utils/Address.sol";
import "@openzeppelin/utils/math/SafeMath.sol";

contract EmployeesRewards is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint32;
    using SafeMath for uint256;

    IERC20 public rewardTokenAddress;
    uint256 decimals = uint256(1).mul((uint256(10)) ** 18);

    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;

    struct EmployeesInfo {
        uint256 tokenAmount;
        uint32 registrationDay;
        uint32 endDay;
        bool isRewardActive;
    }

    mapping(address => EmployeesInfo) internal rewards;

    error ZeroAddressProvided();
    error EndDayNotValid();
    error InvalidTokenAmount();
    error EmployeeAlreadyRegistered(address addressToCheck);
    error EmployeeNotRegistered(address addressToCheck);
    error EndDayNotReached();
    error NotEnoughTokenAmountInContract();

    constructor(address _tokenAddress) {
        if (address(_tokenAddress) == address(0)) {
            revert ZeroAddressProvided();
        }
        rewardTokenAddress = IERC20(_tokenAddress);
    }

    function initRewardTime(
        address _employee,
        uint256 _rewardTokenAmount,
        uint32 _endDay
    ) external onlyOwner {
        if (_endDay <= 0) {
            revert EndDayNotValid();
        }
        if (_employee == address(0)) {
            revert ZeroAddressProvided();
        }
        if (_rewardTokenAmount <= 0) {
            revert InvalidTokenAmount();
        }
        if (isEmployeeRegistered(_employee)) {
            revert EmployeeAlreadyRegistered(_employee);
        }
        _initRewardTime(_employee, _rewardTokenAmount, _endDay);
    }

    function _initRewardTime(
        address _employee,
        uint256 _rewardTokenAmount,
        uint32 _endDay
    ) internal {
        uint256 tokenToTransfer = _rewardTokenAmount.mul(decimals);
        uint32 endDay = uint32(today().add(_endDay));

        rewards[_employee] =
            EmployeesInfo(tokenToTransfer, today(), endDay, true);
        rewardTokenAddress.approve(_employee, tokenToTransfer);
    }

    function finishRewardTime(address _employee)
        external
        nonReentrant
        onlyOwner
    {
        EmployeesInfo storage employee = rewards[_employee];
        if (!isEmployeeRegistered(_employee)) {
            revert EmployeeNotRegistered(_employee);
        }
        if (
            today() < employee.registrationDay
                || today().sub(employee.registrationDay) < employee.endDay
        ) {
            revert EndDayNotReached();
        }
        uint256 tokenAmount = employee.tokenAmount;
        if (rewardTokenAddress.balanceOf(address(this)) < tokenAmount) {
            revert NotEnoughTokenAmountInContract();
        }
        _finishRewardTime(_employee, tokenAmount);
    }

    function _finishRewardTime(address _employee, uint256 _tokenAmount)
        internal
    {
        EmployeesInfo storage employee = rewards[_employee];
        employee.tokenAmount = 0;
        employee.isRewardActive = false;
        rewardTokenAddress.transfer(_employee, _tokenAmount);
    }

    function updateAddressTokenAmount(address _employee, uint256 _tokenAmount)
        external
        onlyOwner
    {
        if (!isEmployeeRegistered(_employee)) {
            revert EmployeeNotRegistered(_employee);
        }
        rewards[_employee].tokenAmount = _tokenAmount;
    }

    function revokeRewards(address _employee) external onlyOwner {
        if (!isEmployeeRegistered(_employee)) {
            revert EmployeeNotRegistered(_employee);
        }
        EmployeesInfo storage employee = rewards[_employee];
        employee.tokenAmount = 0;
        employee.isRewardActive = false;
    }

    function withdrawTokens(uint256 _amountToWithdraw) external onlyOwner {
        require(
            _amountToWithdraw > 0
                && _amountToWithdraw <= rewardTokenAddress.balanceOf(address(this)),
            "Wrong amount"
        );

        address caller = address(_msgSender());

        rewardTokenAddress.approve(caller, _amountToWithdraw);
        rewardTokenAddress.transfer(caller, _amountToWithdraw);
    }

    function today() public view returns (uint32 dayNumber) {
        return uint32(block.timestamp.div(SECONDS_PER_DAY));
    }

    function isEmployeeRegistered(address _employee)
        public
        view
        returns (bool)
    {
        EmployeesInfo storage employee = rewards[_employee];
        return employee.isRewardActive;
    }

    function getRegistrationDay(address _employee)
        public
        view
        returns (uint32)
    {
        return rewards[_employee].registrationDay;
    }

    function getEndDay(address _employee) external view returns (uint256) {
        return rewards[_employee].endDay;
    }

    function getTokenAmount(address _employee)
        external
        view
        returns (uint256)
    {
        return rewards[_employee].tokenAmount;
    }
}