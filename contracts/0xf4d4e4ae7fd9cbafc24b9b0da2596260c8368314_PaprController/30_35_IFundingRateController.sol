// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IFundingRateController {
    /// @notice emitted when target is updated
    /// @param newTarget the new target value
    event UpdateTarget(uint256 newTarget);

    event SetFundingPeriod(uint256 fundingPeriod);

    error AlreadyInitialized();
    error FundingPeriodTooShort();
    error FundingPeriodTooLong();

    /// @notice Updates target and returns new target
    /// @dev if block.timestamp == lastUpdated() then just returns target()
    /// @return Target the new target value
    function updateTarget() external returns (uint256);

    /// @notice The timestamp at which target was last updated
    /// @return lastUpdated the timestamp (in seconds) at which target was last updated
    function lastUpdated() external view returns (uint256);

    /// @notice The target value of one whole unit of papr in underlying units.
    /// @dev Target represents the 0% funding rate value. If mark() is equal to this
    /// value, then funding rates are 0 and newTarget() will equal target().
    /// @return target The value of one whole unit of papr in underlying units.
    /// Example: if papr has 18 decimals and underlying 6 decimals, then
    ///  target = 1e6 means 1e18 papr is worth 1e6 underlying, according to target
    function target() external view returns (uint256);

    /// @notice The value of new value of target() if updateTarget() were called right now
    /// @dev If mark() > target(), newTarget() will be less than target(), positive funding/negative interest
    /// @dev If mark() < target(), newTarget() will be greater than target(), negative funding/positive interest
    /// @return newTarget The up to date target value for this block
    function newTarget() external view returns (uint256);

    /// @notice The market value of a whole unit of papr in underlying units
    /// @return mark market papr price, quoted in underlying
    function mark() external view returns (uint256);

    /// @notice The papr token, the value of which is intended to
    /// reflect in-kind funding payments via target() changing in value
    /// @return papr the ERC20 token (address)
    function papr() external view returns (ERC20);

    /// @notice The underlying token that is used to quote the value of papr
    /// @return underlying the ERC20 token (address)
    function underlying() external view returns (ERC20);

    /// @notice The period over which funding is paid
    /// @dev a shorter funding period means volatility has a greater impact
    /// on funding => target, longer period means the inverse
    /// @return fundingPeriod in seconds over which funding is paid
    function fundingPeriod() external view returns (uint256);
}