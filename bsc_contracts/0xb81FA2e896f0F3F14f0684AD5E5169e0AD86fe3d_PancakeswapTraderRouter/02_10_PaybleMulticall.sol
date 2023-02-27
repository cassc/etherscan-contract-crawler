// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract PaybleMulticall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function paybleMulticall(bytes[] calldata data) external payable virtual returns (bytes[] memory results) {
        uint256 finalBalance = address(this).balance -msg.value + (_limitGasPrice() < tx.gasprice
            ? 0
            : calculateFee(msg.value));

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        payable(msg.sender).transfer(address(this).balance - finalBalance);
        require(address(this).balance >= finalBalance, "PaybleMulticall: Bad balance after multicall transaction");
        return results;
    }

    function calculateFee(uint256 tokenAmount) public view virtual returns (uint256);

    function _limitGasPrice() internal view virtual returns (uint256);
}