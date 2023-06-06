pragma solidity ^0.8.4;
// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

interface IMonitor is AutomationCompatibleInterface {
    // function getPoolTokensQuantity() external view returns (uint256, uint256);
    // function isPoolHealthy() external view returns (bool, bool);
    // function setMinBalanceProportion(uint256 _minBalanceProportion) external;
    // function setMaxOwnershipProportion(
    //     uint256 _maxOwnershipProportion
    // ) external;
    // function setMinIdleEthForAction(uint256 _minIdleEthForAction) external;
}