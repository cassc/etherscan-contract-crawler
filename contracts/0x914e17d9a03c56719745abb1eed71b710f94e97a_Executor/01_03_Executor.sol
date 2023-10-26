// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Executor is Initializable {
    address private _staker;

    uint256[50] private _gap;

    function initialize(address staker_) public initializer {
        require(staker_ != address(0), "!staker");
        _staker = staker_;
    }

    constructor() {
        _disableInitializers();
    }

    /// @dev Function for execute write methods of Staker contract
    /// @param call function calldata, calldata should be without user address in tail
    /// @notice user address will be added automatically to calldata tail
    function execute(
        bytes memory call
    ) public returns (uint256 blockNumber, bytes memory returnData) {
        blockNumber = block.number;

        bytes memory finalCalldata = abi.encodePacked(
            call,
            bytes32(uint256(uint160(msg.sender)))
        );

        (bool success, bytes memory result) = _staker.call(finalCalldata);
        if (success == false) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        returnData = result;
    }
}