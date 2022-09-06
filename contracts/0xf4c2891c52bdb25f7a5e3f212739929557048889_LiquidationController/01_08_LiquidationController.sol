// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/WETH.sol";
import { FlashLoanReceiverBase, ILendingPoolAddressesProvider } from "./interfaces/AaveV2Interfaces.sol";
import { bdToken, Stabilizer } from "./interfaces/BaoInterfaces.sol";
import { ISwapRouter } from "./interfaces/UniswapInterfaces.sol";
import { ICurve } from "./interfaces/CurveInterfaces.sol";

contract LiquidationController is FlashLoanReceiverBase {
    bdToken constant bdUSD = bdToken(0xc0601094C0C88264Ba285fEf0a1b00eF13e79347);
    WETH constant wrappedETH = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 constant bSTBL = ERC20(0x5ee08f40b637417bcC9d2C51B62F4820ec9cF5D8);
    ERC20 constant bdSTBL = ERC20(0xE0a55c00E6510F4F7df9af78b116B7f8E705cA8F);
    ERC20 constant bdETH = ERC20(0xF635fdF9B36b557bD281aa02fdfaeBEc04CD084A);
    ERC20 constant bUSD = ERC20(0x7945b0A6674b175695e5d1D08aE1e6F13744Abb0);
    ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ICurve constant curvePoolbUSD = ICurve(0x0FaFaFD3C393ead5F5129cFC7e0E12367088c473); // bUSD-3Pool
    ICurve constant curvePoolbSTBL = ICurve(0xA148BD19E26Ff9604f6A608E22BFb7B772D0d1A3); // bSTBL-DAI
    ISwapRouter constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniV3 Router

    address immutable public owner; // Only used for the retrieve function, no need to use OZ's Ownable or Solmate's Auth

    event log_named_uint(string key, uint val);

    mapping(address => uint24) poolFee;

    constructor(
        address _lpap
    ) FlashLoanReceiverBase(ILendingPoolAddressesProvider(_lpap)) {
        owner = msg.sender;

        // Approve tokens on contract creation to save gas during liquidations
        DAI.approve(address(curvePoolbUSD), type(uint256).max);
        bUSD.approve(address(curvePoolbUSD), type(uint256).max);
        bUSD.approve(address(bdUSD), type(uint256).max);
        wrappedETH.approve(address(swapRouter), type(uint256).max);
        bSTBL.approve(address(curvePoolbSTBL), type(uint256).max);
        USDC.approve(address(swapRouter), type(uint256).max);
    }

    // This function is called after the contract has received the flash loan
    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata _params
    ) external override returns(bool) {
        (address _borrower, uint256 _repayAmount, address _bdCollateral) = abi.decode(_params, (address, uint256, address));
        // Exchange DAI for bUSD on Curve
        curvePoolbUSD.exchange_underlying(1, 0, amounts[0], 0);

        // If liquidation doesn't succed, we revert
        require(bdUSD.liquidateBorrow(_borrower, _repayAmount, _bdCollateral) == 0);

        bdToken bdCollateral = bdToken(_bdCollateral);

        bdCollateral.redeem(bdCollateral.balanceOf(address(this)));
        ISwapRouter.ExactInputSingleParams memory params;
        uint collateralAmount;

        // If we are handling eth -> transform to weth before selling
        if (_bdCollateral==address(bdETH)) {
            collateralAmount = address(this).balance;

            // ETH to WETH
            wrappedETH.deposit{value: collateralAmount}();

            // Define Swap Params
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(wrappedETH),
                tokenOut: address(DAI),
                fee: 3000, // Hardcoded cause SLOADs are expensive (361 gas here)
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: collateralAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            // Execute Swap
            swapRouter.exactInputSingle(params);
        }
        else if (_bdCollateral==address(bdSTBL)) {
            // Get amount of seized assets
            address underlyingCollateral = bdCollateral.underlying();
            collateralAmount = ERC20(underlyingCollateral).balanceOf(address(this));
            //Swap bSTBL for DAI on Curve
            bSTBL.approve(address(curvePoolbSTBL), collateralAmount);
            curvePoolbSTBL.exchange(1, 0, collateralAmount, 0);
        }
        // Swapping USDC for DAI
        else {
            // Get amount of seized assets
            address underlyingCollateral = bdCollateral.underlying();
            collateralAmount = ERC20(underlyingCollateral).balanceOf(address(this));

            // Define Swap Params
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: underlyingCollateral,
                tokenOut: address(DAI),
                fee: 100, //0.01%
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: collateralAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            // Execute Swap
            swapRouter.exactInputSingle(params);
        }       
        uint totalDebt = amounts[0] + premiums[0];
        DAI.approve(address(LENDING_POOL), totalDebt);
        return true;
    }

    /**
      * @notice Method to liquidate users given an address, amount and asset.
      * @param _borrower The addresses whose borrow we are going to repay (liquidations)
      * @param _repayAmount The number of borrowed assets we want to repay
      * @param _bdCollateral The bdToken address of the collateral we want to claim
      */
    function executeLiquidations(
        address _borrower,
        uint256 _repayAmount,
        address _bdCollateral,
        uint256 _loan_amount,
        address _receiver
    ) external {
        bytes memory params = abi.encode(_borrower,_repayAmount,_bdCollateral);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _loan_amount;

        address[] memory assets = new address[](1);
        assets[0] = address(DAI);

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);

        // Transfer funds to _receiver (to avoid griefing attack)
        DAI.transfer(_receiver, DAI.balanceOf(address(this)));
    }

    // In case any funds are sent to the contract, allow the owner to retrieve them
    function retrieve(address token, uint256 amount) external {
        require(owner == msg.sender, "Must be owner");

        ERC20 tokenContract = ERC20(token);
        tokenContract.transfer(msg.sender, amount);
    }

    // Needed for bdETH redeem
    receive() external payable {}
}