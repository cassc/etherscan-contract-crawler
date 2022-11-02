// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ETHBaseStrategy.sol";

/// @title ETHBaseClaimableStrategy
/// @author Bank of Chain Protocol Inc
abstract contract ETHBaseClaimableStrategy is ETHBaseStrategy {

    /// @notice Collect the rewards from 3rd protocol
    /// @return _claimIsWorth The boolean value to check the claim action is worth or not
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        virtual
        returns (
            bool _claimIsWorth,
            address[] memory _rewardsTokens,
            uint256[] memory _claimAmounts
        );

    /// @notice Swap from the reward tokens to wanted tokens 
    /// @return _wantTokens The address list of the wanted token
    /// @return _wantAmounts The amount list of the wanted token
    function swapRewardsToWants() internal virtual returns(address[] memory _wantTokens,uint256[] memory _wantAmounts);

    /// @inheritdoc ETHBaseStrategy
    function harvest() public virtual override returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts){
        // sell reward token
        (bool _claimIsWorth, address[] memory __rewardsTokens,uint256[] memory __claimAmounts ) = claimRewards();
        _rewardsTokens = __rewardsTokens;
        _claimAmounts = __claimAmounts;
        address[] memory _wantTokens;
        uint256[] memory _wantAmounts;
        if (_claimIsWorth) {
            (_wantTokens,_wantAmounts) = swapRewardsToWants();

            reInvest();
        }

        vault.report(_rewardsTokens,_claimAmounts);

        emit SwapRewardsToWants(address(this),_rewardsTokens, _claimAmounts, _wantTokens,_wantAmounts);
    }

    /// @notice Reinvest in 3rd protocol
    function reInvest() internal {
        address[] memory _wantsCopy = wants;
        address[] memory _assets = new address[](_wantsCopy.length);
        uint256[] memory _amounts = new uint256[](_wantsCopy.length);
        uint256 _totalBalance = 0;
        for (uint8 i = 0; i < _wantsCopy.length; i++) {
            address _want = _wantsCopy[i];
            uint256 _tokenBalance = balanceOfToken(_want);
            _assets[i] = _want;
            _amounts[i] = _tokenBalance;
            _totalBalance += _tokenBalance;
        }
        if (_totalBalance > 0) {
            depositTo3rdPool(_assets, _amounts);
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function repay(
        uint256 _repayShares,
        uint256 _totalShares,
        uint256 _outputCode
    )
        public
        virtual
        override
        onlyVault
        returns (address[] memory _assets, uint256[] memory _amounts)
    {
        // if withdraw all need claim rewards
        if (_repayShares == _totalShares) {
            harvest();
        }
        return super.repay(_repayShares, _totalShares, _outputCode);
    }
}