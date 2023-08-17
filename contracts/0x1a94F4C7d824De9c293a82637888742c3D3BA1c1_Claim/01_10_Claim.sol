// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Claim__Amount__Zero(uint256 num);

error Transfer__Err(uint256 num);

contract Claim is AccessControl {
    //contract manager address
    //will deposit and grant claimer role
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    //can calim funds after duration
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    IERC20 public constant sphri =
        IERC20(0x8A0cdfaB62eD35b836DC0633482798421C81b3Ec);

    uint256 public constant AMOUNT_ERR = 1;

    uint256 public constant TRANSFER_ERR = 2;

    uint256 public amountLocked;

    mapping(address => uint256) private _addressInfo;

    event UPDATE(address by, uint256 amount, uint256 currentAmount);

    event CLAIMED(address claimer, uint256 amount);

    event USER_ADDED(address[] user, uint256[] amount);

    constructor(address manager) {
        _grantRole(MANAGER_ROLE, manager);
    }

    function _addInvestor(address user, uint256 amount) internal {
        _addressInfo[user] = amount;
    }

    function addInvestor(
        address[] calldata user,
        uint256[] calldata amount
    ) external onlyRole(MANAGER_ROLE) {
        for (uint i = 0; i < user.length; ) {
            _addInvestor(user[i], amount[i]);
            _grantRole(CLAIMER_ROLE, user[i]);
            unchecked {
                i++;
            }
        }

        emit USER_ADDED(user, amount);
    }

    function addFunds(uint256 amount_) external onlyRole(MANAGER_ROLE) {
        bool success = sphri.transferFrom(_msgSender(), address(this), amount_);

        success ? _updateFunds(amount_) : revert();
    }

    function _updateFunds(uint256 amount) internal {
        uint256 amount_ = amountLocked;
        uint256 newAmountLocked = amount_ + amount;
        amountLocked = newAmountLocked;
        emit UPDATE(msg.sender, amount, newAmountLocked);
    }

    function _claimFunds() internal {
        uint256 amount_ = _addressInfo[msg.sender];
        if (amount_ > 0) {
            uint256 amount = amountLocked;
            require(sphri.balanceOf(address(this)) == amount, "balance issue");
            amountLocked = amount - amount_;
            sphri.transfer(msg.sender, amount_);
            _revokeRole(CLAIMER_ROLE, msg.sender);
            _addressInfo[msg.sender] = 0;
            emit CLAIMED(msg.sender, amount_);
        } else {
            revert Claim__Amount__Zero(AMOUNT_ERR);
        }
    }

    function claimFunds() external onlyRole(CLAIMER_ROLE) {
        _claimFunds();
    }

    function getAddressInfo(address user) external view returns (uint256) {
        return _addressInfo[user];
    }
}