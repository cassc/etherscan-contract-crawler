// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract ERC20Minter is ERC20 {
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
        MintAction
    }

    struct ActionInfo {
        ActionType actionType;
        bytes actionData;
        uint256 validatorCnt;
        uint256 readCnt;
    }

    struct MintAction {
        address receiverAddr;
        uint256 amount;
    }

    event TokenMinted(address indexed receiverAddr, uint256 amount);
    event TokenBurned(
        address indexed senderAddr,
        string walletAddr,
        uint256 amount
    );
    event ActionFailure(uint256 actionId);

    constructor(
        address[] memory validators,
        uint16 threshold,
        string memory assetName,
        string memory assetUnit
    ) ERC20(assetName, assetUnit) {
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

    function validateMint(
        uint128 actionId,
        address receiverAddr,
        uint256 amount
    ) external {
        bytes memory actionData = abi.encode(MintAction(receiverAddr, amount));
        ValidationRes res = validateAction(
            actionId,
            ActionType.MintAction,
            actionData
        );
        if (res == ValidationRes.Execute) {
            mint(receiverAddr, amount);
        }
    }

    function mint(address receiverAddr, uint256 amount) private {
        _mint(receiverAddr, amount);

        emit TokenMinted(receiverAddr, amount);
    }

    function burn(uint256 amount, string calldata walletAddr) external {
        _burn(msg.sender, amount);

        emit TokenBurned(msg.sender, walletAddr, amount);
    }
}