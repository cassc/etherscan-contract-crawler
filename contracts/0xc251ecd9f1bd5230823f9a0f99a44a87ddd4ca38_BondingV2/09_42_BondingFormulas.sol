// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./BondingShareV2.sol";
import "./libs/ABDKMathQuad.sol";

import "./interfaces/IMasterChefV2.sol";

contract BondingFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    uint256 public constant ONE = uint256(1 ether); //   18 decimals

    /// @dev formula UBQ Rights corresponding to a bonding shares LP amount
    /// @param _bond , bonding share
    /// @param _amount , amount of LP tokens
    /// @notice shares = (bond.shares * _amount )  / bond.lpAmount ;
    function sharesForLP(
        BondingShareV2.Bond memory _bond,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256 _uLP) {
        bytes16 a = _shareInfo[0].fromUInt(); // shares amount
        bytes16 v = _amount.fromUInt();
        bytes16 t = _bond.lpAmount.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
    }

    /// @dev formula may add a decreasing rewards if locking end is near when removing liquidity
    /// @param _bond , bonding share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsRemoveLiquidityNormalization(
        BondingShareV2.Bond memory _bond,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256) {
        return _amount;
    }

    /* solhint-enable no-unused-vars */
    /// @dev formula may add a decreasing rewards if locking end is near when adding liquidity
    /// @param _bond , bonding share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsAddLiquidityNormalization(
        BondingShareV2.Bond memory _bond,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256) {
        return _amount;
    }

    /* solhint-enable no-unused-vars */

    /// @dev formula to calculate the corrected amount to withdraw based on the proportion of
    ///      lp deposited against actual LP token on thge bonding contract
    /// @param _totalLpDeposited , Total amount of LP deposited by users
    /// @param _bondingLpBalance , actual bonding contract LP tokens balance minus lp rewards
    /// @param _amount , amount of LP tokens
    /// @notice corrected_amount = amount * ( bondingLpBalance / totalLpDeposited)
    ///         if there is more or the same amount of LP than deposited then do nothing
    function correctedAmountToWithdraw(
        uint256 _totalLpDeposited,
        uint256 _bondingLpBalance,
        uint256 _amount
    ) public pure returns (uint256) {
        if (_bondingLpBalance < _totalLpDeposited && _bondingLpBalance > 0) {
            // if there is less LP token inside the bonding contract that what have been deposited
            // we have to reduce proportionnaly the lp amount to withdraw
            return
                _amount
                    .fromUInt()
                    .mul(_bondingLpBalance.fromUInt())
                    .div(_totalLpDeposited.fromUInt())
                    .toUInt();
        }
        return _amount;
    }
}