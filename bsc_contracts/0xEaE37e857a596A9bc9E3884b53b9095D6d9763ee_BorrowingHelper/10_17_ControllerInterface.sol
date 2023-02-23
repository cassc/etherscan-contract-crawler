// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface ControllerInterface {
    function collBorrowAllowed(uint marketId, address borrower, bool collateralIndex) external view returns (bool);

    function collRepayAllowed(uint marketId) external view returns (bool);

    function collRedeemAllowed(uint marketId) external view returns (bool);

    function collLiquidateAllowed(uint marketId) external view returns (bool);
}