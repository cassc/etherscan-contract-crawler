// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ILendingPoolAddressesProvider} from "../../.aave/v2/Interfaces.sol";
import {FlashLoanReceiverBase} from "../../.aave/v2/FlashLoanReceiverBase.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {Math} from "../../lib/Math.sol";
import {Ownable} from "../../lib/Ownable.sol";
import {SafeERC20} from "../../lib/SafeERC20.sol";
import {IERC20Metadata} from "../../token/IERC20Metadata.sol";
import {ISapphireCoreV1} from "./ISapphireCoreV1.sol";
import {ISapphirePool} from "../SapphirePool/ISapphirePool.sol";
import {SapphireTypes} from "../SapphireTypes.sol";

/**
 * @title FlashLiquidatorAaveV2
 * @author ARCx
 * @notice A basic flash loan based contracts that is used to liquidate borrowers of SapphireCoreV1
 * contracts. It takes a flash loan to repay the user's debt, swaps the collateral to the
 * repaid stablecoin, transfers the profit to the caller of the liquidate function, then repays
 * the flash loan debt.
 */
contract FlashLiquidatorAaveV2 is FlashLoanReceiverBase, Ownable {

    event ProfitReceiverSet(address indexed profitReceiver);

    address public profitReceiver;

    struct LiquidationVariables {
        address vaultOwner;
        SapphireTypes.ScoreProof[] proofs;
        ISapphireCoreV1 core;
        address collateralAsset;
    }

    ISwapRouter public immutable swapRouter;

    constructor(
        ILendingPoolAddressesProvider _provider,
        ISwapRouter _router,
        address _profitReceiver
    )
        FlashLoanReceiverBase(_provider)
    {
        swapRouter = _router;
        profitReceiver = _profitReceiver;
    }

    function liquidate(
        address _core,
        address _owner,
        SapphireTypes.ScoreProof memory _creditScoreProof
    )
        external
    {
        ISapphireCoreV1 core = ISapphireCoreV1(_core);

        // Get a valid repayment asset
        ISapphirePool pool = ISapphirePool(core.borrowPool());
        IERC20Metadata repayAsset = IERC20Metadata(pool.getDepositAssets()[0]);
        uint8 repayAssetDecimals = repayAsset.decimals();

        // get user's current debt
        SapphireTypes.Vault memory vault = core.vaults(_owner);
        uint256 outstandingDebt = Math.roundUpMul(
            vault.normalizedBorrowedAmount,
            core.currentBorrowIndex()
        );
        uint256 precisionScalar = 10 ** (18 - uint256(repayAssetDecimals));
        uint256 outstandingDebtScaled = outstandingDebt / precisionScalar;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = outstandingDebtScaled;

        // get a flash loan of the amount of the current debt
        bytes memory params = abi.encode(
            _core,
            _owner,
            _creditScoreProof
        );
        address[] memory assets = new address[](1);
        assets[0] = address(repayAsset);

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // no debt

        LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
    }

    /**
     * @dev This function is called by the Aave pool after the funds have been transferred.
     * It executes the liquidation, then swaps the gained collateral for the stablecoin and
     * transfers it to the original sender that called `liquidate()`.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        LiquidationVariables memory liquidationVars = _getVariablesForLiquidation(params);
        address asset = assets[0];
        uint256 amount = amounts[0];
        uint256 premium = premiums[0];

        _executeLiquidation(
            liquidationVars,
            asset,
            amount
        );

        _swapCollateralForStables(liquidationVars.collateralAsset, asset);

        // transfer profit to sender
        uint256 loanRepaymentAmount = amount + premium;
        SafeERC20.safeTransfer(
            IERC20Metadata(asset),
            profitReceiver,
            IERC20Metadata(asset).balanceOf(address(this)) - loanRepaymentAmount
        );

        // Approve the loan for repayment
        SafeERC20.safeApprove(
            IERC20Metadata(asset),
            address(LENDING_POOL),
            loanRepaymentAmount
        );

        return true;
    }

    function setProfitReceiver(address _profitReceiver)
        external
        onlyOwner
    {
        profitReceiver = _profitReceiver;

        emit ProfitReceiverSet(_profitReceiver);
    }

    function _executeLiquidation(
        LiquidationVariables memory liquidationVars,
        address _loanAsset,
        uint256 _loanAmount
    )
        internal
    {
        // approve the loan to the vault
        SafeERC20.safeApprove(
            IERC20Metadata(_loanAsset),
            address(liquidationVars.core),
            _loanAmount
        );

        // liquidate position
        liquidationVars.core.liquidate(
            liquidationVars.vaultOwner,
            _loanAsset,
            liquidationVars.proofs
        );
    }

    function _getVariablesForLiquidation(
        bytes memory _params
    )
        internal
        view
        returns (LiquidationVariables memory)
    {
        (
            address coreAddress,
            address vaultOwner,
            SapphireTypes.ScoreProof memory creditScoreProof
        ) = abi.decode(_params, (
            address,
            address,
            SapphireTypes.ScoreProof
        ));
        ISapphireCoreV1 core = ISapphireCoreV1(coreAddress);

        SapphireTypes.ScoreProof[] memory proofs = new SapphireTypes.ScoreProof[](1);
        proofs[0] = creditScoreProof;

        return LiquidationVariables(
            vaultOwner,
            proofs,
            core,
            core.collateralAsset()
        );
    }

    function _swapCollateralForStables(
        address _collateralAsset,
        address _tokenOut
    )
        internal
    {
        uint256 collateralBalance = IERC20Metadata(_collateralAsset).balanceOf(address(this));

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _collateralAsset,
                tokenOut: _tokenOut,
                fee: 3000, // 0.3%
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: collateralBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        SafeERC20.safeApprove(
            IERC20Metadata(_collateralAsset),
            address(swapRouter),
            collateralBalance
        );

        swapRouter.exactInputSingle(params);
    }
}