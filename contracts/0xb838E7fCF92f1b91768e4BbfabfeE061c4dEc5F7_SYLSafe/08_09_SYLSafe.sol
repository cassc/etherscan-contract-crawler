// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../SYLToken/SYLVestingWallet.sol";

interface ISYLSafe {
    function deposit(uint256 depositAmount) external;

    function withdraw() external;

    function withdrawAll() external;

    function safeStatus() external view returns (uint256[] memory);

    function savingStatus(address addr) external view returns (uint256[] memory);

    function matured() external view returns (bool);
}

/**
 * @author syllabs
 * @title SYLSafe
 */
contract SYLSafe is ISYLSafe, Ownable {
    IERC20 immutable private _erc20;
    SYLVestingWallet immutable private _marketing;
    uint256 immutable private _safeStart;
    uint256 immutable private _safeEnd;
    uint256 immutable private _annualPercentageRate;
    uint256 immutable private _totalAllocation;
    uint256 immutable private _minDeposit;
    uint256 immutable private _maxDeposit;
    bool immutable private _cancellable;

    mapping(address => Saving) private _savings;
    mapping(address => bool) private _deposited;
    uint256 private _allocated;

    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    struct Saving {
        uint256 start;
        uint256 amount;
    }

    constructor(
        address erc20,
        address marketing,
        uint256 safeStart,
        uint256 safeEnd,
        uint256 annualPercentageRate,
        uint256 totalAllocation,
        uint256 minDeposit,
        uint256 maxDeposit,
        bool cancellable
    ) {
        _erc20 = IERC20(erc20);
        _marketing = SYLVestingWallet(marketing);
        _safeStart = safeStart;
        _safeEnd = safeEnd;
        _annualPercentageRate = annualPercentageRate;
        _totalAllocation = totalAllocation;
        _minDeposit = minDeposit;
        _maxDeposit = maxDeposit;
        _cancellable = cancellable;
    }

    /**
     * @notice Deposit amount of ERC20.
     * @dev Needs approve of ERC20 allowance from user.
     */
    function deposit(uint256 depositAmount) external {
        if (!_cancellable) {
            require(_safeStart >= block.timestamp, "safe already started");
        }
        require(_safeEnd >= block.timestamp, "safe already matured");
        require(!_deposited[msg.sender], "already deposited");
        require(depositAmount >= _minDeposit && depositAmount <= _maxDeposit, "invalid deposit amount");
        require(depositAmount + _allocated <= _totalAllocation, "maximum allocation exceed");

        _erc20.transferFrom(msg.sender, address(this), depositAmount);

        _savings[msg.sender] = Saving(block.timestamp, depositAmount);
        _allocated += depositAmount;
        _deposited[msg.sender] = true;
        emit Deposit(msg.sender, depositAmount);
    }

    /**
     * @notice Withdraw amount and interest occurred.
     * @dev Needs approve of ERC20 allowance from marketing beneficiary.
     */
    function withdraw() external {
        uint256 amount = _savingAmount(msg.sender);
        uint256 interest = 0;

        require(amount != 0, "saving nonexists");
        require(matured() || _cancellable, "cannot withdraw");

        if (!matured()) {
            _allocated -= amount;
        } else {
            interest = _interest(msg.sender, _safeEnd);
            _marketing.release();
            _erc20.transferFrom(_marketing.beneficiary(), msg.sender, interest);
        }
        _erc20.transfer(msg.sender, amount);

        delete _savings[msg.sender];
        emit Withdraw(msg.sender, amount + interest);
    }

    /**
     * @dev Emergency withdraw function only for admin role
     */
    function withdrawAll() external onlyOwner {
        _erc20.transfer(msg.sender, _erc20.balanceOf(address(this)));
    }

    /**
     * @return start, end, annual percentage rate, total allocation, current allocation, minimum deposit, maximum deposit, isCancellable
     */
    function safeStatus() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](8);
        result[0] = _safeStart;
        result[1] = _safeEnd;
        result[2] = _annualPercentageRate;
        result[3] = _totalAllocation;
        result[4] = _allocated;
        result[5] = _minDeposit;
        result[6] = _maxDeposit;
        result[7] = _cancellable ? 1 : 0;
        return result;
    }

    /**
     * @return start, amount, accumulated amount, matured amount, isDeposited
     */
    function savingStatus(address addr) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](5);
        result[0] = _savingStart(addr);
        result[1] = _savingAmount(addr);
        result[2] = _savingAmount(addr) + _interest(addr, block.timestamp);
        if (matured()) {
            result[2] = _savingAmount(addr) + _interest(addr, _safeEnd);
        }
        result[3] = _savingAmount(addr) + _interest(addr, _safeEnd);
        result[4] = _deposited[addr] ? 1 : 0;
        return result;
    }

    function matured() public view returns (bool) {
        return block.timestamp >= _safeEnd;
    }

    function _interest(address addr, uint256 timestamp) private view returns (uint256) {
        if (!_deposited[addr] || timestamp <= _safeStart) {
            return 0;
        }
        uint256 interestPerSecond = _savingAmount(addr) * _annualPercentageRate / 100 / (360 * 86400);
        if (_savingStart(addr) <= _safeStart) {
            return interestPerSecond * (timestamp - _safeStart);
        }
        return interestPerSecond * (timestamp - _savingStart(addr));
    }

    function _savingStart(address addr) private view returns (uint256) {
        return _savings[addr].start;
    }

    function _savingAmount(address addr) private view returns (uint256) {
        return _savings[addr].amount;
    }
}