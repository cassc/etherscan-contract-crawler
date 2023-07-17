//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IUSDC.sol";
import "./interfaces/IHauler.sol";
import "./interfaces/IBatcherOld.sol";
import "./interfaces/IVaultOld.sol";
import "./interfaces/IOldConvexTE.sol";
import "./interfaces/IOldPerpTEL2.sol";
import "../Batcher/interfaces/IBatcher.sol";
import "hardhat/console.sol";

contract Migratooor {
    IBatcherOld public oldBatcher =
        IBatcherOld(0x1b6BF7Ab4163f9a7C1D4eCB36299525048083B5e);

    IHauler public oldHauler =
        IHauler(0x1C4ceb52ab54a35F9d03FcC156a7c57F965e081e);

    IUSDC public usdc = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IBatcher public newBatcher;

    constructor(address batcher) {
        newBatcher = IBatcher(batcher);
    }

    function migrateToV2(
        uint256 pmusdcAmount,
        uint256 approvalAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory karmaSignature
    ) public {
        uint256 oldUserBalance = usdc.balanceOf(msg.sender);

        // Burn PMUSDC to get USDC
        uint256 amountOut = oldHauler.withdraw(pmusdcAmount, msg.sender);

        if (approvalAmount > 0) {
            usdc.permit(
                msg.sender,
                address(this),
                approvalAmount,
                deadline,
                v,
                r,
                s
            );
        }

        uint256 newUserBalance = usdc.balanceOf(msg.sender);

        require(
            newUserBalance - oldUserBalance == amountOut,
            "USDC balance mismatch"
        );

        uint256 oldMigratorBalance = usdc.balanceOf(address(this));

        // Use transfer auth signature to transfer usdc to contract
        usdc.transferFrom(msg.sender, address(this), amountOut);

        uint256 newMigratorBalance = usdc.balanceOf(address(this));

        require(
            newMigratorBalance - oldMigratorBalance == amountOut,
            "No usdc received"
        );

        // Deposit USDC to new batcher on behalf of msg sender
        IBatcher.PermitParams memory params = IBatcher.PermitParams({
            value: 0,
            deadline: 0,
            v: 0,
            r: 0x0,
            s: 0x0
        });

        usdc.approve(address(newBatcher), amountOut);
        newBatcher.depositFunds(amountOut, karmaSignature, msg.sender, params);
    }
}