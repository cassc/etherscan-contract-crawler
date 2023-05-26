// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IMyobu is IERC20 {
    event DAOChanged(address newDAOContract);
    event MyobuSwapChanged(address newMyobuSwap);

    function DAO() external view returns (address); // solhint-disable-line

    function myobuSwap() external view returns (address);

    event TaxAddressChanged(address newTaxAddress);
    event TaxedTransferAddedFor(address[] addresses);
    event TaxedTransferRemovedFor(address[] addresses);

    event FeesTaken(uint256 teamFee);
    event FeesChanged(Fees newFees);

    struct Fees {
        uint256 impact;
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
    }

    function currentFees() external view returns (Fees memory);

    struct LiquidityETHParams {
        address pair;
        address to;
        uint256 amountTokenOrLP;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 deadline;
    }

    event LiquidityAddedETH(
        address pair,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function noFeeAddLiquidityETH(LiquidityETHParams calldata params)
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    event LiquidityRemovedETH(
        address pair,
        uint256 amountToken,
        uint256 amountETH,
        uint256 amountRemoved
    );

    function noFeeRemoveLiquidityETH(LiquidityETHParams calldata params)
        external
        returns (uint256 amountToken, uint256 amountETH);

    struct AddLiquidityParams {
        address pair;
        address to;
        uint256 amountToken;
        uint256 amountTokenB;
        uint256 amountTokenMin;
        uint256 amountTokenBMin;
        uint256 deadline;
    }

    event LiquidityAdded(
        address pair,
        uint256 amountMyobu,
        uint256 amountToken,
        uint256 liquidity
    );

    function noFeeAddLiquidity(AddLiquidityParams calldata params)
        external
        returns (
            uint256 amountMyobu,
            uint256 amountToken,
            uint256 liquidity
        );

    struct RemoveLiquidityParams {
        address pair;
        address to;
        uint256 amountLP;
        uint256 amountTokenMin;
        uint256 amountTokenBMin;
        uint256 deadline;
    }

    event LiquidityRemoved(
        address pair,
        uint256 amountMyobu,
        uint256 amountToken,
        uint256 liquidity
    );

    function noFeeRemoveLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (uint256 amountMyobu, uint256 amountToken);

    function taxedPair(address pair) external view returns (bool);
}