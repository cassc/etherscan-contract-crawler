// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract DvdShareholderPoint {

    using SafeMath for uint256;

    event ShareholderPointIncreased(address indexed account, uint256 amount, uint256 totalShareholderPoint);
    event ShareholderPointDecreased(address indexed account, uint256 amount, uint256 totalShareholderPoint);

    /// @dev Our shareholder point tracker
    /// Shareholder point will determine how much token one account can use to farm SDVD
    /// This point can only be increased/decreased by LoC buy/sell function to prevent people trading DVD on exchange and don't pay their taxes
    mapping(address => uint256) private _shareholderPoints;
    uint256 private _totalShareholderPoint;

    /// @notice Get shareholder point of an account
    /// @param account address.
    function shareholderPointOf(address account) public view returns (uint256) {
        return _shareholderPoints[account];
    }

    /// @notice Get total shareholder points
    function totalShareholderPoint() public view returns (uint256) {
        return _totalShareholderPoint;
    }

    /// @notice Increase shareholder point
    /// @param amount The amount to increase.
    function _increaseShareholderPoint(address account, uint256 amount) internal {
        // If account is burn address then skip
        if (account != address(0)) {
            _totalShareholderPoint = _totalShareholderPoint.add(amount);
            _shareholderPoints[account] = _shareholderPoints[account].add(amount);

            emit ShareholderPointIncreased(account, amount, _shareholderPoints[account]);
        }
    }

    /// @notice Decrease shareholder point.
    /// @param amount The amount to decrease.
    function _decreaseShareholderPoint(address account, uint256 amount) internal {
        // If account is burn address then skip
        if (account != address(0)) {
            _totalShareholderPoint = _totalShareholderPoint.sub(amount);
            _shareholderPoints[account] = _shareholderPoints[account] > amount ? _shareholderPoints[account].sub(amount) : 0;

            emit ShareholderPointDecreased(account, amount, _shareholderPoints[account]);
        }
    }

}