//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./interfaces/ICheapSwapFactory.sol";

contract CheapSwapTargetAddress {
    address public owner;
    address public target;
    uint256 public value;
    bytes public data;

    constructor(
        address _owner,
        address _target,
        uint256 _value,
        bytes memory _data
    ) {
        owner = _owner;
        target = _target;
        value = _value;
        data = _data;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    receive() external payable {
        (bool success, ) = target.call{value: value}(data);
        require(success, "CheapSwapTargetAddress: call error");
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function call(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external payable {
        require(msg.sender == owner, "CheapSwapTargetAddress: not owner");
        (bool success, ) = _target.call{value: _value}(_data);
        require(success, "CheapSwapTargetAddress: call error");
    }

    function setData(uint256 _value, bytes calldata _data) external {
        require(msg.sender == owner, "CheapSwapTargetAddress: not owner");
        value = _value;
        data = _data;
    }
}