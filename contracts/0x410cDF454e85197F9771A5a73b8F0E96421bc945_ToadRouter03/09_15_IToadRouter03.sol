/// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

import "./ToadStructs.sol";
import "./IMulticall.sol";
import "./IPermit2/IAllowanceTransfer.sol";
/**
 * IToadRouter03 
 * Extends the V1 router with auto-unwrap functions and permit2 support - also implements Multicall
 * Also has a proper price calculator
 */
abstract contract IToadRouter03 is IMulticall {

    /**
     * Run a permit on a token to the Permit2 contract for max uint256
     * @param owner the token owner
     * @param tok the token to permit
     * @param deadline A deadline to expire by
     * @param v v of the sig
     * @param r r of the sig
     * @param s s of the sig
     */
    function performPermit(address owner, address tok, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual;

    /**
     * Run a permit on a token to the Permit2 contract via the Dai-style permit
     * @param owner the token owner
     * @param tok the token to permit
     * @param deadline A deadline to expire by
     * @param nonce the nonce
     * @param v v of the sig
     * @param r r of the sig
     * @param s s of the sig
     */
    function performPermitDai(address owner, address tok, uint256 nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual;

    /**
     * Run a Permit2 permit on a token to be spent by us
     * @param owner The tokens owner
     * @param permitSingle The struct 
     * @param signature The signature
     */
    function performPermit2Single(address owner, IAllowanceTransfer.PermitSingle memory permitSingle, bytes calldata signature) public virtual;

    /**
     * Run a batch of Permit2 permits on a token to be spent by us
     * @param owner The tokens owner
     * @param permitBatch The struct
     * @param signature The signature
     */
    function performPermit2Batch(address owner, IAllowanceTransfer.PermitBatch memory permitBatch, bytes calldata signature) public virtual;

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path1, ToadStructs.AggPath[] calldata path2, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes, bool unwrap) public virtual returns(uint256 outputAmount);

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, ToadStructs.AggPath[] calldata path, address to, uint deadline, ToadStructs.FeeStruct calldata fees, uint256 ethFee, ToadStructs.AggPath[] calldata gasPath, ToadStructs.DexData[] calldata dexes) public virtual returns(uint256 outputAmount);

    function getPriceOut(uint256 amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) public view virtual returns (uint256[] memory amounts);

    function getAmountsOut(uint amountIn, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, ToadStructs.AggPath[] calldata path, ToadStructs.DexData[] calldata dexes) external view virtual returns (uint[] memory amounts);

    
    // IToadRouter01
    string public versionRecipient = "3.0.0";
    address public immutable factory;
    address public immutable WETH;

    constructor(address fac, address weth) {
        factory = fac;
        WETH = weth;
    }

    function unwrapWETH(address to, uint256 amount, ToadStructs.FeeStruct calldata fees) external virtual;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view virtual returns (uint[] memory amounts);

}


//swapExactTokensForTokensSupportingFeeOnTransferTokensWithWETHGas(uint256,uint256,(address,uint96)[],(address,uint96)[],address,uint256,(uint256,address,uint96),(bytes32,address)[])