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
        ReleaseTokenAction
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

    struct ReleaseTokenAction {
        address erc20Addr;
        address token;
        uint256 amount;
    }

    event Received(address, uint256);

    event LockERC20(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseERC20(address indexed erc20Addr, uint256 amount);
    event LockToken(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        address token,
        uint256 amount
    );
    event ReleaseToken(
        address indexed erc20Addr,
        address indexed token,
        uint256 amount
    );
    event ActionFailure(uint256 actionId);

    constructor(address[] memory validators, uint16 threshold) {
        require(validators.length > 0, "Validators must not be empty!");
        require(
            threshold > 0 && threshold <= validators.length,
            "Invalid threshold!"
        );

        for (uint256 i = 0; i < validators.length; i++) {
            _validators.add(validators[i]);
        }

        _threshold = threshold;
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
        require(msg.value > 0, "Amount is zero!");
        _;
    }

    function lockERC20(
        string calldata destNetwork,
        string calldata walletAddr
    ) external payable checkLockERC20 {
        emit LockERC20(msg.sender, destNetwork, walletAddr, msg.value);
    }

    modifier checkReleaseERC20(uint256 amount) {
        require(amount > 0, "Amount is zero!");
        require(address(this).balance > 0, "Balance is zero!");
        require(
            address(this).balance >= amount,
            "Balance is not enough to withdraw!"
        );
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

        emit ReleaseERC20(erc20Addr, amount);
    }

    modifier checkLockToken(address token, uint256 amount) {
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            "Error low allowance!"
        );
        _;
    }

    function lockToken(
        address token,
        uint256 amount,
        string calldata destNetwork,
        string calldata walletAddr
    ) external checkLockToken(token, amount) {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );

        emit LockToken(msg.sender, destNetwork, walletAddr, token, amount);
    }

    modifier checkReleaseToken(address token, uint256 amount) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Amount is zero!");
        require(balance > 0, "Balance is zero!");
        require(balance >= amount, "Balance is not enough to withdraw!");
        _;
    }

    function validateReleaseToken(
        uint128 actionId,
        address erc20Addr,
        address token,
        uint256 amount
    ) external checkReleaseToken(token, amount) {
        bytes memory actionData = abi.encode(
            ReleaseTokenAction(erc20Addr, token, amount)
        );
        ValidationRes res = validateAction(
            actionId,
            ActionType.ReleaseTokenAction,
            actionData
        );
        if (res == ValidationRes.Execute) {
            releaseToken(erc20Addr, token, amount);
        }
    }

    function releaseToken(
        address erc20Addr,
        address token,
        uint256 amount
    ) private nonReentrant {
        TransferHelper.safeTransfer(token, erc20Addr, amount);

        emit ReleaseToken(erc20Addr, token, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}