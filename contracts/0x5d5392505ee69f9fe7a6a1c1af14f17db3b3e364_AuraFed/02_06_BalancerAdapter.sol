pragma solidity ^0.8.13;

import "IVault.sol";
import "IERC20.sol";

interface IBPT is IERC20{
    function getPoolId() external view returns (bytes32);
    function getRate() external view returns (uint256);
}

contract BalancerComposableStablepoolAdapter {
    
    uint constant BPS = 10_000;
    bytes32 immutable poolId;
    IERC20 immutable dola;
    IBPT immutable bpt = IBPT(0x5b3240B6BE3E7487d61cd1AFdFC7Fe4Fa1D81e64);
    IVault immutable vault;
    IVault.FundManagement fundMan;
    
    constructor(bytes32 poolId_, address dola_, address vault_){
        poolId = poolId_;
        dola = IERC20(dola_);
        vault = IVault(vault_);
        dola.approve(vault_, type(uint).max);
        bpt.approve(vault_, type(uint).max);
        fundMan.sender = address(this);
        fundMan.fromInternalBalance = false;
        fundMan.recipient = payable(address(this));
        fundMan.toInternalBalance = false;
    }
    
    /**
    @notice Swaps exact amount of assetIn for asseetOut through a balancer pool. Output must be higher than minOut
    @dev Due to the unique design of Balancer ComposableStablePools, where BPT are part of the swappable balance, we can just swap DOLA directly for BPT
    @param assetIn Address of the asset to trade an exact amount in
    @param assetOut Address of the asset to trade for
    @param amount Amount of assetIn to trade
    @param minOut minimum amount of assetOut to receive
    */
    function swapExactIn(address assetIn, address assetOut, uint amount, uint minOut) internal {
        IVault.SingleSwap memory swapStruct;

        //Populate Single Swap struct
        swapStruct.poolId = poolId;
        swapStruct.kind = IVault.SwapKind.GIVEN_IN;
        swapStruct.assetIn = IAsset(assetIn);
        swapStruct.assetOut = IAsset(assetOut);
        swapStruct.amount = amount;
        //swapStruct.userData: User data can be left empty

        vault.swap(swapStruct, fundMan, minOut, block.timestamp+1);
    }

    /**
    @notice Deposit an amount of dola into balancer, getting balancer pool tokens in return
    @param dolaAmount Amount of dola to buy BPTs for
    @param maxSlippage Maximum amount of value that can be lost in basis points, assuming DOLA = 1$
    */
    function _deposit(uint dolaAmount, uint maxSlippage) internal returns(uint){
        uint init = bpt.balanceOf(address(this));
        uint bptWanted = bptNeededForDola(dolaAmount);
        uint minBptOut = bptWanted - bptWanted * maxSlippage / BPS;
        swapExactIn(address(dola), address(bpt), dolaAmount, minBptOut);
        uint bptOut =  bpt.balanceOf(address(this)) - init;
        return bptOut;
    }
    
    /**
    @notice Withdraws an amount of value close to dolaAmount
    @dev Will rarely withdraw an amount equal to dolaAmount, due to slippage.
    @param dolaAmount Amount of dola the withdrawer wants to withdraw
    @param maxSlippage Maximum amount of value that can be lost in basis points, assuming DOLA = 1$
    */
    function _withdraw(uint dolaAmount, uint maxSlippage) internal returns(uint){
        uint init = dola.balanceOf(address(this));
        uint bptNeeded = bptNeededForDola(dolaAmount);
        uint minDolaOut = dolaAmount - dolaAmount * maxSlippage / BPS;
        swapExactIn(address(bpt), address(dola), bptNeeded, minDolaOut);
        uint dolaOut = dola.balanceOf(address(this)) - init;
        return dolaOut;
    }

    /**
    @notice Withdraws all BPT in the contract
    @dev Will rarely withdraw an amount equal to dolaAmount, due to slippage.
    @param maxSlippage Maximum amount of value that can be lost in basis points, assuming DOLA = 1$
    */
    function _withdrawAll(uint maxSlippage) internal returns(uint){
        uint bptBal = bpt.balanceOf(address(this));
        uint expectedDolaOut = bptBal * bpt.getRate() / 10**18;
        uint minDolaOut = expectedDolaOut - expectedDolaOut * maxSlippage / BPS;
        swapExactIn(address(bpt), address(dola), bptBal, minDolaOut);
        return dola.balanceOf(address(this));
    }

    /**
    @notice Get amount of BPT equal to the value of dolaAmount, assuming Dola = 1$
    @dev Uses the getRate() function of the balancer pool to calculate the value of the dolaAmount
    @param dolaAmount Amount of DOLA to get the equal value in BPT.
    @return Uint representing the amount of BPT the dolaAmount should be worth.
    */
    function bptNeededForDola(uint dolaAmount) public view returns(uint) {
        return dolaAmount * 10**18 / bpt.getRate();
    }
}
