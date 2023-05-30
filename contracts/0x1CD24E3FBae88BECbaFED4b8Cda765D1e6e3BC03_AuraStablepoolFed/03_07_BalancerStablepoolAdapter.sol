pragma solidity ^0.8.13;

import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/IERC20.sol";

interface IBPT is IERC20{
    function getPoolId() external view returns (bytes32);
    function getRate() external view returns (uint256);
}

interface IBalancerHelper{
    function queryExit(bytes32 poolId, address sender, address recipient, IVault.ExitPoolRequest memory erp) external returns (uint256 bptIn, uint256[] memory amountsOut);
    function queryJoin(bytes32 poolId, address sender, address recipient, IVault.JoinPoolRequest memory jrp) external returns (uint256 bptOut, uint256[] memory amountsIn);
}

contract BalancerStablepoolAdapter {

    uint constant BPS = 10_000;
    bytes32 immutable poolId;
    IERC20 dola;
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    //IBPT immutable bbAUSD = IBPT(0xA13a9247ea42D743238089903570127DdA72fE44);
    //IBalancerHelper helper = IBalancerHelper(0x5aDDCCa35b7A0D07C74063c48700C8590E87864E);
    IBPT immutable bpt = IBPT(0xFf4ce5AAAb5a627bf82f4A571AB1cE94Aa365eA6);
    IVault vault;
    IAsset[] assets = new IAsset[](0);
    uint dolaIndex = type(uint).max;

    constructor(bytes32 poolId_, address dola_, address vault_){
        poolId = poolId_;
        dola = IERC20(dola_);
        vault = IVault(vault_);
        dola.approve(vault_, type(uint).max);
        bpt.approve(vault_, type(uint).max);
        (address[] memory tokens,,) = vault.getPoolTokens(poolId_);
        for(uint i; i<tokens.length; i++){
            assets.push(IAsset(address(tokens[i])));
            if(address(tokens[i]) == dola_){
                dolaIndex = i;
            }
        }
        require(dolaIndex < type(uint).max, "Underlying token not found");
    }

    function getUserDataExactInDola(uint amountIn) internal view returns(bytes memory) {
        uint[] memory amounts = new uint[](assets.length);
        amounts[dolaIndex] = amountIn;
        return abi.encode(1, amounts, 0);
    }

    function getUserDataExactInBPT(uint amountIn) internal view returns(bytes memory) {
        uint[] memory amounts = new uint[](assets.length);
        amounts[dolaIndex] = amountIn;
        return abi.encode(0, amounts);
    }

    function getUserDataCustomExit(uint exactDolaOut, uint maxBPTin) internal view returns(bytes memory) {
        uint[] memory amounts = new uint[](assets.length);
        amounts[dolaIndex] = exactDolaOut;
        return abi.encode(2, amounts, maxBPTin);
    }

    function getUserDataExitExact(uint exactBptIn) internal view returns(bytes memory) {
        return abi.encode(0, exactBptIn, dolaIndex);
    }

    function createJoinPoolRequest(uint dolaAmount) internal view returns(IVault.JoinPoolRequest memory){
        IVault.JoinPoolRequest memory jpr;
        jpr.assets = assets;
        jpr.maxAmountsIn = new uint[](assets.length);
        jpr.maxAmountsIn[dolaIndex] = dolaAmount;
        jpr.userData = getUserDataExactInDola(dolaAmount);
        jpr.fromInternalBalance = false;
        return jpr;
    }

    function createExitPoolRequest(uint index, uint dolaAmount, uint maxBPTin) internal view returns (IVault.ExitPoolRequest memory){
        IVault.ExitPoolRequest memory epr;
        epr.assets = assets;
        epr.minAmountsOut = new uint[](assets.length);
        epr.minAmountsOut[index] = dolaAmount;
        epr.userData = getUserDataCustomExit(dolaAmount, maxBPTin);
        epr.toInternalBalance = false;
        return epr;
    }

    function createExitExactPoolRequest(uint index, uint bptAmount, uint minDolaOut) internal view returns (IVault.ExitPoolRequest memory){
        IVault.ExitPoolRequest memory epr;
        epr.assets = assets;
        epr.minAmountsOut = new uint[](assets.length);
        epr.minAmountsOut[index] = minDolaOut;
        epr.userData = getUserDataExitExact(bptAmount);
        epr.toInternalBalance = false;
        return epr;
    }


    function _deposit(uint dolaAmount, uint maxSlippage) internal returns(uint){
        uint init = bpt.balanceOf(address(this));
        uint bptWanted = bptNeededForDola(dolaAmount);
        vault.joinPool(poolId, address(this), address(this), createJoinPoolRequest(dolaAmount));
        uint bptOut =  bpt.balanceOf(address(this)) - init;
        require(bptOut > bptWanted - bptWanted * maxSlippage / BPS, "Insufficient BPT received");
        return bptOut;
    }

    function _withdraw(uint dolaAmount, uint maxSlippage) internal returns(uint){
        uint init = dola.balanceOf(address(this));
        uint bptNeeded = bptNeededForDola(dolaAmount);
        uint minDolaOut = dolaAmount - dolaAmount * maxSlippage / BPS;
        vault.exitPool(poolId, address(this), payable(address(this)), createExitExactPoolRequest(dolaIndex, bptNeeded, minDolaOut));
        uint dolaOut = dola.balanceOf(address(this)) - init;
        return dolaOut;
    }

    function _withdrawAll(uint maxSlippage) internal returns(uint){
        uint bptBal = bpt.balanceOf(address(this));
        uint expectedDolaOut = bptBal * bpt.getRate() / 10**18;
        uint minDolaOut = expectedDolaOut - expectedDolaOut * maxSlippage / BPS;
        vault.exitPool(poolId, address(this), payable(address(this)), createExitExactPoolRequest(dolaIndex, bptBal, minDolaOut));
        return dola.balanceOf(address(this));
    }

    function bptNeededForDola(uint dolaAmount) public view returns(uint) {
        return dolaAmount * 10 ** 18 / bpt.getRate();
    }
}