// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract Placeholder {

    event Result(bool success, bytes data);

    fallback(bytes calldata data) external payable returns (bytes memory) {
        if (data.length > 32) {
            (address target, bytes memory _calldata) = abi.decode(data, (address, bytes));
            (bool success, bytes memory returndata) = target.call{value: msg.value}(_calldata);
            emit Result(success, returndata);
        } else {
            return abi.encode(address(this));
        }
        return '';
    }
}