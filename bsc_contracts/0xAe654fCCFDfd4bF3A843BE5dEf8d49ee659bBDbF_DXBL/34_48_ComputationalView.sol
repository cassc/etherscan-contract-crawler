//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../VaultStorage.sol";
import "../interfaces/IComputationalView.sol";
import "../../common/LibConstants.sol";
//import "hardhat/console.sol";

contract ComputationalView is IComputationalView {

    function convertGasToFeeToken(address feeToken, uint gasCost) public view returns (uint){
        VaultStorage.VaultData storage rs = VaultStorage.load();
        require(address(rs.allowedFeeTokens[feeToken].feed) != address(0), "Unsupported fee token");

        if(feeToken == rs.wrappedNativeToken) {
            //already in native units
            return gasCost;
        }
        uint np = _getPrice(rs.allowedFeeTokens[rs.wrappedNativeToken]);
        uint ftp = _getPrice(rs.allowedFeeTokens[feeToken]);
        uint ftpNative = (np*LibConstants.PRICE_PRECISION)/ftp;
        uint ftpUnits = (ftpNative * gasCost) / LibConstants.PRICE_PRECISION;
        return (ftpUnits * (10**rs.tokenDecimals[feeToken])) / 1e18; //native is always 18decs
    }

    function estimateRedemption(address rewardToken, uint dxblAmount) public view returns(uint){
        VaultStorage.VaultData storage rs =VaultStorage.load();
        uint nav = currentNavUSD();
         //convert nav to price-precision units
        nav = (nav * LibConstants.PRICE_PRECISION) / LibConstants.USD_PRECISION;
        
        //we need to know the value of each token in rewardToken units
        //start by getting the USD price of reward token
        uint ftUSD = feeTokenPriceUSD(rewardToken);

        uint8 ftDecs = rs.tokenDecimals[rewardToken];

        //Divide nav of each token by the price of each reward token expanding 
        //precision to include the fee-token decimals
        uint ftUnitPrice = (nav*(10**ftDecs))/ftUSD;

        //compute how much rewardToken to withdraw based on unit price of each DXBL
        //in fee-token units. Have to remove the dexible token precision (18)
        return (dxblAmount * ftUnitPrice)/1e18;
    }

    function feeTokenPriceUSD(address feeToken) public view returns (uint){
        VaultStorage.VaultData storage rs = VaultStorage.load();
        VaultStorage.PriceFeed storage pf = rs.allowedFeeTokens[feeToken];
        require(address(pf.feed) != address(0), "Unsupported fee token");
        return _getPrice(pf);
    }

    function computeVolumeUSD(address feeToken, uint amount) public view returns(uint volumeUSD) {
        VaultStorage.VaultData storage fs = VaultStorage.load();
        VaultStorage.PriceFeed storage pf = fs.allowedFeeTokens[feeToken];

        //price is in USD with 30decimal precision
        uint ftp = _getPrice(pf);

        (uint v,) = _toUSD(fs, IERC20(feeToken), ftp, amount);
        volumeUSD = v;
    }

    function aumUSD() public view returns(uint usd){
        VaultStorage.VaultData storage fs = VaultStorage.load();

        //for each fee token allowed in the vault
        //move to memory so we're not accessing storage in loop
        IERC20[] memory feeTokens = fs.feeTokens;
        for(uint i=0;i<feeTokens.length;++i) {
            IERC20 ft = IERC20(feeTokens[i]);
            VaultStorage.PriceFeed storage pf = fs.allowedFeeTokens[address(ft)];
            
            //make sure fee token still active
            //get the price of the asset
            uint price = _getPrice(pf);
            //use it to compute USD value
            (uint _usd,) = _toUSD(fs, ft, price, 0);
            usd += _usd;
        }
    }

    function currentNavUSD() public view returns(uint nav){
        //console.log("--------------- START COMPUTE NAV ---------------------");
        VaultStorage.VaultData storage rs = VaultStorage.load();

        //get the total supply of dxbl tokens
        uint supply = rs.dxbl.totalSupply();

        //get the total USD under management by this vault
        uint aum = aumUSD();

        //if either is 0, the nav is 0
        if(supply == 0 || aum == 0) {
            return 0;
        }
         
        //supply is 18decs while aum and nav are expressed in USD units
        nav = (aum*1e18) / supply;
        //console.log("--------------- END COMPUTE NAV ---------------------");
    }

    function assets() public view returns (IComputationalView.AssetInfo[] memory tokens){
        /**
         * RISK: Must limit the fee token count to avoid miner not allowing call due to high
         * gas usage
         */
        VaultStorage.VaultData storage fs = VaultStorage.load();

        //create in-memory structure only for active fee tokens
        tokens = new IComputationalView.AssetInfo[](fs.feeTokens.length);

        //count offset of return tokens
        uint cnt = 0;
        
        //copy fee tokens in memory to we're not accessing storage in loop
        IERC20[] memory feeTokens = fs.feeTokens;
        for(uint i=0;i<feeTokens.length;++i) {
            IERC20 ft = feeTokens[i];
            VaultStorage.PriceFeed storage pf = fs.allowedFeeTokens[address(ft)];

            //lookup USD price of asset in 30-dec units
            uint price = _getPrice(pf);

            //convert to total usd-precision USD value
            (uint usd, uint bal) = _toUSD(fs, ft, price, 0);

            tokens[cnt] = IComputationalView.AssetInfo({
                token: address(ft),
                balance: bal,
                usdValue: usd,
                usdPrice: (price*LibConstants.USD_PRECISION) / LibConstants.PRICE_PRECISION
            });
            ++cnt;
        }
    }

    function currentMintRateUSD() public view returns (uint rate){
        /**
        * formula for mint rate:
        * startingRate+(startingRate*(ratePerMM*MM_vol))
        */
        VaultStorage.VaultData storage rs = VaultStorage.load();

        uint16 normalizedMMInVolume = uint16(rs.currentVolume / LibConstants.MM_VOLUME);

        //mint rate is a bucket with min/max volume thresholds and establishes how many 
        //percentage points per million to apply to the starting mint rate 
        uint percIncrease = rs.currentMintRate.rate * normalizedMMInVolume;

        //mint rate percentage is expressed in 18-dec units so have to divide that out before adding to base
        rate = rs.baseMintThreshold + ((rs.baseMintThreshold * percIncrease)/1e18);
    }


    function _getPrice(VaultStorage.PriceFeed storage pf) internal view returns (uint) {
        //get latest price
        (   ,
            int256 answer,
            ,
            uint256 updatedAt,
        ) = pf.feed.latestRoundData();

        //make sure price valid
        require(answer > 0, "No price data available");

        //make sure prices have been updated in last 48hrs
        uint stale = block.timestamp - (LibConstants.DAY*2);
        require(updatedAt > stale, "Stale price data");
        return (uint256(answer) * LibConstants.PRICE_PRECISION) / (10**pf.decimals);
    }

    /**
     * Convert an assets total balance to USD
     */
    function _toUSD(VaultStorage.VaultData storage fs, IERC20 token, uint price, uint amt) internal view returns(uint usd, uint bal) {
        bal = amt;
        if(bal == 0) {
            bal = token.balanceOf(address(this));
        }
        
        //compute usd in raw form (fee-token units + price-precision units) but account for
        //USD precision
        usd = (bal * price)*LibConstants.USD_PRECISION;

        //then divide out the fee token and price-precision units
        usd /= (10**fs.tokenDecimals[address(token)]*LibConstants.PRICE_PRECISION);
        
    }
}