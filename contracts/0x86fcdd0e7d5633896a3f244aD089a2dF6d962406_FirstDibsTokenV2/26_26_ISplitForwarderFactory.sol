//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ISplitForwarderFactory {
    function splitForwarder() external view returns (address);
    function splitPool() external view returns (address);
    function getSplitForwarderAddress(bytes32 _merkleRoot) external view returns(address);
    function createSplitForwarder(bytes32 _merkleRoot) external returns (address _clone);
}