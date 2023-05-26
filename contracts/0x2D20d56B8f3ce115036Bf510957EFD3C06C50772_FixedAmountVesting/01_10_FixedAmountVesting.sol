// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./libraries/VestingLibrary.sol";

contract FixedAmountVesting is ReentrancyGuard, Ownable {
    
    using SafeCast for uint;
    using SafeERC20 for IERC20;
    using VestingLibrary for VestingLibrary.Data;

    event Withdraw(address indexed sender, uint amount);
    event SetLockup(address _account, uint total);

    uint constant private BP = 10_000;

    mapping(address => uint) public vestedAmountOf;

    IERC20 immutable private token;
    VestingLibrary.Data private vestingData;
    mapping(address => uint) private _lockupAmountOf;
    uint64 cliffPercentageInBP;
    uint64 vestingPercentageInBP;

    constructor(
        address _token,
        uint64 _cliffEnd,
        uint32 _vestingInterval,
        uint64 _cliffPercentageInBP,
        uint64 _vestingPercentageInBP
    ) {
        token = IERC20(_token);
        cliffPercentageInBP = _cliffPercentageInBP;
        vestingPercentageInBP = _vestingPercentageInBP;
        vestingData.initialize(
            _cliffEnd,
            _vestingInterval
        );
    }

    function addLockup(address[] calldata _accounts, uint[] calldata _totalAmounts) external onlyOwner {
        require(_accounts.length == _totalAmounts.length, "FixedAmountVesting: LENGTH");
        for (uint i; i < _accounts.length; ++i) {
            _lockupAmountOf[_accounts[i]] += _totalAmounts[i];
            emit SetLockup(_accounts[i], _lockupAmountOf[_accounts[i]]);
        }
    }

    function setLockup(address[] calldata _accounts, uint[] calldata _totalAmounts) external onlyOwner {
        require(_accounts.length == _totalAmounts.length, "FixedAmountVesting: LENGTH");
        for (uint i; i < _accounts.length; ++i) {
            _lockupAmountOf[_accounts[i]] = _totalAmounts[i];
            emit SetLockup(_accounts[i], _totalAmounts[i]);
        }
    }

    /// @notice Withdrawals are allowed only if ownership was renounced (setLockup cannot be called, vesting recipients cannot be changed anymore)
    function withdraw() external nonReentrant {
        require(owner() == address(0), "FixedAmountVesting: RENOUNCE_OWNERSHIP");
        uint totalAmount = _lockupAmountOf[msg.sender];
        uint unlocked = vestingData.availableInputAmount(
            totalAmount, 
            vestedAmountOf[msg.sender], 
            totalAmount * vestingPercentageInBP / BP, 
            totalAmount * cliffPercentageInBP / BP
        );
        require(unlocked > 0, "FixedAmountVesting: ZERO");
        vestedAmountOf[msg.sender] += unlocked;
        IERC20(token).safeTransfer(msg.sender, unlocked);
        emit Withdraw(msg.sender, unlocked);
    }

    function lockupAmountOf(address _account) external view returns (uint totalAmount) {
        totalAmount = _lockupAmountOf[_account];
    }
 
    function unlockedAmountOf(address _account) external view returns (uint) {
        uint totalAmount = _lockupAmountOf[_account];
        return vestingData.availableInputAmount(
            totalAmount, 
            vestedAmountOf[_account], 
            totalAmount * vestingPercentageInBP / BP, 
            totalAmount * cliffPercentageInBP / BP
        );
    }
}