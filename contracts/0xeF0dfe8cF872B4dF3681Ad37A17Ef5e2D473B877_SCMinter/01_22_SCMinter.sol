// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "StableSwapGuard.sol";
import "GeminonInfrastructure.sol";
import "VariableFees.sol";

import "IGeminonOracle.sol";
import "IGenesisLiquidityPool.sol";

import "IERC20Indexed.sol";
import "TradePausable.sol";


/**
* @title SCMinter
* @author Geminon Protocol
* @notice Allows users to mint and redeem stablecoins using GEX tokens and swap stablecoins.
*/
contract SCMinter is Ownable, TradePausable, GeminonInfrastructure, StableSwapGuard, VariableFees {
    
    address public immutable USDI;
    
    uint32 public baseMintFee;
    uint32 public baseRedeemFee;
    
    address[] public stablecoins;
    
    mapping(address => bool) public validTokens;
    mapping(address => bool) public mintedTokens;
    mapping(address => uint32) public baseSwapFees;
    

    /// @dev Checks if token is a valid mintable token
    modifier onlyValidTokens(address token) {
        require(validTokens[token], 'Invalid token');
        _;
    }

    /// @dev Checks if token is a valid redeemable token
    modifier onlyMintedTokens(address token) {
        require(mintedTokens[token], 'Token not minted');
        _;
    }


    constructor(address gex, address usdi, address oracle) {
        GEX = gex;
        USDI = usdi;
        
        oracleGeminon = oracle;
        oracleAge = uint64(block.timestamp);

        baseMintFee = 1000;
        baseRedeemFee = 2000;
        
        stablecoins.push(usdi);
        validTokens[usdi] = true;
        mintedTokens[usdi] = true;
        baseSwapFees[usdi] = 3000;
    }
    
    
    
    /// @dev Adds stablecoin to the list of valid tokens
    function addStablecoin(address token, uint32 swapFee) external onlyOwner {
        require(token != address(0)); // dev: Address 0
        stablecoins.push(token);
        validTokens[token] = true;
        mintedTokens[token] = true;
        setSwapFee(token, swapFee);
    }

    /// @dev Removes stablecoin from the list of valid tokens
    /// @notice Stablecoins can't be removed from the list of minted tokens
    /// to protect users: they can always be redeem once created.
    function removeStablecoin(address token) external onlyOwner onlyValidTokens(token) {
        require(token != USDI); // dev: Cant remove USDI
        validTokens[token] = false;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                       PARAMETERS CHANGES                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Changes the value of the base mint fee
    /// Max allowed value is 0.5% 
    function setMintFee(uint32 value) external onlyOwner {
        require(value <= 5000); // dev: Max mint fee
        baseMintFee = value;
    }

    /// @dev Changes the value of the base redeem fee
    /// Max allowed value is 0.6%
    function setRedeemFee(uint32 value) external onlyOwner {
        require(value <= 6000); // dev: Max redeem fee
        baseRedeemFee = value;
    }

    /// @dev Changes the value of the base swap fee of the stablecoin
    /// Max allowed value is 1.2%
    function setSwapFee(address stable, uint32 value) public onlyOwner onlyValidTokens(stable) {
        require(value <= 12000); // dev: Max swap fee
        require(value >= baseMintFee + baseRedeemFee); // dev: Low swap fee
        baseSwapFees[stable] = value;
    }
    
    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          USER FUNCTIONS                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Mints a stablecoin from the list of valid tokens using GEX as payment
    function mintStablecoin(address stablecoin, uint256 amountInGEX) 
        external 
        whenMintNotPaused 
        onlyValidTokens(stablecoin) 
        returns(uint256)
    {    
        uint256 amountOutStablecoin;

        uint256 usdPrice = IERC20Indexed(stablecoin).getOrUpdatePegValue();

        if (stablecoin == USDI || usdPrice == 1e18) {
            uint256 amountFeeGEX_ = amountFeeGEX(amountInGEX, baseMintFee);
            amountOutStablecoin = amountMint(stablecoin, amountInGEX - amountFeeGEX_);
        } else {
            amountOutStablecoin = amountMint(stablecoin, amountInGEX);
            _updatePriceRecord(stablecoin, usdPrice, amountOutStablecoin, true);
            amountOutStablecoin -= amountFeeMint(stablecoin, amountOutStablecoin, usdPrice);
        }
        
        if (amountOutStablecoin > IERC20Indexed(stablecoin).balanceOf(address(this)) / 10)
            _addReserves(amountOutStablecoin, stablecoin);

        _balanceFees += (amountInGEX * baseMintFee) / 1e6;
        
        IERC20(GEX).transferFrom(msg.sender, address(this), amountInGEX);
        IERC20(stablecoin).transfer(msg.sender, amountOutStablecoin);

        return amountOutStablecoin;
    }

    
    /// @notice Redeems a stablecoin from the list of minted tokens receiving GEX in exchange
    function redeemStablecoin(address stablecoin, uint256 amountInStablecoin) 
        external 
        onlyMintedTokens(stablecoin) 
        returns(uint256) 
    {
        uint256 amountFeeGEX_;
        
        uint256 usdPrice = IERC20Indexed(stablecoin).getOrUpdatePegValue();
        
        uint256 amountOutGEX = amountRedeem(stablecoin, amountInStablecoin);
        if (stablecoin == USDI || usdPrice == 1e18) {
            amountFeeGEX_ = amountFeeGEX(amountOutGEX, baseRedeemFee);
        } else {
            _updatePriceRecord(stablecoin, usdPrice, amountInStablecoin, false);
            uint256 amountFeeStablecoin = amountFeeRedeem(stablecoin, amountInStablecoin, usdPrice);
            amountFeeGEX_ = amountRedeem(stablecoin, amountFeeStablecoin);
        }

        uint256 balanceGEX = IERC20(GEX).balanceOf(address(this)) - _balanceFees;
        if(amountOutGEX > balanceGEX) 
            _requestBailoutFromPool();
        require(amountOutGEX <= balanceGEX, "Amount too high");
        
        _balanceFees += (amountOutGEX * baseRedeemFee) / 1e6;
        
        amountOutGEX -= amountFeeGEX_;
        IERC20(stablecoin).transferFrom(msg.sender, address(this), amountInStablecoin);
        IERC20(GEX).transfer(msg.sender, amountOutGEX);

        return amountOutGEX;
    }


    /// @notice Swaps any pair of stablecoins without slippage. The fees generated go
    /// to the GEX holders.
    function stableSwap(address stableIn, address stableOut, uint256 amountIn) 
        external 
        whenMintNotPaused 
        onlyMintedTokens(stableIn) 
        onlyValidTokens(stableOut) 
        returns(uint256) 
    {
        uint256 usdPriceIn = IERC20Indexed(stableIn).getOrUpdatePegValue();
        uint256 usdPriceOut = IERC20Indexed(stableOut).getOrUpdatePegValue();

        uint256 amountOutStable = (amountIn * usdPriceIn) / usdPriceOut;

        if (stableIn != USDI && usdPriceIn != 1e18) 
            _updatePriceRecord(stableIn, usdPriceIn, amountIn, false);
        if (stableOut != USDI && usdPriceOut != 1e18) 
            _updatePriceRecord(stableOut, usdPriceOut, amountOutStable, true);

        amountOutStable -= amountFeeSwap(
            stableIn, 
            stableOut, 
            usdPriceIn, 
            usdPriceOut, 
            amountOutStable
        );
        
        if (amountOutStable > IERC20Indexed(stableOut).balanceOf(address(this)) / 10)
            _addReserves(amountOutStable, stableOut);
        
        IERC20(stableIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(stableOut).transfer(msg.sender, amountOutStable);

        return amountOutStable;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                        PROTOCOL FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Pauses stablecoins mint. Redeems can not be paused.
    function pauseMint() external onlyOwner whenMintNotPaused {
        _pauseMint();
    }

    /// @dev Unpauses stablecoins mint. Can not unpause if migration has 
    /// been requested as those actions pause the minter as security measure.
    function unpauseMint() external onlyOwner whenMintPaused {
        require(!isMigrationRequested); // dev: migration requested
        _unpauseMint();
    }

    
    /// @dev Mints new supply of GEX to this contract
    function addReservesGEX(uint256 amount) external onlyOwner {
        IERC20Indexed(GEX).mint(address(this), amount);
    }

    /// @dev Mints stablecoins to this contract
    function addReserves(uint256 amount, address stablecoin) external onlyOwner onlyValidTokens(stablecoin) {
        _addReserves(amount, stablecoin);
    }

    /// @dev Burns stablecoins from this contract
    function burnReserves(uint256 amount, address stablecoin) external onlyOwner onlyMintedTokens(stablecoin) {
        IERC20Indexed(stablecoin).burn(address(this), amount);
    }


    /// @notice Transfer GEX tokens from a Genesis Liquidity Pool
    function requestBailoutFromPool() external onlyOwner returns(uint256) {
        return _requestBailoutFromPool();
    }

    

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                     INFORMATIVE FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Gets the GEX balance
    function getBalanceGEX() external view returns(uint256) {
        return IERC20(GEX).balanceOf(address(this)) - _balanceFees;
    }

    /// @notice Calculates the Total Value Circulating of the Geminon stablecoins in this blockchain
    function getTVC() external view returns(uint256) {
        uint256 value = 0;
        for (uint16 i=0; i<stablecoins.length; i++) {
            address sc = stablecoins[i];
            uint256 circulating = IERC20(sc).totalSupply() - IERC20(sc).balanceOf(address(this));
            value += (circulating * IERC20Indexed(sc).getPegValue()) / 1e18;
        }
        return value;
    }


    /// @notice Calculates the amount of the mint/redeem fee given the amount of GEX
    function amountFeeGEX(uint256 amountGEX, uint256 baseFee) public view returns(uint256 fee) {
        return (amountGEX * feeGEX(amountGEX, baseFee)) / 1e6;
    }

    /// @notice Calculates the amount of the mint fee for a given stablecoin amount
    function amountFeeMint(address stable, uint256 amountStable, uint256 usdPrice) public view returns(uint256) {
        return (amountStable * _feeStablecoin(stable, amountStable, usdPrice, baseMintFee, true)) / 1e6;
    }

    /// @notice Calculates the amount of the redeem fee for a given stablecoin amount
    function amountFeeRedeem(address stable, uint256 amountStable, uint256 usdPrice) public view returns(uint256) {
        return (amountStable * _feeStablecoin(stable, amountStable, usdPrice, baseRedeemFee, false)) / 1e6;
    }

    /// @notice Calculates the amount of the stableswap fee
    function amountFeeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) public view returns(uint256) {
        return (amountOut * feeSwap(stableIn, stableOut, usdPriceIn, usdPriceOut, amountOut)) / 1e6;
    }
    
    
    /// @notice Calculate the percentage of the fee to mint a stablecoin given the amount of stablecoin
    function feeStablecoinMint(address stable, uint256 amountStable) public view returns(uint256) {
        uint256 amountEqUSDI = amountUSDI(stable, amountStable);
        uint256 usdPrice = IERC20Indexed(stable).getPegValue();
        return _feeStablecoin(stable, amountEqUSDI, usdPrice, baseMintFee, true);
    }

    /// @notice Calculate the percentage of the fee to redeem a stablecoin given the amount of stablecoin
    function feeStablecoinRedeem(address stable, uint256 amountStable) public view returns(uint256) {
        uint256 amountEqUSDI = amountUSDI(stable, amountStable);
        uint256 usdPrice = IERC20Indexed(stable).getPegValue();
        return _feeStablecoin(stable, amountEqUSDI, usdPrice, baseRedeemFee, false);
    }

    /// @notice Returns the equivalent amount of USDI of a given stablecoin amount
    function amountUSDI(address stablecoin, uint256 amount) public view returns(uint256) {
        return (amount * IERC20Indexed(stablecoin).getPegValue()) / IERC20Indexed(USDI).getPegValue();
    }

    /// @notice Gives all mintStablecoin info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee that has 6.
    function getMintInfo(uint256 inGEXAmount, address stablecoin) public view returns(
        uint256 gexPriceUSD,
        uint256 stablecoinPriceUSD, 
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    ) {
        gexPriceUSD = IGeminonOracle(oracleGeminon).getSafePrice();
        stablecoinPriceUSD = IERC20Indexed(stablecoin).getPegValue();
        fee = feeGEX(inGEXAmount, baseMintFee);
        feeAmount = (inGEXAmount * fee) / 1e6;
        outStablecoinAmount = amountMint(stablecoin, inGEXAmount - feeAmount);
    }

    /// @notice Gives all redeemStablecoin info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee that has 6.
    function getRedeemInfo(uint256 inStablecoinAmount, address stablecoin) public view returns(
        uint256 stablecoinPriceUSD, 
        uint256 gexPriceUSD,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount
    ) {
        stablecoinPriceUSD = IERC20Indexed(stablecoin).getPegValue();
        gexPriceUSD = IGeminonOracle(oracleGeminon).getSafePrice();
        fee = feeStablecoinRedeem(stablecoin, inStablecoinAmount);
        feeAmount = (inStablecoinAmount * fee) / 1e6;
        outGEXAmount = amountRedeem(stablecoin, inStablecoinAmount - feeAmount);
    }

    /// @notice Gives all stableSwap info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee that has 6.
    function getStableSwapInfo(uint256 inAmount, address stableIn, address stableOut) public view returns(
        uint256 inStablecoinPriceUSD,
        uint256 outStablecoinPriceUSD, 
        uint256 quoteS2S1,
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    ) {
        inStablecoinPriceUSD = IERC20Indexed(stableIn).getPegValue();
        outStablecoinPriceUSD = IERC20Indexed(stableOut).getPegValue();
        quoteS2S1 = (outStablecoinPriceUSD * 1e18) / inStablecoinPriceUSD;
        outStablecoinAmount = (inAmount * inStablecoinPriceUSD) / outStablecoinPriceUSD;
        fee = feeSwap(stableIn, stableOut, inStablecoinPriceUSD, outStablecoinPriceUSD, outStablecoinAmount);
        feeAmount = (outStablecoinAmount * fee) / 1e6;
        outStablecoinAmount -= feeAmount;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         CORE FUNCTIONS                             +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Calculates the amount ot stablecoin minted given a GEX amount
    function amountMint(address stablecoin, uint256 amountGEX) public view returns(uint256) {
        return (amountGEX * getSafeMintRatio(stablecoin)) / 1e18;
    }

    /// @dev Calculates the amount of GEX to redeem a given stablecoin and amount
    function amountRedeem(address stablecoin, uint256 amountStablecoin) public view returns(uint256) {
        return (amountStablecoin * getSafeRedeemRatio(stablecoin)) / 1e18;
    }
    
    /// @dev Calculates the quote of the GEX token on the given stablecoin
    function getSafeMintRatio(address stablecoin) public view returns(uint256) {
        uint256 priceGEX = IGeminonOracle(oracleGeminon).getSafePrice();
        uint256 priceIndex = IERC20Indexed(stablecoin).getPegValue();
        return (priceGEX * 1e18) / priceIndex;
    }

    /// @dev Calculates the quote of the given stablecoin on GEX tokens
    function getSafeRedeemRatio(address stablecoin) public view returns(uint256) {
        uint256 priceGEX = IGeminonOracle(oracleGeminon).getSafePrice();
        uint256 priceIndex = IERC20Indexed(stablecoin).getPegValue();
        return (priceIndex * 1e18) / priceGEX;
    }

    
    /// @dev Calculate the percentage of the fee given a GEX amount with 6 decimals. 
    function feeGEX(uint256 amountGEX, uint256 baseFee) public view returns(uint256 fee) {
        if (msg.sender == arbitrageur && arbitrageur != address(0)) return 0;
        uint256 usdiAmount = (amountGEX * getSafeMintRatio(USDI)) / 1e18;
        return _variableFee(usdiAmount, baseFee);
    }

    /// @dev Calculates the percentage of the stableswap fee with 6 decimals. 
    function feeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) public view returns(uint256) {
        uint256 amountEqUSDI = amountUSDI(stableOut, amountOut);
        uint256 feeStableIn = _feeStablecoin(stableIn, amountEqUSDI, usdPriceIn, baseSwapFees[stableIn], false);
        uint256 feeStableOut = _feeStablecoin(stableOut, amountEqUSDI, usdPriceOut, baseSwapFees[stableOut], true);
        return feeStableIn > feeStableOut ? feeStableIn : feeStableOut;
    }


    /// @dev Mints new supply of the stablecoin to this contract
    function _addReserves(uint256 amount, address stablecoin) private {
        IERC20Indexed(stablecoin).mint(address(this), amount);
    }

    /// @dev Transfers GEX tokens from a Genesis Liquidity Pool to this contract
    function _requestBailoutFromPool() private returns(uint256) {
        address pool = _biggestPool();
        uint256 bailoutAmount = IGenesisLiquidityPool(pool).bailoutMinter();
        IERC20(GEX).transferFrom(pool, address(this), bailoutAmount);
        return bailoutAmount;
    }
    

    /// @dev Calculates the safety fee of the stablecoin with 6 decimals. 
    function _feeStablecoin(
        address stable, 
        uint256 amountEqUSDI, 
        uint256 usdPrice, 
        uint256 baseFee, 
        bool isOpLong
    ) private view returns(uint256) {     
        if (msg.sender == arbitrageur && arbitrageur != address(0)) return 0;

        if (stable != USDI && usdPrice != 1e18) {
            uint256 safetyFee = _safetyFeeStablecoin(stable, usdPrice, isOpLong);
            baseFee = safetyFee > baseFee ? safetyFee : baseFee;
        }
        return _variableFee(amountEqUSDI, baseFee);
    }

    /// @dev Returns the address of the GLP with the higher balance of GEX
    function _biggestPool() private view returns(address) {
        return IGeminonOracle(oracleGeminon).getHighestGEXPool();
    }
}