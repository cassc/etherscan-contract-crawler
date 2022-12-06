// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20ElasticSupply.sol";


/**
* @title IERC20Indexed
* @author Geminon Protocol
* @dev Interface for the ERC20Indexed contract
*/
interface IERC20Indexed is IERC20ElasticSupply {
    
    function setIndexBeacon(address beacon) external;
    function requestMaxVariationChange(uint16 newValue) external;
    function applyMaxVariationChange() external;

    function updateTarget() external;
    
    function getOrUpdatePegValue() external returns(uint256);
    function getPegValue() external view returns(uint256);
}