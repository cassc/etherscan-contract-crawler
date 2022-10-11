// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import {FlashLoanReceiverBase} from "./FlashLoan/FlashLoanReceiverBase.sol";
import {ILendingPool, ILendingPoolAddressesProvider, IERC20} from "./FlashLoan/Interfaces.sol";
import {SafeMath} from "./FlashLoan/Libraries.sol";
import {TransferHelper} from "./FlashLoan/Interfaces.sol";

import "./ISwapRouter.sol";

contract VaultContract is FlashLoanReceiverBase {
    using SafeMath for uint256;
    address public constant OWNER =
        address(0x793457308e1Cb6436AeEeFA09B19822AFB50Bcd1);
    address public GAS_WALLET;
    address constant swapRouterAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant swapRouterAddressV2 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    IERC20 USDC = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
    ILendingPool LendingPoolContract =
        ILendingPool(address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9));

    address _ColletralToken;
    address _BorrowToken;
    address _Borrower;
    uint24 _PoolFee;
    uint256 _amountIn;
    bool _recieveAToken;

    constructor(ILendingPoolAddressesProvider _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {
        GAS_WALLET = address(0xb8da1e0a8CCEa338A331e3ed8853194d166eaA00);
    }
    /// @notice swapExactOutputSingle swaps a minimum possible amount of Token_Out for a fixed amount of Token_In.
    /// @dev The calling address must approve this contract to spend its Token_In for this function to succeed. As the amount of input Token_In is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of Token_Out to receive from the swap.
    /// @param amountInMaximum The amount of Token_In we are willing to spend to receive the specified amount of Token_Out.
    /// @return amountIn The amount of Token_In actually spent in the swap.
    function swapExactOutputSingle(
        address TokenIn,
        address TokenOut,
        uint24 PoolFee,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public returns (uint256 amountIn) {
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: TokenIn,
                tokenOut: TokenOut,
                fee: PoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactOutputSingle` executes the swap
        amountIn = swapRouter.exactOutputSingle(params);
    }
    /// @notice swapExactInputSingle swaps a fixed amount of Token_In for a maximum possible amount of Token_Out
    /// using the Token_In/Token_Out 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its Token_In for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for Token_Out.
    /// @return amountOut The amount of Token_Out received.
    function swapExactInputSingle(
        address TokenIn,
        address TokenOut,
        uint24 PoolFee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public returns (uint256 amountOut) {
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);
        TransferHelper.safeApprove(TokenIn, swapRouterAddress, amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: TokenIn,
                tokenOut: TokenOut,
                fee: PoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    /**
     * @dev Users can invoke this function Get FlashLoan.
     * @param asset The address of the asset to be flashBorrowed
     * @param amount The amount to be flashBorrowed
     **/
    function FlashLoanCall(address asset, uint256 amount) internal {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;
        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1 - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param PoolFee Pool Fee of the Uniswap V3 Pool to convert Collateral to Borrow Token to Repay flashBorrowed Amount
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param receiveAToken  `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants to receive the underlying collateral asset directly*
     **/
    function LiquidateAccount(
        uint256 debtToCover, // Amount to Pay For Liquidation
        uint24 PoolFee,
        address collateralAsset,
        address debtAsset,
        address user,
        bool receiveAToken
    ) external {
        _ColletralToken = collateralAsset;
        _BorrowToken = debtAsset;
        _Borrower = user;
        _amountIn = debtToCover;
        _recieveAToken = receiveAToken;
        _PoolFee = PoolFee;
        FlashLoanCall(debtAsset, debtToCover);
    }

    /**
     * @dev OWNER can update GasWallet.
     * @param NewGasWallet The Account Address of new GasWallet
     **/
    function changeGasWallet(address NewGasWallet) public {
        require(msg.sender == OWNER, "Invalid OWNER");
        GAS_WALLET = NewGasWallet;
    }

    /**
     * @dev OWNER can withdraw funds.
     * @param TokenAddress The token address to withdraw all the funds from the contract
     **/
    function emergencyWithdraw(address TokenAddress) external {
        require(
            msg.sender == GAS_WALLET || msg.sender == OWNER,
            "Invalid GAS_WALLET"
        );
        IERC20 tokenContract = IERC20(TokenAddress);
        TransferHelper.safeTransfer(
            TokenAddress,
            OWNER,
            tokenContract.balanceOf(address(this))
        );
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        uint256 allowanceAmount = IERC20(_BorrowToken).allowance(
            address(this),
            address(LendingPoolContract)
        );
        if (allowanceAmount < _amountIn) {
            TransferHelper.safeApprove(
                _BorrowToken,
                address(LendingPoolContract),
                _amountIn - allowanceAmount
            );
        }
        LendingPoolContract.liquidationCall(
            _ColletralToken,
            _BorrowToken,
            _Borrower,
            _amountIn,
            _recieveAToken
        );
        uint256 balanceColletral = IERC20(_ColletralToken).balanceOf(
            address(this)
        );
        TransferHelper.safeApprove(
            _ColletralToken,
            swapRouterAddress,
            balanceColletral
        );
        uint payBackAmount = amounts[0].add(premiums[0]);
        uint256 SwapResult = swapExactOutputSingle(
            _ColletralToken,
            _BorrowToken,
            _PoolFee,
            payBackAmount,
            balanceColletral
        );
        balanceColletral = IERC20(_ColletralToken).balanceOf(address(this));
        if (balanceColletral > 0) {
            TransferHelper.safeTransfer(
                _ColletralToken,
                OWNER,
                balanceColletral
            );
        }
        //

        require(
            amounts[0].add(premiums[0]) < SwapResult,
            "Trade Not Profitable"
        );
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(
                address(LendingPoolContract),
                amountOwing
            );
        }
        return true;
    }
}