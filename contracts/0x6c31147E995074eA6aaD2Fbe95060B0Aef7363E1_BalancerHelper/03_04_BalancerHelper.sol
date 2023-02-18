pragma solidity ^0.8.13;
import "src/util/IVault.sol";
import "src/util/AbstractHelper.sol";

interface BalancerPool {
    function getSwapFeePercentage() external view returns(uint);
}

contract BalancerHelper is AbstractHelper{

    IVault immutable vault;
    bytes32 immutable poolId;
    BalancerPool immutable balancerPool;
    IVault.FundManagement fundManangement;

    constructor(bytes32 _poolId, address _vault) {
        vault = IVault(_vault);
        poolId = _poolId;
        (address balancerPoolAddress,) = vault.getPool(_poolId);
        balancerPool = BalancerPool(balancerPoolAddress);
        fundManangement.sender = address(this);
        fundManangement.fromInternalBalance = false;
        fundManangement.recipient = payable(address(this));
        fundManangement.toInternalBalance = false;
        DOLA.approve(_vault, type(uint).max);
        DBR.approve(_vault, type(uint).max);
    }

    /**
    @notice Sells an exact amount of DBR for DOLA in a balancer pool
    @param amount Amount of DBR to sell
    @param minOut minimum amount of DOLA to receive
    */
    function _sellExactDbr(uint amount, uint minOut) internal override {
        IVault.SingleSwap memory swapStruct;

        //Populate Single Swap struct
        swapStruct.poolId = poolId;
        swapStruct.kind = IVault.SwapKind.GIVEN_IN;
        swapStruct.assetIn = IAsset(address(DBR));
        swapStruct.assetOut = IAsset(address(DOLA));
        swapStruct.amount = amount;
        //swapStruct.userData: User data can be left empty

        vault.swap(swapStruct, fundManangement, minOut, block.timestamp);
    }

    /**
    @notice Buys an exact amount of DBR for DOLA in a balancer pool
    @param amount Amount of DBR to receive
    @param maxIn maximum amount of DOLA to put in
    */
    function _buyExactDbr(uint amount, uint maxIn) internal override {
        IVault.SingleSwap memory swapStruct;

        //Populate Single Swap struct
        swapStruct.poolId = poolId;
        swapStruct.kind = IVault.SwapKind.GIVEN_OUT;
        swapStruct.assetIn = IAsset(address(DOLA));
        swapStruct.assetOut = IAsset(address(DBR));
        swapStruct.amount = amount;
        //swapStruct.userData: User data can be left empty

        vault.swap(swapStruct, fundManangement, maxIn, block.timestamp);
    }
    
    /**
    @notice Retrieve the token balance of tokens in a balancer pool with only two tokens.
    @dev Will break if used on balancer pools with more than two tokens.
    @param tokenIn Address of the token being traded in
    @param tokenOut Address of the token being traded out
    @return balanceIn balanceOut A tuple of (balanceIn, balanceOut) balances
    */
    function _getTokenBalances(address tokenIn, address tokenOut) internal view returns(uint balanceIn, uint balanceOut){
        (address[] memory tokens, uint[] memory balances,) = vault.getPoolTokens(poolId);
        if(tokens[0] == tokenIn && tokens[1] == tokenOut){
            balanceIn = balances[0];
            balanceOut = balances[1];
        } else if(tokens[1] == tokenIn && tokens[0] == tokenOut){
            balanceIn = balances[1];
            balanceOut = balances[0];       
        } else {
            revert("Wrong tokens in pool");
        }   
    }

    /**
    @notice Calculates the amount of a token received from balancer weighted pool, given balances and amount in
    @dev Will only work for 50-50 weighted pools
    @param balanceIn Pool balance of token being traded in
    @param balanceOut Pool balance of token received
    @param amountIn Amount of token being traded in
    @param tradeFee The fee taking by LPs
    @return Amount of token received
    */
    function _getOutGivenIn(uint balanceIn, uint balanceOut, uint amountIn, uint tradeFee) internal pure returns(uint){
        return balanceOut * (10**18 - (balanceIn * 10**18 / (balanceIn + amountIn))) / 10**18 * (10**18 - tradeFee) / 10**18;
    }

    /**
    @notice Calculates the amount of a token to pay to a balancer weighted pool, given balances and amount out
    @dev Will only work for 50-50 weighted pools
    @param balanceIn Pool balance of token being traded in
    @param balanceOut Pool balance of token received
    @param amountOut Amount of token desired to receive
    @param tradeFee The fee taking by LPs
    @return Amount of token to pay in
    */
    function _getInGivenOut(uint balanceIn, uint balanceOut, uint amountOut, uint tradeFee) internal pure returns(uint){
        return balanceIn * (balanceOut * 10**18 / (balanceOut - amountOut) - 10**18) / 10**18 * (10**18 + tradeFee) / 1 ether;
    }

    /**
    @notice Approximates the amount of additional DOLA and DBR needed to sustain dolaBorrowAmount over the period
    @dev Larger number of iterations increases both accuracy of the approximation and gas cost. Will always undershoot actual DBR amount needed..
    @param dolaBorrowAmount The amount of DOLA the user wishes to borrow before covering DBR expenses
    @param period The amount of seconds the user wish to borrow the DOLA for
    @param iterations The amount of approximation iterations.
    @return dolaNeeded dbrNeeded Tuple of (dolaNeeded, dbrNeeded) representing the total dola needed to pay for the DBR and pay out dolaBorrowAmount and the dbrNeeded to sustain the loan over the period
    */
    function approximateDolaAndDbrNeeded(uint dolaBorrowAmount, uint period, uint iterations) override public view returns(uint dolaNeeded, uint dbrNeeded){
        (uint balanceIn, uint balanceOut) = _getTokenBalances(address(DOLA), address(DBR));
        dolaNeeded  = dolaBorrowAmount;
        uint tradeFee = balancerPool.getSwapFeePercentage();
        //There may be a better analytical way of computing this
        for(uint i; i < iterations; i++){
            dbrNeeded = dolaNeeded * period / 365 days;
            dolaNeeded = dolaBorrowAmount + _getInGivenOut(balanceIn, balanceOut, dbrNeeded, tradeFee);
        }
    }
}