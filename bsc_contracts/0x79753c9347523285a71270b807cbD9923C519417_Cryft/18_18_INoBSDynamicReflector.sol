// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";

interface INoBSDynamicReflector is IBaseDistributor {

    function getRewardType() external view returns (string memory);
    function getUnpaidEarnings(address shareholder) external view returns (uint256);
    function process() external;
    function updateGasForProcessing(uint256 _gas) external;

}