// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";
import "Operator.sol";
import "Withdrawable.sol";
import "Beneficiary.sol";
import "SafeMath.sol";
import "SafeERC20.sol";

import "IERC20.sol";
import "IOriginVault.sol";
import "ICurveSwap.sol";
import "IWETH.sol";


contract OriginEthStrategy is Ownable, Operator, Beneficiary, Withdrawable{
    using SafeERC20 for IERC20;

    // Curve Pools info swap
    struct CurveSwapInfo{
        address pool;
        int256 baseId;
        int256 assetId;
        bool isFactory;
    }

    // Asset to Base Swap
    mapping (address => CurveSwapInfo) toBaseSwapMap;

    // Deposit Event
    event Deposited(uint256 amount);
    // Withdraw Event
    event Withdrawn(uint256 amount, uint256 baseTrueOut, int256 profit);
    
    // Bank address
    address public bank;
    // Origin Protocol Vault with strategies
    address public originVault;
    // deposited assets in Origin Vault
    uint256 public depositedBase = 0;
    // Version
    string public version = '1.00';
    // profit of rewards in base token currency
    int256 public totalProfit = 0;
    // Base coin, rewards will convert to this token
    address public baseToken = WETH;
    // precition for calculating rewards
    uint256 public precition = 1e12;

    // addresses helpers
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant ORIGIN_VAULT = 0x39254033945AA2E4809Cc2977E7087BEE48bd7Ab;
    address internal constant OETH = 0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3;
    address[] internal REDEEM_TOKENS = [0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84, 0x5E8422345238F34275888049021821E8E08CAa1f, 0xae78736Cd615f374D3085123A210448E74Fc6393];

    constructor(address bank_){
        bank = bank_;
        toBaseSwapMap[0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3] = CurveSwapInfo(0x94B17476A93b3262d87B9a326965D1E91f9c13E7, 0, 1, false);
        toBaseSwapMap[0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84] = CurveSwapInfo(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022, 0, 1, false);
        toBaseSwapMap[0x5E8422345238F34275888049021821E8E08CAa1f] = CurveSwapInfo(0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577, 0, 1, false);
        toBaseSwapMap[0xae78736Cd615f374D3085123A210448E74Fc6393] = CurveSwapInfo(0x0f3159811670c117c372428D4E69AC32325e4D0F, 0, 1, true);
    }

    /**
     * @dev set bank for getting assets
     * 
     * @param bank_ - bank address
     */
    function setBank(address bank_) external onlyBeneficiary{
        bank = bank_;
    }

    /*
        Strategy Stuff
    */
    
    /**
    * @dev Returns balance of the contract at baseToken.
    */
    function getBaseTokenBalance() view public returns(uint256){
        return IERC20(baseToken).balanceOf(address(this));
    }

    /**
    * @dev returns balance of OETH
    */
    function getStrategyTokenBalance() view public returns(uint256){
        return IERC20(OETH).balanceOf(address(this));
    }

    /**
    * @dev returns potential rewards at the current moment 
    *      if operator will withdraw all assets from strategy
    */
    function getPotentialRewards() view public returns(int256){
        return getPotentialRewards(depositedBase);
    }

    /**
    * @dev returns potential rewards at the current moment for specific amount 
    *      if operator will withdraw all assets from strategy
    *
    * @param baseAmountOut - amount of base token
    */
    function getPotentialRewards(uint256 baseAmountOut) view public returns(int256){
        uint256 strategyTokenIn = _calcStrategyTokenWithdraw(baseAmountOut);
        uint256 baseTrueOut = _calcSwapToBase(strategyTokenIn, OETH);
        return int256(baseTrueOut)- int256(baseAmountOut);
    }
    
    /**
     * @dev depositng base token from bank to this smart-contract
     *
     * @param baseAmount - amount that depositing to strategy
     * @param isSafeTransfer - turn on safe transfer
     */
    function depositFromBank(uint256 baseAmount, bool isSafeTransfer) public onlyOperator{
        uint256 allowance = IERC20(baseToken).allowance(bank, address(this));
        require(allowance >= baseAmount, "depositToStrategy: allowance less than baseAmount");
        require(IERC20(baseToken).balanceOf(bank) >= baseAmount, "depositToStrategy: balance less than baseAmount");
        
        if (isSafeTransfer){
            IERC20(baseToken).safeTransferFrom(bank, address(this), baseAmount);
        }
        else{
            IERC20(baseToken).transferFrom(bank, address(this), baseAmount);
        }
    }

    /**
     * @dev withdrawing base token back to bank
     *
     * @param baseAmount - amount that withdrawing to bank
     */
    function withdrawToBank(uint256 baseAmount) public onlyOperator{
        require(getBaseTokenBalance() >= baseAmount, "depositToStrategy: balance less than baseAmount");

        IERC20(baseToken).transfer(bank, baseAmount);
    }
    
    /**
     * @dev mint OETH and run Origin ETH Strategy
     *
     * @param baseAmount - amount that withdrawing to bank
     */
    function runStrategy(uint256 baseAmount) public onlyOperator{
        require(getBaseTokenBalance() >= baseAmount, "runStrategy: balance less than baseAmount");

        IERC20(WETH).approve(ORIGIN_VAULT, baseAmount);
        IOriginVault(ORIGIN_VAULT).mint(baseToken, baseAmount, 0);
        depositedBase += baseAmount;
        
        emit Deposited(baseAmount);
    }

    /**
     * @dev withdrawing base token from strategy
     * 
     * @param baseAmount - amount of base token
    */
    function withdrawFromStrategy(uint256 baseAmount, bool isRedeem) public onlyOperator{
        require(baseAmount <= depositedBase, "withdrawFromStrategy: baseAmount greather than deposited assets");
        uint256 baseTrueOut = 0;
        int currentProfit = 0;
        if (isRedeem){
            (baseTrueOut,currentProfit) = _withdrawViaVault(baseAmount);
        }
        else{
            (baseTrueOut,currentProfit) = _withdrawViaSwap(baseAmount);
        }
        
        emit Withdrawn(baseAmount, baseTrueOut, currentProfit);
    }

    /**
     * @dev withdrawing all amount of base asset from strategy
     */
    function withdrawFromStrategyAll(bool isRedeem) virtual public onlyOperator{
        withdrawFromStrategy(depositedBase, isRedeem);
    }

    /**
     * @dev calculate percent part of amount
     * 
     * @param all - the amount of which the percentage is calculated
     * @param part - part of which the percentage is calculated
    */
    function _calcPercentOf(uint256 all, uint256 part) private view returns (uint256) {
        return part * precition / all;
    }

    /**
     * @dev calculate value of part by percent
     * 
     * @param all - amount of which interest is calculated
     * @param percent - percent of part
    */
    function _getPercentOf(uint256 all, uint256 percent) private view returns(uint256) {
        return (all * percent) / precition;
    }

    /**
     * @dev calculate amount withdraw of Strategy Token by amount of base token 
     * 
     * @param baseAmountOut - amount of base token
    */
    function _calcStrategyTokenWithdraw(uint256 baseAmountOut) private view returns (uint256){
        uint256 percent = _calcPercentOf(depositedBase, baseAmountOut);
        return _getPercentOf(getStrategyTokenBalance(), percent);
    }

    /**
     * @dev get out amount of base asset after swap at Curve Protocol
     *
     * @param assetAmount - in amount for swap
     * @param asset - amount of asset
     */
    function _calcSwapToBase(uint256 assetAmount, address asset) private view returns(uint256){
        CurveSwapInfo memory swapInfo = toBaseSwapMap[asset];
        if (swapInfo.isFactory){
            return ICurveSwap(swapInfo.pool).get_dy(uint256(swapInfo.assetId), uint256(swapInfo.baseId), assetAmount);
        }
        else{
            return ICurveSwap(swapInfo.pool).get_dy(int128(swapInfo.assetId), int128(swapInfo.baseId), assetAmount);
        }
    }

    /**
     * @dev - withdraw via origin vault
     *
     * @param baseAmount - base token amount   
     */
    function _withdrawViaVault(uint256 baseAmount) private returns(uint256, int256){
        uint256 strategyTokenIn = _calcStrategyTokenWithdraw(baseAmount);
        uint256 baseTrueOut = getBaseTokenBalance();
        uint256[3] memory redeemTokensAmounts = _redeem(strategyTokenIn);

        baseTrueOut = getBaseTokenBalance() - baseTrueOut;
        for(uint i = 0; i < REDEEM_TOKENS.length; i++){
            baseTrueOut +=_swapToBase(redeemTokensAmounts[i], REDEEM_TOKENS[i]);
        }

        int256 currentProfit = int256(baseTrueOut)- int256(baseAmount);
        totalProfit += currentProfit;
        depositedBase -= baseAmount;
        return (baseTrueOut, currentProfit);
    }


    /**
     * @dev - redeem using origin vault and returns amounts of redeemed tokens
     *
     * @param oethAmount - base token amount   
     */
    function _redeem(uint256 oethAmount) private returns(uint256[3] memory){
        uint[3] memory balances;
        for (uint i = 0; i < REDEEM_TOKENS.length; i++){
            balances[i] = IERC20(REDEEM_TOKENS[i]).balanceOf(address(this));
        }
        IOriginVault(ORIGIN_VAULT).redeem(oethAmount, 0);
        for (uint i = 0; i < REDEEM_TOKENS.length; i++){
            balances[i] = IERC20(REDEEM_TOKENS[i]).balanceOf(address(this)) - balances[i];
        }
        return balances;
    }

    /**
     * @dev withdraw from strategy via curve swap
     * 
     * @param baseAmount - base token amount
     */
    function _withdrawViaSwap(uint256 baseAmount) private returns(uint256, int256){
        uint256 strategyTokenIn = _calcStrategyTokenWithdraw(baseAmount);
        uint256 baseTrueOut = _swapToBase(strategyTokenIn, OETH);
        int256 currentProfit = int256(baseTrueOut)- int256(baseAmount);

        totalProfit += currentProfit;
        depositedBase -= baseAmount;
        return (baseTrueOut, currentProfit);
    }

    /**
    * @dev swap strategy asset to baseToken via Curve Protocol 
    *
    * @param assetAmount - in amount for swap
    * @param asset - asset address
    */
    function _swapToBase(uint256 assetAmount, address asset) private returns(uint256) {
        CurveSwapInfo memory swapInfo = toBaseSwapMap[asset];
        uint256 balanceBefore = getBaseTokenBalance();
        IERC20(asset).approve(swapInfo.pool, assetAmount);  
        if (swapInfo.isFactory){
            ICurveSwap(swapInfo.pool).exchange(uint256(swapInfo.assetId), uint256(swapInfo.baseId), assetAmount, 0, false, address(this));
        }
        else{
            ICurveSwap(swapInfo.pool).exchange(int128(swapInfo.assetId), int128(swapInfo.baseId), assetAmount, 0);
            IWETH(WETH).deposit{value: address(this).balance}();
        }
        return getBaseTokenBalance() - balanceBefore;
    }

    receive() external payable {}
}