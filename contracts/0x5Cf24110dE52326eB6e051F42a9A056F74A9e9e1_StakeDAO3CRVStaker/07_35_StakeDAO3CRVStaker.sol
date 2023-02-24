// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../StakeDAOTokenStakerMainnet.sol";

/// @title StakeDAO3CRVStaker
/// @author Angle Labs, Inc.
/// @dev Implementation of `StakeDAOTokenStakerMainnet` for the 3CRV pool
contract StakeDAO3CRVStaker is StakeDAOTokenStakerMainnet {
    // ============================= VIRTUAL FUNCTIONS =============================

    /// @inheritdoc BorrowStaker
    function asset() public pure override returns (IERC20) {
        return IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    }

    /// @inheritdoc StakeDAOTokenStaker
    function _vault() internal pure override returns (IStakeCurveVault) {
        return IStakeCurveVault(0xb9205784b05fbe5b5298792A24C2CB844B7dc467);
    }

    /// @inheritdoc StakeDAOTokenStaker
    function _gauge() internal pure override returns (ILiquidityGauge) {
        return ILiquidityGauge(0xf99FD99711671268EE557fEd651EA45e34B2414f);
    }
}