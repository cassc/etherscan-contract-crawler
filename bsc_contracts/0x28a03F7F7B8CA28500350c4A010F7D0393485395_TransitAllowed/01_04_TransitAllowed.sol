// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";

contract TransitAllowed is Ownable {

    constructor(address executor) Ownable(executor) {

    }

    event ChangeCallerAllowed(uint8[] flags, address[][] callers);
    event ChangeFunctionAllowed(address[] callers, bytes4[] functions, bool[] newAllowed);
    event ChangeRequireAllowed(bool oldRequireAllowed, bool newRequireAllowed);
    event ChangeRequireFunctionAllowed(address[] callers, bool[] newAllowed);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    mapping(uint8 => mapping(address => bool)) private _caller_allowed;
    mapping(address => mapping(bytes4 => bool)) private _function_allowed;
    bool private _requireAllowed;
    mapping(address => bool) private _requireFunctionAllowed;

    function requireAllowed() public view returns (bool) {
        return _requireAllowed;
    }

    function requireFunctionAllowed(address caller) public view returns (bool) {
        return _requireFunctionAllowed[caller];
    }

    function checkAllowed(uint8 flag, address caller, bytes4 fun) public view returns (bool) {
        if (!requireAllowed()) {
            return true;
        }
        bool callerAllowed = _caller_allowed[flag][caller];
        if (requireFunctionAllowed(caller)) {
            bool functionAllowed = _function_allowed[caller][fun];
            return callerAllowed && functionAllowed;
        }
        return callerAllowed;
    }

    function changeRequireAllowed() public onlyExecutor {
        bool oldRequireAllowed = _requireAllowed;
        _requireAllowed = !_requireAllowed;
        emit ChangeRequireAllowed(oldRequireAllowed, _requireAllowed);
    }

    function changeRequireFunctionAllowed(address[] calldata callers) public onlyExecutor {
        bool[] memory newAllowed = new bool[](callers.length);
        for (uint index; index < callers.length; index++) {
            bool oldRequireAllowed = _requireFunctionAllowed[callers[index]];
            _requireFunctionAllowed[callers[index]] = !oldRequireAllowed;
            newAllowed[index] = !oldRequireAllowed;
        }
        emit ChangeRequireFunctionAllowed(callers, newAllowed);
    }

    function changeCallerAllowed(uint8[] calldata flags, address[][] calldata callers) public onlyExecutor {
        for (uint index; index < flags.length; index++) {
            for (uint indexSecond; indexSecond < callers[index].length; indexSecond++) {
                _caller_allowed[flags[index]][callers[index][indexSecond]] = !_caller_allowed[flags[index]][callers[index][indexSecond]];
            }
        }
        emit ChangeCallerAllowed(flags, callers);
    }

    function changeFunctionAllowed(address[] calldata callers, bytes4[] calldata functions) public onlyExecutor {
        bool[] memory newAllowed = new bool[](callers.length);
        for (uint index; index < callers.length; index++) {
            _function_allowed[callers[index]][functions[index]] = !_function_allowed[callers[index]][functions[index]];
        }
        emit ChangeFunctionAllowed(callers, functions, newAllowed);
    }
    
    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for(uint index; index < tokens.length; index++) {
            uint amount;
            if(TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }

}