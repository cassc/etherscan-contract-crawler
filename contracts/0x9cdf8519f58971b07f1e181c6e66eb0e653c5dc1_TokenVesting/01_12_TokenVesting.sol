// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    event SetSchedule(
        address indexed beneficiary,
        uint[] schedule,
        uint[] amount
    );
    event Released(address indexed beneficiary, uint amount);

    IERC20 private immutable _token;
    EnumerableMap.AddressToUintMap private vestingSchedulesTotalAmount;
    mapping(address => uint[]) private vestingSchedules;
    mapping(address => uint[]) private vestingAmounts;
    mapping(address => uint) public releasedIndex;
    mapping(address => uint) public releasedTotalAmount;

    constructor(IERC20 token_) {
        _token = token_;
    }

    function setSchedule(
        address _beneficiary,
        uint[] calldata _schedule,
        uint[] calldata _amount
    ) external onlyOwner {
        require(
            _beneficiary != address(0),
            "TokenVesting: beneficiary cannot be the zero address"
        );
        require(
            _schedule.length > 0 && _schedule.length == _amount.length,
            "TokenVesting: invalid schedule"
        );

        uint totalAmount = 0;
        for (uint i = 0; i < _schedule.length; i++) {
            totalAmount += _amount[i];
        }

        vestingSchedulesTotalAmount.set(_beneficiary, totalAmount);
        vestingSchedules[_beneficiary] = _schedule;
        vestingAmounts[_beneficiary] = _amount;

        emit SetSchedule(_beneficiary, _schedule, _amount);
    }

    function getSchedule(address _beneficiary)
        public
        view
        returns (uint[] memory schedule, uint[] memory amount)
    {
        schedule = vestingSchedules[_beneficiary];
        amount = vestingAmounts[_beneficiary];
    }

    function getVestingScheduleTotalAmount(address _beneficiary)
        public
        view
        returns (uint)
    {
        return vestingSchedulesTotalAmount.get(_beneficiary);
    }

    function getReleasableAmount(address beneficiary)
        public
        view
        returns (uint)
    {
        (bool isBeneficiary, ) = vestingSchedulesTotalAmount.tryGet(
            beneficiary
        );

        if (!isBeneficiary) {
            return 0;
        }

        uint releasableAmount = 0;
        for (
            uint i = releasedIndex[beneficiary];
            i < vestingSchedules[beneficiary].length;
            i++
        ) {
            if (block.timestamp >= vestingSchedules[beneficiary][i]) {
                releasableAmount = vestingAmounts[beneficiary][i];
                break;
            }
        }

        return releasableAmount;
    }

    function release() external nonReentrant {
        (bool isBeneficiary, ) = vestingSchedulesTotalAmount.tryGet(msg.sender);

        if (!isBeneficiary) {
            revert("TokenVesting: only beneficiary can release vested tokens");
        }

        uint releasableAmount = getReleasableAmount(msg.sender);

        if (releasableAmount > 0) {
            releasedIndex[msg.sender] += 1;
            releasedTotalAmount[msg.sender] += releasableAmount;
            _token.safeTransfer(payable(msg.sender), releasableAmount);
            emit Released(msg.sender, releasableAmount);
        }
    }

    function getWithdrawableAmount() public view returns (uint) {
        uint totalAmount = 0;
        for (uint i = 0; i < vestingSchedulesTotalAmount.length(); i++) {
            (address addr, uint amount) = vestingSchedulesTotalAmount.at(i);
            totalAmount += amount - releasedTotalAmount[addr];
        }

        return _token.balanceOf(address(this)).sub(totalAmount);
    }

    function withdraw(uint amount) external nonReentrant onlyOwner {
        require(
            getWithdrawableAmount() >= amount,
            "TokenVesting: not enough withdrawable funds"
        );
        _token.safeTransfer(owner(), amount);
    }
}