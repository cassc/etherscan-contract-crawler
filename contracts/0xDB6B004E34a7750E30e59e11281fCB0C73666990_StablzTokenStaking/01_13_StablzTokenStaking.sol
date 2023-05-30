//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "contracts/staking/common/StablzStaking.sol";
import "contracts/token/OperatingSystem.sol";

/// @title Stablz staking
contract StablzTokenStaking is StablzStaking {

    OperatingSystem public immutable receipt;

    /// @param _stablz Stablz token
    /// @param _operatingSystem Stablz governance token
    /// @param _totalRewards Total rewards allocated for the contract
    /// @param _minimumDeposit Minimum deposit amount
    /// @param _apr1Month APR for 1 month to 1 d.p. e.g. 80 = 8%
    /// @param _apr3Month APR for 3 month to 1 d.p. e.g. 120 = 12%
    /// @param _apr6Month APR for 6 month to 1 d.p. e.g. 200 = 20%
    /// @param _apr12Month APR for 12 month to 1 d.p. e.g. 365 = 36.5%
    constructor(
        address _stablz,
        address _operatingSystem,
        uint _totalRewards,
        uint _minimumDeposit,
        uint _apr1Month,
        uint _apr3Month,
        uint _apr6Month,
        uint _apr12Month
    ) StablzStaking(_stablz, _stablz, _totalRewards, _minimumDeposit, _apr1Month, _apr3Month, _apr6Month, _apr12Month) {
        require(_operatingSystem != address(0), "StablzTokenStaking: _operatingSystem cannot be the zero address");
        receipt = OperatingSystem(_operatingSystem);
    }

    /// @dev Calculate the rewards earned at the end of the lockup period for a given amount of LP
    function _calculateReward(uint _amount, uint _lockUpPeriodType) internal override view returns (uint reward) {
        uint period = getLockUpPeriod(_lockUpPeriodType);
        uint apr = getAPR(_lockUpPeriodType);
        return _amount * apr * period / (365 days * APR_DENOMINATOR);
    }

    function _giveReceipt(address _user, uint _amount) internal override {
        receipt.mint(_user, _amount);
    }

    function _takeReceipt(address _user, uint _amount) internal override {
        receipt.burnFrom(_user, _amount);
    }

}