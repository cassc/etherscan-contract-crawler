// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/BankConfig.sol";
import "./interfaces/GoblinConfig.sol";


interface InterestModel {
    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);
}

contract TripleSlopeModel {
    using SafeMath for uint256;

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint debt, uint floating) external pure returns (uint) {
        uint total = debt.add(floating);
        uint utilization = total == 0 ? 0 : debt.mul(100e18).div(total);
        if (utilization < 80e18) {
            // Less than 80% utilization - 0%-20% APY
            return utilization.mul(20e16).div(80e18) / 365 days;
        } else if (utilization < 90e18) {
            // Between 80% and 90% - 20% APY
            return uint(20e16) / 365 days;
        } else if (utilization < 100e18) {
            // Between 90% and 100% - 20%-200% APY
            return (20e16 + utilization.sub(90e18).mul(180e16).div(10e18)) / 365 days;
        } else {
            // Not possible, but just in case - 200% APY
            return uint(200e16) / 365 days;
        }
    }
}

contract ConfigurableInterestBankConfig is BankConfig, Ownable {
    /// The minimum ETH debt size per position.
    uint256 public minDebtSize;
    /// The portion of interests allocated to the reserve pool.
    uint256 public getReservePoolBps;
    /// The reward for successfully killing a position.
    uint256 public getKillBps;
    /// Mapping for goblin address to its configuration.
    mapping (address => GoblinConfig) public goblins;
    /// Interest rate model
    InterestModel public interestModel;

    constructor(
        uint256 _minDebtSize,
        uint256 _reservePoolBps,
        uint256 _killBps,
        InterestModel _interestModel
    ) public {
        setParams(_minDebtSize, _reservePoolBps, _killBps, _interestModel);
    }

    /// @dev Set all the basic parameters. Must only be called by the owner.
    /// @param _minDebtSize The new minimum debt size value.
    /// @param _reservePoolBps The new interests allocated to the reserve pool value.
    /// @param _killBps The new reward for killing a position value.
    /// @param _interestModel The new interest rate model contract.
    function setParams(
        uint256 _minDebtSize,
        uint256 _reservePoolBps,
        uint256 _killBps,
        InterestModel _interestModel
    ) public onlyOwner {
        minDebtSize = _minDebtSize;
        getReservePoolBps = _reservePoolBps;
        getKillBps = _killBps;
        interestModel = _interestModel;
    }

    /// @dev Set the configuration for the given goblins. Must only be called by the owner.
    function setGoblins(address[] calldata addrs, GoblinConfig[] calldata configs) external onlyOwner {
        require(addrs.length == configs.length, "bad length");
        for (uint256 idx = 0; idx < addrs.length; idx++) {
            goblins[addrs[idx]] = configs[idx];
        }
    }

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256) {
        return interestModel.getInterestRate(debt, floating);
    }

    /// @dev Return whether the given address is a goblin.
    function isGoblin(address goblin) external view returns (bool) {
        return address(goblins[goblin]) != address(0);
    }

    /// @dev Return whether the given goblin accepts more debt. Revert on non-goblin.
    function acceptDebt(address goblin) external view returns (bool) {
        return goblins[goblin].acceptDebt(goblin);
    }

    /// @dev Return the work factor for the goblin + ETH debt, using 1e4 as denom. Revert on non-goblin.
    function workFactor(address goblin, uint256 debt) external view returns (uint256) {
        return goblins[goblin].workFactor(goblin, debt);
    }

    /// @dev Return the kill factor for the goblin + ETH debt, using 1e4 as denom. Revert on non-goblin.
    function killFactor(address goblin, uint256 debt) external view returns (uint256) {
        return goblins[goblin].killFactor(goblin, debt);
    }
}