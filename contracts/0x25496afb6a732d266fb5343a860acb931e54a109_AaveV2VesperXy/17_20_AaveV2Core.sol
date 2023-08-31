// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "vesper-pools/contracts/Errors.sol";
import "../../../interfaces/aave/IAave.sol";

/// @title This contract provide core operations for Aave
abstract contract AaveV2Core {
    //solhint-disable-next-line const-name-snakecase
    StakedAave public constant stkAAVE = StakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    AaveLendingPool public immutable aaveLendingPool;
    AaveProtocolDataProvider public aaveProtocolDataProvider;
    AaveIncentivesController public immutable aaveIncentivesController;
    PoolAddressesProvider internal immutable aaveAddressesProvider_;

    AToken internal immutable aToken;
    bytes32 private constant AAVE_PROVIDER_ID = 0x0100000000000000000000000000000000000000000000000000000000000000;

    constructor(address _receiptToken) {
        require(_receiptToken != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        aToken = AToken(_receiptToken);
        // If there is no AAVE incentive then below call will fail
        try AToken(_receiptToken).getIncentivesController() returns (address _aaveIncentivesController) {
            aaveIncentivesController = AaveIncentivesController(_aaveIncentivesController);
        } catch {} //solhint-disable no-empty-blocks
        aaveAddressesProvider_ = PoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
        aaveLendingPool = AaveLendingPool(aaveAddressesProvider_.getLendingPool());
        aaveProtocolDataProvider = AaveProtocolDataProvider(aaveAddressesProvider_.getAddress(AAVE_PROVIDER_ID));
    }

    ///////////////////////// External access functions /////////////////////////

    /**
     * @notice Initiate cooldown to unstake aave.
     * @dev We only want to call this function when cooldown is expired and
     * that's the reason we have 'if' condition.
     * @dev Child contract should expose this function as external and onlyKeeper
     */
    function _startCooldown() internal returns (bool) {
        if (canStartCooldown()) {
            stkAAVE.cooldown();
            return true;
        }
        return false;
    }

    /**
     * @notice Unstake Aave from stakedAave contract
     * @dev We want to unstake as soon as favorable condition exit
     * @dev No guarding condition thus this call can fail, if we can't unstake.
     * @dev Child contract should expose this function as external and onlyKeeper
     */
    function _unstakeAave() internal {
        stkAAVE.redeem(address(this), type(uint256).max);
    }

    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns true if Aave can be unstaked
    function canUnstake() external view returns (bool) {
        (, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        return _canUnstake(_cooldownEnd, _unstakeEnd);
    }

    /// @notice Returns true if we should start cooldown
    function canStartCooldown() public view returns (bool) {
        (uint256 _cooldownStart, , uint256 _unstakeEnd) = cooldownData();
        return _canStartCooldown(_cooldownStart, _unstakeEnd);
    }

    /// @notice Return cooldown related timestamps
    function cooldownData() public view returns (uint256 _cooldownStart, uint256 _cooldownEnd, uint256 _unstakeEnd) {
        _cooldownStart = stkAAVE.stakersCooldowns(address(this));
        _cooldownEnd = _cooldownStart + stkAAVE.COOLDOWN_SECONDS();
        _unstakeEnd = _cooldownEnd + stkAAVE.UNSTAKE_WINDOW();
    }

    /**
     * @notice Claim Aave. Also unstake all Aave if favorable condition exits or start cooldown.
     * @dev If we unstake all Aave, we can't start cooldown because it requires StakedAave balance.
     * @dev DO NOT convert 'if else' to 2 'if's as we are reading cooldown state once to save gas.
     * @dev Not all collateral token has aave incentive
     */
    function _claimAave() internal returns (uint256) {
        (uint256 _cooldownStart, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        if (address(aaveIncentivesController) != address(0) && (_cooldownStart == 0 || block.timestamp > _unstakeEnd)) {
            // claim stkAave when its first rebalance or unstake period passed.
            aaveIncentivesController.claimRewards(getAssets(), type(uint256).max, address(this));
        }
        if (stkAAVE.balanceOf(address(this)) > 0) {
            // Fetch and check again for next action.
            (_cooldownStart, _cooldownEnd, _unstakeEnd) = cooldownData();
            if (_canUnstake(_cooldownEnd, _unstakeEnd)) {
                stkAAVE.redeem(address(this), type(uint256).max);
            } else if (_canStartCooldown(_cooldownStart, _unstakeEnd)) {
                stkAAVE.cooldown();
            }

            stkAAVE.claimRewards(address(this), type(uint256).max);
        }
        return IERC20(AAVE).balanceOf(address(this));
    }

    /// @notice Deposit asset into Aave
    function _deposit(address _asset, uint256 _amount) internal {
        if (_amount > 0) {
            try aaveLendingPool.deposit(_asset, _amount, address(this), 0) {} catch Error(string memory _reason) {
                // Aave uses liquidityIndex and some other indexes as needed to normalize input.
                // If normalized input equals to 0 then error will be thrown with '56' error code.
                // CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
                // Hence discard error where error code is '56'
                require(bytes32(bytes(_reason)) == "56", _reason);
            }
        }
    }

    function getAssets() internal view returns (address[] memory) {
        address[] memory _assets = new address[](1);
        _assets[0] = address(aToken);
        return _assets;
    }

    /**
     * @notice Safe withdraw will make sure to check asking amount against available amount.
     * @dev Check we have enough aToken and liquidity to support this withdraw
     * @param _asset Address of asset to withdraw
     * @param _to Address that will receive collateral token.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _safeWithdraw(address _asset, address _to, uint256 _amount) internal returns (uint256) {
        uint256 _aTokenBalance = aToken.balanceOf(address(this));
        // If Vesper becomes large liquidity provider in Aave(This happened in past in vUSDC 1.0)
        // In this case we might have more aToken compare to available liquidity in Aave and any
        // withdraw asking more than available liquidity will fail. To do safe withdraw, check
        // _amount against available liquidity.
        uint256 _availableLiquidity = IERC20(_asset).balanceOf(address(aToken));

        // Get minimum of _amount, _aTokenBalance and _availableLiquidity
        return _withdraw(_asset, _to, Math.min(_amount, Math.min(_aTokenBalance, _availableLiquidity)));
    }

    /**
     * @notice Withdraw given amount of collateral from Aave to given address
     * @param _asset Address of asset to withdraw
     * @param _to Address that will receive collateral token.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _withdraw(address _asset, address _to, uint256 _amount) internal returns (uint256) {
        if (_amount > 0) {
            require(aaveLendingPool.withdraw(_asset, _amount, _to) == _amount, Errors.INCORRECT_WITHDRAW_AMOUNT);
        }
        return _amount;
    }

    /**
     * @dev Return true, only if we have StakedAave balance and either cooldown expired or cooldown is zero
     * @dev If we are in cooldown period we cannot unstake Aave. But our cooldown is still valid so we do
     * not want to reset/start cooldown.
     */
    function _canStartCooldown(uint256 _cooldownStart, uint256 _unstakeEnd) internal view returns (bool) {
        return stkAAVE.balanceOf(address(this)) > 0 && (_cooldownStart == 0 || block.timestamp > _unstakeEnd);
    }

    /// @dev Return true, if cooldown is over and we are in unstake window.
    function _canUnstake(uint256 _cooldownEnd, uint256 _unstakeEnd) internal view returns (bool) {
        return block.timestamp > _cooldownEnd && block.timestamp <= _unstakeEnd;
    }

    /**
     * @notice Return total AAVE incentive allocated to this address
     * @dev Aave and StakedAave are 1:1
     * @dev Not all collateral token has aave incentive
     */
    function _totalAave() internal view returns (uint256) {
        if (address(aaveIncentivesController) == address(0)) {
            return 0;
        }
        // TotalAave = Get current StakedAave rewards from controller +
        //             StakedAave balance here +
        //             Aave rewards by staking Aave in StakedAave contract
        return
            aaveIncentivesController.getRewardsBalance(getAssets(), address(this)) +
            stkAAVE.balanceOf(address(this)) +
            stkAAVE.getTotalRewardsBalance(address(this));
    }
}