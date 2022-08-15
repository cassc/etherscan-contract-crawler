pragma solidity >=0.5.0;

interface IProxyTransaction {
    function forwardCall(address target, uint256 value, bytes calldata callData) external payable returns (bool success, bytes memory returnData);
}