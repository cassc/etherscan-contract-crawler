// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";
import "IBundle.sol";
import "IPolicy.sol";

interface IRiskpool is IComponent {

    event LogRiskpoolCreated (address riskpoolAddress);
    event LogRiskpoolProposed (uint256 id);
    event LogRiskpoolApproved (uint256 id);
    event LogRiskpoolDeclined (uint256 id);

    event LogRiskpoolBundleCreated(uint256 bundleId, uint256 amount);
    event LogRiskpoolBundleMatchesPolicy(uint256 bundleId, bool isMatching);
    event LogRiskpoolCollateralLocked(bytes32 processId, uint256 collateralAmount, bool isSecured);

    event LogRiskpoolPremiumProcessed(bytes32 processId, uint256 amount);
    event LogRiskpoolPayoutProcessed(bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralReleased(bytes32 processId, uint256 collateralAmount);


    function createBundle(bytes memory filter, uint256 initialAmount) external returns(uint256 bundleId);
    function fundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);
    function defundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);

    function lockBundle(uint256 bundleId) external;
    function unlockBundle(uint256 bundleId) external;
    function closeBundle(uint256 bundleId) external;
    function burnBundle(uint256 bundleId) external;

    function collateralizePolicy(bytes32 processId, uint256 collateralAmount) external returns(bool isSecured);
    function processPolicyPremium(bytes32 processId, uint256 amount) external;
    function processPolicyPayout(bytes32 processId, uint256 amount) external;
    function releasePolicy(bytes32 processId) external;

    function getCollateralizationLevel() external view returns (uint256);
    function getFullCollateralizationLevel() external view returns (uint256);

    function bundleMatchesApplication(
        IBundle.Bundle memory bundle, 
        IPolicy.Application memory application
    ) 
        external view returns(bool isMatching);   
    
    function getFilterDataStructure() external view returns(string memory);

    function bundles() external view returns(uint256);
    function getBundle(uint256 idx) external view returns(IBundle.Bundle memory);

    function activeBundles() external view returns(uint256);
    function getActiveBundleId(uint256 idx) external view returns(uint256 bundleId);

    function getWallet() external view returns(address);
    function getErc20Token() external view returns(address);

    function getSumOfSumInsuredCap() external view returns (uint256);
    function getCapital() external view returns(uint256);
    function getTotalValueLocked() external view returns(uint256); 
    function getCapacity() external view returns(uint256); 
    function getBalance() external view returns(uint256); 

    function setMaximumNumberOfActiveBundles(uint256 maximumNumberOfActiveBundles) external; 
    function getMaximumNumberOfActiveBundles() external view returns(uint256 maximumNumberOfActiveBundles);
}