// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {BridgeBase} from "./BridgeBase.sol";
import {LzLib} from "@layerzerolabs/solidity-examples/contracts/libraries/LzLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "./library/TransferHelper.sol";
import {IWETH} from "./interface/IWETH.sol";

contract OriginalBridge is BridgeBase{

    mapping (address => bool) public supportedTokens;
    
    mapping (address => uint) public totalValueLocked;

    mapping (address => uint) public conversionRate;

    uint16 public remoteChainId;

    address public immutable WETH;

    event Send(address indexed  token,address from,address to,uint amount);
    event Receive(address indexed token,address to,uint amount);
    event RegisterToken(address token);
    event SetRemoteChainId(uint16 chainId);
    event WithdrawFee(address token,address to,uint amount);

    receive() external payable {}

    constructor(address _endpoint,uint16 _remoteChainId,address _weth)BridgeBase(_endpoint){
        require(_weth != address(0),"OriginalBridge:Invalid weth address");
        WETH = _weth;
        remoteChainId = _remoteChainId;
    }
    
    function registerToken(address token,uint8 sharedDecimals) external onlyOwner{

        require(!supportedTokens[token] && token != address(0),"OriginalBridge:Invalid address");
        uint8 localDecimals = _getDecimals(token);
        require(localDecimals >= sharedDecimals,"OriginalBridge:Shared decimals must be less than or equal to local decimals");
        supportedTokens[token] = true;
        //usdt 8 set 6 
        //ConversionRate[token] = 10**2 = 100
        conversionRate[token] = 10**(localDecimals-sharedDecimals);
        emit RegisterToken(token);
    }
    
    function estimateGasFee(
        bool _useZero,
        bytes calldata _adapterParam
        ) public view returns (uint nativeFee, uint zroFee)
    {
        bytes memory _payload = abi.encode(PT_MINT,address(this),address(this),0);
        return lzEndpoint.estimateFees(remoteChainId, address(this), _payload, _useZero, _adapterParam);
    }
    
    function setRemoteChainId(uint16 chainId) external  onlyOwner{
        remoteChainId = chainId;
        emit SetRemoteChainId(chainId);
    }
    //cross token
    function bridge(
        address token,
        address to,
        uint amountInto,
        LzLib.CallParams calldata callParams,
        bytes memory adapterParams
        ) external payable  nonReentrant
        {
        require(supportedTokens[token] && to != address(0),"OriginalBridge:Invalid address");
        
        uint balanceBefore = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountInto);
        uint balanceAfter = IERC20(token).balanceOf(address(this));

        (uint retained,uint dust) = _removeDust(token, balanceAfter - balanceBefore);
        if (dust>0){
            TransferHelper.safeTransfer(token, msg.sender , dust);
        }
    
        _bridge(token, to, retained, msg.value, callParams, adapterParams);
        
    }

    function bridgeETH(
        address to,
        uint amountInto,
        LzLib.CallParams calldata callParams,
        bytes memory adapterParams
        ) external payable  nonReentrant
        {
        require(supportedTokens[WETH] && to != address(0),"OriginalBridge:Invalid address");
        require(msg.value > amountInto,"OriginalBridge:Not enough value");
        (uint retained, ) = _removeDust(WETH, amountInto);
        IWETH(WETH).deposit{value: retained}();
        _bridge(WETH, to, retained, msg.value - retained, callParams, adapterParams);
    }

    function _bridge(
        address token,
        address to,
        uint retained,
        uint nativeFee,
        LzLib.CallParams calldata callParams,
        bytes memory adapterParams
        ) private{
        _checkAdapterParams(remoteChainId, PT_MINT, adapterParams);
        uint mintAmount = _amountLDToSD(token, retained);
        require(mintAmount > 0,"OriginalBridge:Invalid amount");
        
        totalValueLocked[token] += mintAmount;
        
        bytes memory payload = abi.encode(PT_MINT,token,to,mintAmount);
        
        _lzSend(
            remoteChainId, 
            payload, 
            callParams.refundAddress, 
            callParams.zroPaymentAddress, 
            adapterParams, nativeFee);
        emit Send(token, msg.sender, to, retained);
    }

    function _nonblockingLzReceive(
        uint16 srcChainId, 
        bytes memory, 
        uint64, 
        bytes memory payload
    ) internal virtual override 
    {
        
        require(srcChainId == remoteChainId,"OriginalBridge:ChainId mismatch");
        (uint8 pkType,address token,address to,uint withdrawAmount,uint totalAmount,bool unwrap) =
        abi.decode(payload,(uint8,address,address,uint,uint,bool));
        require(pkType == PT_UNLOCK, "OriginalBridge:Pk type mis mismatch");
        require(supportedTokens[token], "OriginalBridge:Not supported");
        totalValueLocked[token] -= totalAmount;
        uint withdrawAmountLD = _amountSDToLD(token,withdrawAmount);
        if (token == WETH && unwrap){
            IWETH(WETH).withdraw(withdrawAmountLD);
            TransferHelper.safeTransferETH(to,withdrawAmountLD);
            emit Receive(address(0), to, withdrawAmountLD);
        }else{
            TransferHelper.safeTransfer(token,to,withdrawAmountLD);
            emit Receive(token, to, withdrawAmountLD);
        }
    }

    function getBridgeTruthFee(address token) public view returns(uint){
        (bool success,bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(success,"Original:Static call failed");
        uint256 currentAmount = abi.decode(data,(uint256));
        return currentAmount - _amountSDToLD(token, totalValueLocked[token]);
    }

    function withdrawFee(address token,address to,uint amount) external onlyOwner{
        
        uint fee = getBridgeTruthFee(token);
        require(amount <= fee,"OriginalBridge:Invalid withdraw amount");
        TransferHelper.safeTransfer(token,to,amount);
        emit WithdrawFee( token, to, amount);
    }

    function _getDecimals(address token) internal view returns (uint8){
        (bool success,bytes memory data) = token.staticcall(abi.encodeWithSignature("decimals()"));
        require(success,"OriginalBridge:Static call failed");
        return abi.decode(data,(uint8));
    }

    function _removeDust(address token,uint amountInto) internal view returns(uint retained,uint dust){
        dust = amountInto % conversionRate[token];
        retained = amountInto - dust;
    }

    function _amountLDToSD(address token,uint amount) internal view returns (uint){
        return amount / conversionRate[token];
        //10**18 - 10**12
    }

    function _amountSDToLD(address token,uint amount) internal view returns (uint){
        return amount * conversionRate[token];
    }


}