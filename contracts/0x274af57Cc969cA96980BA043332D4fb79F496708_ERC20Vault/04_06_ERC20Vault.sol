// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "./libraries/TransferHelper.sol";

contract ERC20Vault is ReentrancyGuard {
    using BytesLib for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;

    address _token;

    uint256 public erc20Balance;
    uint256 public usdcBalance;

    uint256 private _threshold;

    EnumerableSet.AddressSet private _validators;
    mapping(uint128 => ActionInfo) private _actions;
    mapping(uint128 => mapping(address => uint8)) private _actionValidators;

    enum ValidationRes {
        Execute,
        Noop
    }

    enum ActionType {
        // Bridge actions
        ReleaseERC20Action,
        ReleaseUSDCAction
    }

    struct ActionInfo {
        ActionType actionType;
        bytes actionData;
        uint256 validatorCnt;
        uint256 readCnt;
    }

    struct ReleaseERC20Action {
        address erc20Addr;
        uint256 amount;
    }

    struct ReleaseUSDCAction {
        address erc20Addr;
        uint256 amount;
    }

    event LockERC20(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseERC20(address indexed erc20Addr, uint256 amount);
    event LockUSDC(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseUSDC(address indexed erc20Addr, uint256 amount);
    event ActionFailure(uint256 actionId);

    constructor(address[] memory validators, uint16 threshold, address token) {
        require(validators.length > 0, "Validators must not be empty!");
        require(
            threshold > 0 && threshold <= validators.length,
            "Invalid threshold!"
        );

        for (uint256 i = 0; i < validators.length; i++) {
            _validators.add(validators[i]);
        }

        _threshold = threshold;
        _token = token;
    }

    function validateAction(
        uint128 actionId,
        ActionType actionType,
        bytes memory actionData
    ) private returns (ValidationRes) {
        require(_validators.contains(msg.sender), "Not a validator!");

        if (_actions[actionId].validatorCnt == 0) {
            _actions[actionId] = ActionInfo(actionType, actionData, 1, 1);
        } else {
            require(
                _actionValidators[actionId][msg.sender] < 2,
                "Duplicate Validator!"
            );

            _actions[actionId].readCnt += 1;
            require(
                _actions[actionId].actionType == actionType,
                "Action Mismatch"
            );
            require(
                _actions[actionId].actionData.equal(actionData),
                "Action Mismatch"
            );
            _actions[actionId].validatorCnt += 1;
        }

        _actionValidators[actionId][msg.sender] = 2;

        ValidationRes res = ValidationRes.Noop;
        if (_actions[actionId].validatorCnt == _threshold) {
            res = ValidationRes.Execute;
        }

        if (_actions[actionId].readCnt == _validators.length()) {
            delete _actions[actionId];
            if (_actions[actionId].validatorCnt < _threshold) {
                emit ActionFailure(actionId);
            }
        }

        return res;
    }

    modifier checkLockERC20() {
        require(msg.value > 10 ** 12, "Sending amount is too small!");
        _;
    }

    function lockERC20(
        string calldata destNetwork,
        string calldata walletAddr
    ) external payable checkLockERC20 {
        erc20Balance += msg.value;

        emit LockERC20(msg.sender, destNetwork, walletAddr, msg.value);
    }

    modifier checkReleaseERC20(uint256 amount) {
        require(erc20Balance > 0, "Balance is zero!");
        require(erc20Balance >= amount, "Balance is not enough to withdraw!");
        _;
    }

    function validateReleaseERC20(
        uint128 actionId,
        address erc20Addr,
        uint256 amount
    ) external checkReleaseERC20(amount) {
        bytes memory actionData = abi.encode(
            ReleaseERC20Action(erc20Addr, amount)
        );
        ValidationRes res = validateAction(
            actionId,
            ActionType.ReleaseERC20Action,
            actionData
        );
        if (res == ValidationRes.Execute) {
            releaseERC20(erc20Addr, amount);
        }
    }

    function releaseERC20(
        address erc20Addr,
        uint256 amount
    ) private nonReentrant {
        TransferHelper.safeTransferETH(erc20Addr, amount);

        erc20Balance -= amount;

        emit ReleaseERC20(msg.sender, amount);
    }

    modifier checkLockUSDC(uint256 amount) {
        require(
            IERC20(_token).allowance(msg.sender, address(this)) >= amount,
            "Error low allowance!"
        );
        _;
    }

    function lockUSDC(
        uint256 amount,
        string calldata destNetwork,
        string calldata walletAddr
    ) external checkLockUSDC(amount) {
        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            amount
        );

        usdcBalance += amount;

        emit LockUSDC(msg.sender, destNetwork, walletAddr, amount);
    }

    modifier checkReleaseUSDC(uint256 amount) {
        require(usdcBalance > 0, "Balance is zero!");
        require(usdcBalance >= amount, "Balance is not enough to withdraw!");
        _;
    }

    function validateReleaseUSDC(
        uint128 actionId,
        address erc20Addr,
        uint256 amount
    ) external checkReleaseUSDC(amount) {
        bytes memory actionData = abi.encode(
            ReleaseUSDCAction(erc20Addr, amount)
        );
        ValidationRes res = validateAction(
            actionId,
            ActionType.ReleaseUSDCAction,
            actionData
        );
        if (res == ValidationRes.Execute) {
            releaseUSDC(erc20Addr, amount);
        }
    }

    function releaseUSDC(
        address erc20Addr,
        uint256 amount
    ) private nonReentrant {
        TransferHelper.safeTransfer(_token, erc20Addr, amount);

        usdcBalance -= amount;

        emit ReleaseUSDC(erc20Addr, amount);
    }
}