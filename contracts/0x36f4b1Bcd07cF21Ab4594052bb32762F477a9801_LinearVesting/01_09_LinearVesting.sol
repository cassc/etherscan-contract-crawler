// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/LinearVestingLibrary.sol";

contract LinearVesting is ReentrancyGuard, Ownable {    
    using SafeERC20 for IERC20;
    using LinearVestingLibrary for LinearVestingLibrary.Data;

    event Withdraw(address indexed sender, uint amount);
    event SetLockup(address _account, uint total);

    mapping(address => uint) public lockupAmountOf;
    mapping(address => uint) public vestedAmountOf;

    address immutable private token;
    LinearVestingLibrary.Data private vestingData;

    constructor(
        address _token,
        uint _cliffEndBlock,
        uint _vestingDurationBlocks
    ) {
        token = _token;
        vestingData.initialize(
            _cliffEndBlock,
            _vestingDurationBlocks
        );
    }

    function addLockup(address[] calldata _accounts, uint128[] calldata _amounts) external onlyOwner {
        require(_accounts.length == _amounts.length, "LinearVesting: LENGTH");
        for (uint i; i < _accounts.length; ++i) {
            lockupAmountOf[_accounts[i]] += _amounts[i];
            emit SetLockup(_accounts[i], lockupAmountOf[_accounts[i]]);
        }
    }

    function setLockup(address[] calldata _accounts, uint128[] calldata _totalAmounts) external onlyOwner {
        require(_accounts.length == _totalAmounts.length, "LinearVesting: LENGTH");
        for (uint i; i < _accounts.length; ++i) {
            lockupAmountOf[_accounts[i]] = _totalAmounts[i];
            emit SetLockup(_accounts[i], _totalAmounts[i]);
        }
    }

    /// @notice Withdrawals are allowed only if ownership was renounced (setLockup cannot be called, vesting recipients cannot be changed anymore)
    function withdraw() external nonReentrant {
        require(owner() == address(0), "LinearVesting: RENOUNCE_OWNERSHIP");
        uint unlocked = vestingData.availableInputAmount(
            lockupAmountOf[msg.sender], 
            vestedAmountOf[msg.sender]
        );
        require(unlocked > 0, "LinearVesting: ZERO");
        vestedAmountOf[msg.sender] += unlocked;
        IERC20(token).safeTransfer(msg.sender, unlocked);
        emit Withdraw(msg.sender, unlocked);
    }
 
    function unlockedAmountOf(address _account) external view returns (uint) {
        return vestingData.availableInputAmount(
            lockupAmountOf[_account], 
            vestedAmountOf[_account]
        );
    }
}