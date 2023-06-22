// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC20.sol";

/**
 * @dev ClaimConfg contract interface. See {ClaimConfig}.
 * @author Alan
 */
interface IClaimConfig {
    function allowPartialClaim() external view returns (bool);
    function auditor() external view returns (address);
    function governance() external view returns (address);
    function treasury() external view returns (address);
    function protocolFactory() external view returns (address);
    function maxClaimDecisionWindow() external view returns (uint256);
    function baseClaimFee() external view returns (uint256);
    function forceClaimFee() external view returns (uint256);
    function feeMultiplier() external view returns (uint256);
    function feeCurrency() external view returns (IERC20);
    function getFileClaimWindow(address _protocol) external view returns (uint256);
    
    // @dev Only callable by governance
    function setMaxClaimDecisionWindow(uint256 _newTimeWindow) external;
    function setGovernance(address _governance) external;
    function setTreasury(address _treasury) external;
    function setAuditor(address _auditor) external;
    function setPartialClaimStatus(bool _allowPartialClaim) external;
    function setFeeAndCurrency(uint256 _baseClaimFee, uint256 _forceClaimFee, address _currency) external;
    function setFeeMultiplier(uint256 _multiplier) external;

    function isAuditorVoting() external view returns (bool);
    function getProtocolClaimFee(address _protocol) external view returns (uint256);
}