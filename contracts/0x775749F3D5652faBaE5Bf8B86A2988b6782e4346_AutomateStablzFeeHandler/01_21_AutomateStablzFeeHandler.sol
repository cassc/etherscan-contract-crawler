//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "contracts/chainlink/common/ChainLinkAutomation.sol";
import "contracts/fees/StablzFeeHandler.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/// @title ChainLink automation for Stablz fee handler
contract AutomateStablzFeeHandler is ChainLinkAutomation {

    StablzFeeHandler public immutable feeHandler;
    uint public slippage = 50;
    uint public constant MAX_SLIPPAGE = 500;
    uint public constant SLIPPAGE_DENOMINATOR = 10000;
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event BuyBackSlippageUpdated(uint slippage);

    /// @param _feeHandler Stablz fee handler address
    /// @param _keeperRegistry Chainlink keeper registry address
    constructor(StablzFeeHandler _feeHandler, address _keeperRegistry) ChainLinkAutomation(_keeperRegistry){
        require(address(_feeHandler) != address(0), "AutomateStablzFeeHandler: _feeHandler cannot be the zero address");
        feeHandler = _feeHandler;
    }

    /// @notice Set buy back slippage
    /// @param _slippage Burn swap slippage to 2 d.p. e.g. 0.25% -> 25
    function setBuyBackSlippage(uint _slippage) external onlyOwner {
        require(_slippage <= MAX_SLIPPAGE, "AutomateStablzFeeHandler: _slippage cannot exceed the maximum slippage");
        slippage = _slippage;
        emit BuyBackSlippageUpdated(_slippage);
    }

    function _performUpkeep(bytes calldata _performData) internal override {
        (uint minimumAmount) = abi.decode(_performData, (uint));
        feeHandler.processFee(minimumAmount);
    }

    function _checkUpkeep(bytes calldata) internal view override returns (bool upkeepNeeded, bytes memory performData) {
        if (feeHandler.oracle() == address(this) && feeHandler.isBalanceAboveThreshold()) {
            uint minimumAmount;
            (uint buyBackAmount,,) = feeHandler.getFeeAmounts();
            if (buyBackAmount > 0) {
                address uniswapPair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(feeHandler.stablz(), feeHandler.usdt());
                require(address(uniswapPair) != address(0), "AutomateStablzFeeHandler: Pair not found");
                IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
                (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
                uint usdtReserve = pair.token0() == feeHandler.usdt() ? reserve0 : reserve1;
                uint stablzReserve = pair.token0() == feeHandler.stablz() ? reserve0 : reserve1;
                IUniswapV2Router02 router = IUniswapV2Router02(feeHandler.router());
                uint amountOut = router.getAmountOut(buyBackAmount, usdtReserve, stablzReserve);
                minimumAmount = amountOut - (amountOut * slippage / SLIPPAGE_DENOMINATOR);
            }
            upkeepNeeded = true;
            performData = abi.encode(minimumAmount);
        }
        return (upkeepNeeded, performData);
    }
}