// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";
import {VaultCallback} from "./VaultCallback.sol";
import {ISwapRouter} from "../interfaces/callbacks/ISwapRouter.sol";
import {IVaultCallback} from "../interfaces/IVaultCallback.sol";

contract UniV3Looping is VaultCallback {
    using SafeERC20 for IERC20Metadata;

    address private constant UNI_V3_SWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    constructor(address _borrowerGateway) VaultCallback(_borrowerGateway) {} // solhint-disable no-empty-blocks

    function borrowCallback(
        DataTypesPeerToPeer.Loan calldata loan,
        bytes calldata data
    ) external {
        (uint256 minSwapReceive, uint256 deadline, uint24 poolFee) = abi.decode(
            data,
            (uint256, uint256, uint24)
        );
        // swap whole loan token balance received from borrower gateway
        uint256 loanTokenBalance = IERC20(loan.loanToken).balanceOf(
            address(this)
        );
        IERC20Metadata(loan.loanToken).safeIncreaseAllowance(
            UNI_V3_SWAP_ROUTER,
            loanTokenBalance
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: loan.loanToken,
                tokenOut: loan.collToken,
                fee: poolFee,
                recipient: loan.borrower,
                deadline: deadline,
                amountIn: loanTokenBalance,
                amountOutMinimum: minSwapReceive,
                sqrtPriceLimitX96: 0
            });
        ISwapRouter(UNI_V3_SWAP_ROUTER).exactInputSingle(params);
        IERC20Metadata(loan.loanToken).safeDecreaseAllowance(
            UNI_V3_SWAP_ROUTER,
            IERC20Metadata(loan.loanToken).allowance(
                address(this),
                UNI_V3_SWAP_ROUTER
            )
        );
    }

    function _repayCallback(
        DataTypesPeerToPeer.Loan calldata loan,
        bytes calldata data
    ) internal override {
        (uint256 minSwapReceive, uint256 deadline, uint24 poolFee) = abi.decode(
            data,
            (uint256, uint256, uint24)
        );
        // swap whole coll token balance received from borrower gateway
        uint256 collTokenBalance = IERC20(loan.collToken).balanceOf(
            address(this)
        );
        IERC20Metadata(loan.collToken).safeIncreaseAllowance(
            UNI_V3_SWAP_ROUTER,
            collTokenBalance
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: loan.collToken,
                tokenOut: loan.loanToken,
                fee: poolFee,
                recipient: loan.borrower,
                deadline: deadline,
                amountIn: collTokenBalance,
                amountOutMinimum: minSwapReceive,
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(UNI_V3_SWAP_ROUTER).exactInputSingle(params);
        IERC20Metadata(loan.collToken).safeDecreaseAllowance(
            UNI_V3_SWAP_ROUTER,
            IERC20Metadata(loan.collToken).allowance(
                address(this),
                UNI_V3_SWAP_ROUTER
            )
        );
    }
}