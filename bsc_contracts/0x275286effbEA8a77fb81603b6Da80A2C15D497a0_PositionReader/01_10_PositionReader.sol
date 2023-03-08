// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultUtils.sol";
import "../core/interfaces/IVaultPriceFeedV2.sol";
import "../core/interfaces/IBasePositionManager.sol";

interface IVaultTarget {
    function vaultUtils() external view returns (address);
}

struct DispPosition {
    address account;
    address collateralToken;
    address indexToken;
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 reserveAmount;
    uint256 lastUpdateTime;
    uint256 aveIncreaseTime;

    uint256 entryFundingRateSec;
    int256 entryPremiumRateSec;

    int256 realisedPnl;

    uint256 stopLossRatio;
    uint256 takeProfitRatio;

    bool isLong;

    bytes32 key;
    uint256 delta;
    bool hasProfit;

    int256 accPremiumFee;
    uint256 accFundingFee;
    uint256 accPositionFee;
    uint256 accCollateral;

    int256 pendingPremiumFee;
    uint256 pendingPositionFee;
    uint256 pendingFundingFee;

    uint256 indexTokenMinPrice;
    uint256 indexTokenMaxPrice;
}


struct DispToken {
    address token;

    //tokenBase part
    bool isFundable;
    bool isStable;
    uint256 decimal;
    uint256 weight;         
    uint256 maxUSDAmounts;  // maxUSDAmounts allows setting a max amount of USDX debt for a token
    uint256 balance;        // tokenBalances is used only to determine _transferIn values
    uint256 poolAmount;     // poolAmounts tracks the number of received tokens that can be used for leverage
    uint256 poolSize;
    uint256 reservedAmount; // reservedAmounts tracks the number of tokens reserved for open leverage positions
    uint256 bufferAmount;   // bufferAmounts allows specification of an amount to exclude from swaps
                            // this can be used to ensure a certain amount of liquidity is available for leverage positions
    uint256 guaranteedUsd;  // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions

    //trec part
    uint256 shortSize;
    uint256 shortCollateral;
    uint256 shortAveragePrice;
    uint256 longSize;
    uint256 longCollateral;
    uint256 longAveragePrice;

    //fee part
    uint256 fundingRatePerSec; //borrow fee & token util
    uint256 fundingRatePerHour; //borrow fee & token util
    uint256 accumulativefundingRateSec;

    int256 longRatePerSec;  //according to position
    int256 shortRatePerSec; //according to position
    int256 longRatePerHour;  //according to position
    int256 shortRatePerHour; //according to position

    int256 accumulativeLongRateSec;
    int256 accumulativeShortRateSec;
    uint256 latestUpdateTime;

    //limit part
    uint256 maxShortSize;
    uint256 maxLongSize;
    uint256 maxTradingSize;
    uint256 maxRatio;
    uint256 countMinSize;

    //
    uint256 spreadBasis;
    uint256 maxSpreadBasis;// = 5000000 * PRICE_PRECISION;
    uint256 minSpreadCalUSD;// = 10000 * PRICE_PRECISION;

}

struct GlobalFeeSetting{
    uint256 taxBasisPoints; // 0.5%
    uint256 stableTaxBasisPoints; // 0.2%
    uint256 mintBurnFeeBasisPoints; // 0.3%
    uint256 swapFeeBasisPoints; // 0.3%
    uint256 stableSwapFeeBasisPoints; // 0.04%
    uint256 marginFeeBasisPoints; // 0.1%
    uint256 liquidationFeeUsd;
    uint256 maxLeverage; // 100x
    //Fees related to funding
    uint256 fundingRateFactor;
    uint256 stableFundingRateFactor;
    //trading tax part
    uint256 taxGradient;
    uint256 taxDuration;
    uint256 taxMax;
    //trading profit limitation part
    uint256 maxProfitRatio;
    uint256 premiumBasisPointsPerHour;
    int256 posIndexMaxPointsPerHour;
    int256 negIndexMaxPointsPerHour;
}


contract PositionReader is Ownable{
    using SafeMath for uint256;
    address public nativeToken;

    mapping(address => address[]) private fundingTokens;
    mapping(address => address[]) private tradingTokens;


    constructor(address _nativeToken) {
        nativeToken = _nativeToken;
    }

    function setokens(address _vault, address[] memory _fTokens, address[] memory _tTokens) external onlyOwner{
        fundingTokens[_vault] = _fTokens;//stable only
        tradingTokens[_vault] = _tTokens;
    }

    function getPosition(address _vault, address _account, address colToken, address idxToken, bool isLong) public view returns (DispPosition memory) {
        IVaultUtils  vaultUtils = IVaultUtils(IVaultTarget(_vault).vaultUtils());
        DispPosition memory dPos;
        uint256 entryFundingRate;
        {
            uint256 realisedPnl_uint;
            bool hasRealisedProfit;
            (dPos.size,
            dPos.collateral,
            dPos.averagePrice,
            entryFundingRate,
            dPos.reserveAmount,
            realisedPnl_uint,
            hasRealisedProfit,
            dPos.aveIncreaseTime) = IVault(_vault).getPosition(_account, colToken, idxToken, isLong);
            dPos.realisedPnl = hasRealisedProfit ? int256(realisedPnl_uint) : -int256(realisedPnl_uint);
        }
        if (dPos.size < 1 ||dPos.averagePrice < 1 ) return dPos;

        dPos.account = _account;
        dPos.collateralToken = colToken;
        dPos.indexToken = idxToken;
        dPos.isLong = isLong;
        dPos.lastUpdateTime = dPos.aveIncreaseTime;
        // dPos.key = dPos.aveIncreaseTime;
        dPos.entryFundingRateSec = entryFundingRate.mul(1e10).div(3600).div(1e6);
        (dPos.hasProfit , dPos.delta) = IVault(_vault).getDelta(idxToken, dPos.size, dPos.averagePrice, isLong, dPos.lastUpdateTime);

        dPos.pendingPositionFee = vaultUtils.getPositionFee(dPos.account,dPos.collateralToken, dPos.indexToken, dPos.isLong, dPos.size);
        dPos.pendingFundingFee = vaultUtils.getFundingFee(dPos.account, dPos.collateralToken, dPos.indexToken, dPos.isLong, dPos.size, entryFundingRate);

        return dPos;
    }
    



    
    function getUserPositions(address _vault, address _account) external view returns (DispPosition[] memory){
        DispPosition[] memory _dps = new DispPosition[](tradingTokens[_vault].length * (fundingTokens[_vault].length + 1));
        if (tradingTokens[_vault].length == 0) return _dps;
        uint256 accum_i = 0;
        uint256 accum_k = 0;
        for(uint256 i = 0; i < tradingTokens[_vault].length; i++){
            _dps[accum_i] = getPosition(_vault, _account, tradingTokens[_vault][i], tradingTokens[_vault][i], true);
            if (_dps[accum_i].size > 0)
                accum_k += 1;
            accum_i = accum_i.add(1);
            for(uint256 j = 0; j < fundingTokens[_vault].length; j++){
                _dps[accum_i] = getPosition(_vault, _account, fundingTokens[_vault][j], tradingTokens[_vault][i], false);
                if (_dps[accum_i].size > 0)
                    accum_k += 1;
                accum_i = accum_i.add(1);            }
        }
        DispPosition[] memory _dpsK = new DispPosition[](accum_k);
        uint256 accum_ki = 0;

        for(uint256 i = 0; i < _dps.length; i++){
            if (_dps[i].size < 1)
                continue;
            _dpsK[accum_ki]=_dps[i];
            accum_ki += 1;
        }
        return _dpsK;
    }



    function getTokenInfo(address _vault, address[] memory _fundTokens) external view returns (DispToken[] memory) {
        IVaultUtils  vaultUtils = IVaultUtils(IVaultTarget(_vault).vaultUtils());
        DispToken[] memory _dispT = new DispToken[](_fundTokens.length);
        IVault vault = IVault(_vault);
        for(uint256 i = 0; i < _dispT.length; i++){
            if (_fundTokens[i] == address(0))
                _fundTokens[i] = nativeToken;

            _dispT[i].token = _fundTokens[i];
            _dispT[i].weight = vault.tokenWeights(_fundTokens[i]);  
            _dispT[i].maxUSDAmounts =vault.maxUSDAmounts(_fundTokens[i]);
            _dispT[i].balance = vault.tokenBalances(_fundTokens[i]);
            _dispT[i].poolAmount = vault.poolAmounts(_fundTokens[i]);

            _dispT[i].reservedAmount = vault.reservedAmounts(_fundTokens[i]);
            _dispT[i].bufferAmount = vault.bufferAmounts(_fundTokens[i]);  
            _dispT[i].guaranteedUsd = IVault(_vault).guaranteedUsd(_fundTokens[i]);  

            _dispT[i].poolSize = vault.tokenToUsdMin(_fundTokens[i], _dispT[i].poolAmount);

            //fee part
            _dispT[i].fundingRatePerHour = vault.getNextFundingRate(_fundTokens[i]);  
            _dispT[i].fundingRatePerSec = _dispT[i].fundingRatePerHour.mul(1e10).div(3600).div(1e6);
    
        }
        return _dispT;
    }



/*
    function getGlobalFeeInfo(address _vault) external view returns (GlobalFeeSetting memory){//Fees related to swap
        GlobalFeeSetting memory gFS;
        IVaultUtils  vaultUtils = IVaultUtils(IVaultTarget(_vault).vaultUtils());
        gFS.taxBasisPoints = vaultUtils.taxBasisPoints();

        gFS.stableTaxBasisPoints = vaultUtils.stableTaxBasisPoints();
        gFS.mintBurnFeeBasisPoints = vaultUtils.mintBurnFeeBasisPoints();
        gFS.swapFeeBasisPoints = vaultUtils.swapFeeBasisPoints();
        gFS.stableSwapFeeBasisPoints = vaultUtils.stableSwapFeeBasisPoints();

        gFS.marginFeeBasisPoints = vaultUtils.marginFeeBasisPoints();
        gFS.liquidationFeeUsd = vaultUtils.liquidationFeeUsd();
        gFS.maxLeverage = vaultUtils.maxLeverage();
        gFS.fundingRateFactor = vaultUtils.fundingRateFactor();
        gFS.stableFundingRateFactor = vaultUtils.stableFundingRateFactor();
        gFS.taxGradient = vaultUtils.taxGradient();
        gFS.taxDuration = vaultUtils.taxDuration();

        gFS.taxMax = vaultUtils.taxMax();
        gFS.maxProfitRatio = vaultUtils.maxProfitRatio();
        gFS.premiumBasisPointsPerHour = vaultUtils.premiumBasisPointsPerHour();
        gFS.posIndexMaxPointsPerHour = vaultUtils.posIndexMaxPointsPerHour();
        gFS.negIndexMaxPointsPerHour = vaultUtils.negIndexMaxPointsPerHour();
        return gFS;
    }
*/
}