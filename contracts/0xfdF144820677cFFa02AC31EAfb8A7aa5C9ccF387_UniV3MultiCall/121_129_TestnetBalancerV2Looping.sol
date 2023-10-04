// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BalancerDataTypes} from "../peer-to-peer/interfaces/callbacks/BalancerDataTypes.sol";
import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {VaultCallback} from "../peer-to-peer/callbacks/VaultCallback.sol";
import {IBalancerAsset} from "../peer-to-peer/interfaces/callbacks/IBalancerAsset.sol";
import {IBalancerVault} from "../peer-to-peer/interfaces/callbacks/IBalancerVault.sol";
import {IVaultCallback} from "../peer-to-peer/interfaces/IVaultCallback.sol";

contract TestnetBalancerV2Looping is VaultCallback {
    using SafeERC20 for IERC20Metadata;

    address private constant BALANCER_V2_VAULT =
        0x5758059F5b5f636D4E68dD729b43729B4cF34870;

    constructor(address _borrowerGateway) VaultCallback(_borrowerGateway) {} // solhint-disable no-empty-blocks

    function borrowCallback(
        DataTypesPeerToPeer.Loan calldata loan,
        bytes calldata data
    ) external {
        BalancerDataTypes.FundManagement
            memory fundManagement = BalancerDataTypes.FundManagement({
                sender: address(this), // swap payer
                fromInternalBalance: false, // use payer's internal balance
                recipient: payable(loan.borrower), // swap receiver
                toInternalBalance: false // user receiver's internal balance
            });
        (bytes32 poolId, uint256 minSwapReceive, uint256 deadline) = abi.decode(
            data,
            (bytes32, uint256, uint256)
        );
        // swap whole loan token balance received from borrower gateway
        uint256 loanTokenBalance = IERC20(loan.loanToken).balanceOf(
            address(this)
        );
        IERC20Metadata(loan.loanToken).safeIncreaseAllowance(
            BALANCER_V2_VAULT,
            loanTokenBalance
        );
        BalancerDataTypes.SingleSwap memory singleSwap = BalancerDataTypes
            .SingleSwap({
                poolId: poolId,
                kind: BalancerDataTypes.SwapKind.GIVEN_IN,
                assetIn: IBalancerAsset(loan.loanToken),
                assetOut: IBalancerAsset(loan.collToken),
                amount: loanTokenBalance,
                userData: ""
            });
        IBalancerVault(BALANCER_V2_VAULT).swap(
            singleSwap,
            fundManagement,
            minSwapReceive,
            deadline
        );
        IERC20Metadata(loan.loanToken).safeDecreaseAllowance(
            BALANCER_V2_VAULT,
            IERC20Metadata(loan.loanToken).allowance(
                address(this),
                BALANCER_V2_VAULT
            )
        );
    }

    function _repayCallback(
        DataTypesPeerToPeer.Loan calldata loan,
        bytes calldata data
    ) internal override {
        BalancerDataTypes.FundManagement
            memory fundManagement = BalancerDataTypes.FundManagement({
                sender: address(this), // swap payer
                fromInternalBalance: false, // use payer's internal balance
                recipient: payable(loan.borrower), // swap receiver
                toInternalBalance: false // user receiver's internal balance
            });
        (bytes32 poolId, uint256 minSwapReceive, uint256 deadline) = abi.decode(
            data,
            (bytes32, uint256, uint256)
        );
        // swap whole coll token balance received from borrower gateway
        uint256 collBalance = IERC20(loan.collToken).balanceOf(address(this));
        BalancerDataTypes.SingleSwap memory singleSwap = BalancerDataTypes
            .SingleSwap({
                poolId: poolId,
                kind: BalancerDataTypes.SwapKind.GIVEN_IN,
                assetIn: IBalancerAsset(loan.collToken),
                assetOut: IBalancerAsset(loan.loanToken),
                amount: collBalance,
                userData: ""
            });
        IERC20Metadata(loan.collToken).safeIncreaseAllowance(
            BALANCER_V2_VAULT,
            collBalance
        );
        IBalancerVault(BALANCER_V2_VAULT).swap(
            singleSwap,
            fundManagement,
            minSwapReceive,
            deadline
        );
        IERC20Metadata(loan.collToken).safeDecreaseAllowance(
            BALANCER_V2_VAULT,
            IERC20Metadata(loan.collToken).allowance(
                address(this),
                BALANCER_V2_VAULT
            )
        );
    }
}