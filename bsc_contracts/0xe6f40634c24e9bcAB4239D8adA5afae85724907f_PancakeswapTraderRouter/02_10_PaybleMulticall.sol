// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract PaybleMulticall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function paybleMulticall(bytes[] calldata data) external payable virtual returns (bytes[] memory results) {
        uint256 finalBalance = address(this).balance - msg.value + calculateFee(msg.value);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        require(address(this).balance>=finalBalance,"PaybleMulticall: Bad balance after multicall transaction");
        return results;
    }

    function calculateFee(uint256 tokenAmount) public view virtual returns (uint256);
}