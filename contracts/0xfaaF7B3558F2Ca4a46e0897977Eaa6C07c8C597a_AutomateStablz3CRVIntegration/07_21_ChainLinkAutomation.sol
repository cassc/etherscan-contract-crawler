//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/// @title Generic ChainLink automation contract
abstract contract ChainLinkAutomation is Ownable, AutomationCompatibleInterface {

    address public immutable keeperRegistry;
    uint public lastPerformedAt;
    uint public interval;

    event IntervalUpdated(uint interval);

    modifier onlyKeeperRegistry() {
        require(_msgSender() == keeperRegistry, "ChainLinkAutomation: Only the keeper registry can call this function");
        _;
    }

    /// @param _keeperRegistry Chainlink keeper registry address
    constructor(address _keeperRegistry) {
        require(_keeperRegistry != address(0), "ChainLinkAutomation: _keeperRegistry cannot be the zero address");
        keeperRegistry = _keeperRegistry;
    }

    /// @notice Set the interval between when checkUpkeep should run its internal logic, 0 will mean it will run every block
    /// @param _interval Interval in seconds
    function setInterval(uint _interval) external onlyOwner {
        interval = _interval;
        emit IntervalUpdated(_interval);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(bytes calldata _checkData) external onlyKeeperRegistry returns (bool upkeepNeeded, bytes memory performData) {
        if (interval == 0 || block.timestamp >= lastPerformedAt + interval) {
            return _checkUpkeep(_checkData);
        }
        return (upkeepNeeded, performData);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata _performData) external onlyKeeperRegistry {
        lastPerformedAt = block.timestamp;
        _performUpkeep(_performData);
    }

    function _checkUpkeep(bytes calldata _checkData) internal virtual returns (bool upkeepNeeded, bytes memory performData);

    function _performUpkeep(bytes calldata _performData) internal virtual;
}