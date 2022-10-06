// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "IERC20.sol";

import "IERC721Receiver.sol";
import "Ownable.sol";
import "SafeMath.sol";
//import "INonfungiblePositionManager.sol";

//import 'V3LiqManagerHelperLib.sol';
import "INonfungiblePositionManager.sol";
import "IUniswapV3Factory.sol";
import "IUniswapV3Pool.sol";
import "FixedPoint128.sol";
import "FullMath.sol";
import "TickMath.sol";
import "SqrtPriceMath.sol";
import "TransferHelper.sol";


library V3LiqManagerHelperLib {
    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function getPositionInfo(address npmAddress, uint256 tokenID) public view returns (Position memory pos){
        (uint96 nonce, 
        address operator, 
        address token0, 
        address token1, 
        uint24 fee, 
        int24 tickLower, 
        int24 tickUpper, 
        uint128 liquidity, 
        uint256 feeGrowthInside0LastX128, 
        uint256 feeGrowthInside1LastX128, 
        uint128 tokensOwed0, 
        uint128 tokensOwed1) = INonfungiblePositionManager(npmAddress).positions(tokenID);
        pos = Position(nonce,operator,token0,token1,fee,tickLower,tickUpper,liquidity,
                       feeGrowthInside0LastX128,feeGrowthInside1LastX128,tokensOwed0,tokensOwed1);
    }

    function getPositionLiquidity(address npmAddress, uint256 tokenID) public view returns (uint128){
        (,,,,,,,uint128 liquidity,,,,) = INonfungiblePositionManager(npmAddress).positions(tokenID);
        return liquidity;
    }

    function getSqrtPriceAndTick(address poolAddress) public view returns (uint160 sqrtPriceX96, int24 currentTick) {
        // depositInfo memory DI = deposited[npmAddress][tokenID];
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        (sqrtPriceX96, currentTick,,,,,) = pool.slot0();
    }

    function getLiquidityDeltas(uint128 liq, uint160 sqrtPriceCurrent, int24 currentTick, int24 tickLower, int24 tickUpper) 
        public pure returns (uint256 amt0, uint256 amt1) {

        //uint160 sqrtPriceCurrent = TickMath.getSqrtRatioAtTick(currentTick);
        uint160 sqrtPriceLower = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceUpper = TickMath.getSqrtRatioAtTick(tickUpper);

        if (currentTick < tickLower){
            amt0 = SqrtPriceMath.getAmount0Delta(sqrtPriceLower, sqrtPriceUpper, liq, true);
            amt1 = 0;
        } else if ( tickLower <= currentTick && currentTick < tickUpper) {
            amt0 = SqrtPriceMath.getAmount0Delta(sqrtPriceCurrent, sqrtPriceUpper, liq, true);
            amt1 = SqrtPriceMath.getAmount1Delta(sqrtPriceCurrent, sqrtPriceLower, liq, true);
        } else {
            amt0 = 0;
            amt1 = SqrtPriceMath.getAmount1Delta(sqrtPriceUpper, sqrtPriceLower, liq, true);
        }
    }
    
    function getVirtualReserves(address npmAddress, uint256 tokenID, address poolAddress) public view returns (uint256 amt0, uint256 amt1) {
        // INonfungiblePositionManager npm = INonfungiblePositionManager(npmAddress);
        Position memory pos = getPositionInfo(npmAddress, tokenID);

        uint128 liq = pos.liquidity;

        (uint160 sqrtPrice, int24 currentTick) = getSqrtPriceAndTick(poolAddress);
        return getLiquidityDeltas(liq, sqrtPrice, currentTick, pos.tickLower, pos.tickUpper);
    }

    function calcFees(address npmAddress, uint256 tokenID, address poolAddress) public view 
             returns (uint128 tokensOwed0, uint128 tokensOwed1) {
        // INonfungiblePositionManager npm = INonfungiblePositionManager(npmAddress);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        (, int24 currentTick,,,,,) = pool.slot0();

        Position memory position = getPositionInfo(npmAddress, tokenID);

        (, , uint256 fgOutside0_lower, uint256 fgOutside1_lower,,,,) = pool.ticks(position.tickLower);
        (, , uint256 fgOutside0_upper, uint256 fgOutside1_upper,,,,) = pool.ticks(position.tickUpper);

        uint256 fBelowLowerTick0;
        uint256 fAboveUpperTick0;
        uint256 fBelowLowerTick1;
        uint256 fAboveUpperTick1;

        //compute fees below lower tick
        if (currentTick >= position.tickLower){
            fBelowLowerTick0 = fgOutside0_lower;
            fBelowLowerTick1 = fgOutside1_lower;
        } else {
            fBelowLowerTick0 = pool.feeGrowthGlobal0X128() - fgOutside0_lower;
            fBelowLowerTick1 = pool.feeGrowthGlobal1X128() - fgOutside1_lower;
        }

        //compute fees above upper tick
        if (currentTick >= position.tickUpper){
            fAboveUpperTick0 = pool.feeGrowthGlobal0X128() - fgOutside0_upper;
            fAboveUpperTick1 = pool.feeGrowthGlobal1X128() - fgOutside1_upper;
        } else {
            fAboveUpperTick0 = fgOutside0_upper;
            fAboveUpperTick1 = fgOutside1_upper;
        }

        tokensOwed0 = position.tokensOwed0;
        tokensOwed1 = position.tokensOwed1;

        tokensOwed0 += 
            uint128(
                FullMath.mulDiv(pool.feeGrowthGlobal0X128() - fBelowLowerTick0 - fAboveUpperTick0 - position.feeGrowthInside0LastX128, 
                                position.liquidity, 
                                FixedPoint128.Q128
                )
            );
        tokensOwed1 += 
            uint128(
                FullMath.mulDiv(pool.feeGrowthGlobal1X128() - fBelowLowerTick1 - fAboveUpperTick1 - position.feeGrowthInside1LastX128, 
                                position.liquidity, 
                                FixedPoint128.Q128
                )
            );
    }

    function createPool(address npmAddress, address token0, address token1, uint24 fee, uint160 sqrtPriceX96) 
                             public 
                             returns(address) {
        //address npmAddress = defaultNPM;
        address pairAddress;
        INonfungiblePositionManager npm = INonfungiblePositionManager(npmAddress);

        IUniswapV3Factory factory = IUniswapV3Factory(npm.factory());
        pairAddress = factory.getPool(token0, token1, fee);
        if (pairAddress == address(0)){
            pairAddress = factory.createPool(token0, token1, fee);
        }
        IUniswapV3Pool pool = IUniswapV3Pool(pairAddress);
        pool.initialize(sqrtPriceX96);

        // pairAddress = npm.createAndInitializePoolIfNecessary(token0, token1, fee, sqrtPriceX96); //fails sometimes. not sure why./
        return pairAddress;
    }

    //note that pool must be created and initialized first!
    function mint(INonfungiblePositionManager.MintParams calldata params, address npmAddress) 
                             public
                             returns(uint256 tokenID, uint128 liq, uint256 amt0, uint256 amt1) {
        INonfungiblePositionManager npm = INonfungiblePositionManager(npmAddress);

        TransferHelper.safeTransferFrom(params.token0, msg.sender, address(this), params.amount0Desired);
        TransferHelper.safeTransferFrom(params.token1, msg.sender, address(this), params.amount1Desired);

        TransferHelper.safeApprove(params.token0, npmAddress, params.amount0Desired);
        TransferHelper.safeApprove(params.token1, npmAddress, params.amount1Desired);
        
        (tokenID, liq, amt0, amt1) = npm.mint(params);  //owner will be msg.sender, so the deposit must be done separately, after approval
 
        // Remove allowance and refund in both assets.
        if (amt0 < params.amount0Desired) {
            TransferHelper.safeApprove(params.token0, npmAddress, 0);
            uint256 refund0 = params.amount0Desired - amt0;
            TransferHelper.safeTransfer(params.token0, msg.sender, refund0);
        }

        if (amt1 < params.amount1Desired) {
            TransferHelper.safeApprove(params.token1, npmAddress, 0);
            uint256 refund1 = params.amount1Desired - amt1;
            TransferHelper.safeTransfer(params.token1, msg.sender, refund1);
        }
    }

    //return liquidity is the amount of new liquidity that is created.
    function increaseLiquidity(address npmAddress, uint256 tokenID,  
                               uint256 amtAdd0, uint256 amtAdd1, uint256 amtAdd0Min, uint256 amtAdd1Min) 
                               public returns (uint128 liquidity, uint256 amt0, uint256 amt1) {
                                   
        INonfungiblePositionManager npm = INonfungiblePositionManager(npmAddress);

        Position memory position = getPositionInfo(npmAddress, tokenID);
        address token0 = position.token0;
        address token1 = position.token1;
        
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amtAdd0);
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amtAdd1);

        TransferHelper.safeApprove(token0, npmAddress, amtAdd0);
        TransferHelper.safeApprove(token1, npmAddress, amtAdd1);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
                    INonfungiblePositionManager.IncreaseLiquidityParams({
                        tokenId: tokenID,
                        amount0Desired: amtAdd0,
                        amount1Desired: amtAdd1,
                        amount0Min: amtAdd0Min,
                        amount1Min: amtAdd1Min,
                        deadline: block.timestamp
                    });

        (liquidity, amt0, amt1) = npm.increaseLiquidity(params);

        // Remove allowance and refund in both assets and refund.
        if (amt0 < amtAdd0) {
            TransferHelper.safeApprove(token0, npmAddress, 0);
            uint256 refund0 = amtAdd0 - amt0;
            TransferHelper.safeTransfer(token0, msg.sender, refund0);
        }

        if (amt1 < amtAdd1) {
            TransferHelper.safeApprove(token1, npmAddress, 0);
            uint256 refund1 = amtAdd1 - amt1;
            TransferHelper.safeTransfer(token1, msg.sender, refund1);
        }
    }

    function decreaseLiquidity(address npmAddress, uint256 tokenID, uint128 liquidityToRemove, uint256 amt0Min, uint256 amt1Min) 
                               public returns (uint256 amt0, uint256 amt1) {
        INonfungiblePositionManager npm = INonfungiblePositionManager(npmAddress);
        
        //TODO: add slipppage factor instead of amountsMin = 0. Need to find amount in pool.
        INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenID,
                liquidity: liquidityToRemove,
                amount0Min: amt0Min,
                amount1Min: amt1Min,
                deadline: block.timestamp
            });

        (amt0, amt1) = npm.decreaseLiquidity(decreaseParams);
        // if (amt0 > 0 ) {
        //     // TransferHelper.safeTransfer(token0, msg.sender, amt0);
        //     TransferHelper.safeTransfer(token0, msg.sender, amt0);
        // }
        // if (amt1 > 0 ) {
        //     TransferHelper.safeTransfer(token1, msg.sender, amt1);
        // }
    }

    //set amt0, amt1 to type(uint128).max = 2**128-1 to collect all fees
    function collectFees(address npmAddress, uint256 tokenID, address recipient, uint128 amt0, uint128 amt1) 
        public 
        returns(uint256 token0Amt, uint256 token1Amt) {

        INonfungiblePositionManager.CollectParams memory collectParams;
        collectParams = INonfungiblePositionManager.CollectParams(tokenID, recipient, amt0, amt1);

        (token0Amt, token1Amt) = INonfungiblePositionManager(npmAddress).collect(collectParams);
    }
}


contract OrbitalLocker is Ownable, IERC721Receiver  {
    event Log(string message);

    struct positionInfo {
        uint256 tokenID;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
    }
    
    using SafeMath for uint256;
    address private _owner;
    
    string private _name = "OrbitalLocker";
    bool internal lock;

    uint256 private lockTokenTime;
    uint256 private lockLPTime;
    uint256 private lastTransactionTimeGlobal;
    uint128 private liquidityGlobal;

    address private npmAddressGlobal;
    uint256 private tokenIDGlobal;
    address private poolAddressGlobal;

    uint256 private feesCollectedGlobal0;
    uint256 private feesCollectedGlobal1;
    address private token0Address;
    address private token1Address;

    uint256 private releaseTimeLP;

    uint256 private releaseTimeToken;
    address private lockedTokenAddress;
    uint256 private lockedTokensDeposited;
    uint256 private lockedTokensDistributed = 0;
    bool private tokensLocked = false;
    bool private LPLocked = false;

    uint256 private initialDepositReleaseTime;
    uint256 private initialDepositReleaseToken = 1;
    uint256 private initialAmt1;
    bool private initialDepositReleased = false;
    positionInfo currentPosition;

    INonfungiblePositionManager npm;

    constructor() public {
        _owner = msg.sender;
    }

    modifier nonReentrant() {
        require(!lock, "no reentrancy allowed");
        lock = true;
        _;
        lock = false;
    }

    receive() external payable {}

    function onERC721Received(address, address, uint256, bytes calldata) external override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    function name() public view returns(string memory){
        return _name;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function getReleaseTimeToken() public view returns (uint256) {
        return releaseTimeToken;
    }

    function getReleaseTimeLP() public view returns (uint256) {
        return releaseTimeLP;
    }

    function getTotalLiquidity() public view returns (uint128) {
        return V3LiqManagerHelperLib.getPositionLiquidity(npmAddressGlobal, tokenIDGlobal);
    }

    function getNFTInfo() public view returns (address npmAddress, uint256 tokenID, uint128 liquidity) {
        return (npmAddressGlobal, tokenIDGlobal, getTotalLiquidity());
    }

    function getPendingFees() public view returns (uint256 pendingFees0, uint256 pendingFees1) {
        (pendingFees0, pendingFees1) = V3LiqManagerHelperLib.calcFees(npmAddressGlobal, tokenIDGlobal, poolAddressGlobal);
    }

    function collectFees() public onlyOwner returns(uint256 amt0, uint256 amt1) {
        (amt0, amt1) = getPendingFees();

        require(amt0 > 0 || amt1 > 0, "no fees to collect");
        (uint256 collected0, uint256 collected1) = V3LiqManagerHelperLib.collectFees(npmAddressGlobal, tokenIDGlobal, address(this), type(uint128).max, type(uint128).max);

        IERC20(token0Address).transfer(msg.sender, collected0);
        // treasuryBalanceToken0 -= amt0;
        feesCollectedGlobal0 += collected0;

        IERC20(token1Address).transfer(msg.sender, collected1);
        // treasuryBalanceToken1 -= amt1;
        feesCollectedGlobal1 += collected1;
    }

    function _increaseLiquidity(address npmAddress, uint256 tokenID, uint256 amt0Desired, uint256 amt1Desired, uint256 amtAdd0Min, uint256 amtAdd1Min) private returns (uint128 newLiquidity, uint256 amt0, uint256 amt1){
        (newLiquidity, amt0, amt1) = V3LiqManagerHelperLib.increaseLiquidity(npmAddress, tokenID, 
                                                                             amt0Desired, amt1Desired, 
                                                                             amtAdd0Min, amtAdd1Min);
    }

    function increaseLiquidity(uint256 amt0Desired, uint256 amt1Desired, uint256 amtAdd0Min, uint256 amtAdd1Min) 
            public onlyOwner returns (uint128 newLiquidity, uint256 amt0, uint256 amt1){
        (newLiquidity, amt0, amt1) = _increaseLiquidity(npmAddressGlobal, tokenIDGlobal, 
                                                       amt0Desired, amt1Desired, 
                                                       amtAdd0Min, amtAdd1Min);
    }

    function _decreaseLiquidity(uint128 liquidityToRemove, uint256 amt0Min, uint256 amt1Min) 
            private returns (uint256 amt0, uint256 amt1, uint256 collected0, uint256 collected1){
        
        (amt0, amt1) = V3LiqManagerHelperLib.decreaseLiquidity(npmAddressGlobal, tokenIDGlobal,  
                                                                liquidityToRemove, amt0Min, amt1Min);

        require(amt0 < type(uint128).max && amt1 < type(uint128).max, "overflow");
        (collected0, collected1) = V3LiqManagerHelperLib.collectFees(npmAddressGlobal, tokenIDGlobal, address(this), uint128(amt0), uint128(amt1));
    }

    function lockTokens(address token, uint256 amt, uint256 lockPeriod) public onlyOwner {
        require(!tokensLocked, "Tokens already locked");
        require(amt > 0, "Amount must be greater than 0");
        require(lockPeriod > 0, "Lock period must be greater than 0");
        lockTokenTime = block.timestamp;
        tokensLocked = true;
        lockedTokenAddress = token;
        lockedTokensDeposited = amt;
        lockedTokensDistributed = 0;
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amt);
        releaseTimeToken = lockTokenTime.add(lockPeriod);
    }

    function withdrawTokens() public onlyOwner returns (uint256 amt) {
        require(tokensLocked, "Tokens not locked");
        uint256 allowedToWithdraw = (block.timestamp - lockTokenTime) * lockedTokensDeposited / (releaseTimeToken - lockTokenTime);
        if (allowedToWithdraw > lockedTokensDeposited) {
            allowedToWithdraw = lockedTokensDeposited;
        }
        amt = allowedToWithdraw - lockedTokensDistributed;
        if (amt > 0) {
            TransferHelper.safeTransfer(lockedTokenAddress, msg.sender, amt);
            lockedTokensDistributed += amt;
        }

        if (lockedTokensDistributed >= lockedTokensDeposited) {
            tokensLocked = false;
        } 
    }

    function lockLP(address npmAddress, 
                    uint256 tokenID, 
                    address routerAddress, 
                    address poolAddress, 
                    uint256 initialDeposit, 
                    uint256 lockPeriod, 
                    uint256 initialDepositLockPeriod) public onlyOwner {
        require(!LPLocked, "LP already locked");
        LPLocked = true;
        initialDepositReleased = false;
        lockLPTime = block.timestamp;
        releaseTimeLP = lockLPTime.add(lockPeriod);
        initialDepositReleaseTime = lockLPTime.add(initialDepositLockPeriod);
        
        npmAddressGlobal = npmAddress;

        npm = INonfungiblePositionManager(npmAddress);

        if (npm.ownerOf(tokenID) != address(this)){
            npm.safeTransferFrom(msg.sender, address(this), tokenID);
        }

        V3LiqManagerHelperLib.Position memory position = V3LiqManagerHelperLib.getPositionInfo(npmAddress, tokenID);
        token0Address = position.token0;
        token1Address = position.token1;

        initialAmt1 = initialDeposit;

        tokenIDGlobal = tokenID;
        poolAddressGlobal = poolAddress;

        positionInfo memory PI = positionInfo(tokenID, position.tickLower, position.tickUpper, position.fee);
        currentPosition = PI;

        IERC20(token0Address).approve(routerAddress, type(uint256).max);
        IERC20(token1Address).approve(routerAddress, type(uint256).max);
        IERC20(token0Address).approve(npmAddress, type(uint256).max);
        IERC20(token1Address).approve(npmAddress, type(uint256).max);
    }

    event CurrentAmts(uint256 amt0, uint256 amt1);
    event EthRatio(uint256 ethRatio);

    function releaseInitialDepositLP(uint256 slippageMilliPercent) 
            public onlyOwner returns (uint256 collected0, uint256 collected1){
        (uint256 currentAmt0, uint256 currentAmt1) = V3LiqManagerHelperLib.getVirtualReserves(npmAddressGlobal, tokenIDGlobal, poolAddressGlobal);

        emit CurrentAmts(currentAmt0, currentAmt1);
        uint256 ethRatio = currentAmt1/initialAmt1;
        emit EthRatio(ethRatio);
        require(block.timestamp >= initialDepositReleaseTime || ethRatio >= 5, "too early to withdraw initial deposit");
        require(initialDepositReleased == false, "initial deposit already released");
        initialDepositReleased = true;
        uint128 currentLiquidity = V3LiqManagerHelperLib.getPositionLiquidity(npmAddressGlobal, tokenIDGlobal);
        uint128 maxLiquidityToRemove = uint128((uint256(currentLiquidity) * initialAmt1) / currentAmt1);

        uint256 amt0Min = (((uint256(maxLiquidityToRemove) * currentAmt0) / currentLiquidity) * (100*1000 - slippageMilliPercent)) /(100*1000);
        uint256 amt1Min = ((initialAmt1) * (100*1000 - slippageMilliPercent)) /(100*1000);
        uint256 amt0;
        uint256 amt1;
        (amt0, amt1, collected0, collected1) = _decreaseLiquidity(maxLiquidityToRemove, amt0Min, amt1Min);

        if (amt0 > 0) {
            TransferHelper.safeTransfer(token0Address, msg.sender, collected0);
            feesCollectedGlobal0 += collected0;
        }
        if (amt1 > 0) {
            TransferHelper.safeTransfer(token1Address, msg.sender, collected1);
            feesCollectedGlobal1 += collected1;
        }
        
    }

    function withdrawLP() public onlyOwner returns (bool) {
        require(LPLocked, "LP not locked");
        require(block.timestamp >= releaseTimeLP, "too early");
        npm.safeTransferFrom(address(this), msg.sender, tokenIDGlobal);
        LPLocked = false;
        return true;
    }



}
