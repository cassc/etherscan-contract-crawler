// SPDX-License-Identifier: UNLICENSED
// Copyright 2023 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./ClipperCommonExchange.sol";
import "./ClipperProtocolDeposit.sol";

interface DaiPermitInterface {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

interface WETH9Interface {
    function deposit() external payable;
}

contract ClipperTransferHelper is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable PROTOCOL_DEPOSIT;
    address payable public immutable CLIPPER_POOL;

    bytes4 constant EIP2612_FUNCTION_SELECTOR = IERC20Permit.permit.selector;
    bytes4 constant DAI_PERMIT_FUNCTION_SELECTOR = DaiPermitInterface.permit.selector;
    address constant CLIPPER_ETH_SIGIL = address(0);

    error InvalidPermit();
    error InvalidClipper();

    event LPTransferred(
        address indexed depositor,
        address indexed oldClipper,
        uint256 oldPoolTokens,
        uint256 newPoolTokens
    );

    constructor(address _clipperPool, address _protocolDepositContract){
        CLIPPER_POOL = payable(_clipperPool);
        PROTOCOL_DEPOSIT = _protocolDepositContract;

        IERC20(_clipperPool).approve(_protocolDepositContract, type(uint256).max);
    }

    // Allows the receipt of ETH directly
    receive() external payable {
    }

    function safePermit(address token, bytes calldata permitCallData, bool daiStylePermitAllowed) internal {
        bytes4 functionSignature = bytes4(permitCallData[:4]);
        if(functionSignature != EIP2612_FUNCTION_SELECTOR){
            if(!daiStylePermitAllowed || functionSignature != DAI_PERMIT_FUNCTION_SELECTOR){
                revert InvalidPermit();
            }
        }

        (bool success, ) = token.call(permitCallData);
        if(!success){
            revert InvalidPermit();
        }
    }

    function permitSwap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, ClipperCommonExchange.Signature calldata theSignature, bytes calldata auxiliaryData, bytes calldata permitData) external nonReentrant {
        safePermit(inputToken, permitData, true);

        IERC20(inputToken).safeTransferFrom(msg.sender, CLIPPER_POOL, inputAmount);

        if(outputToken == CLIPPER_ETH_SIGIL){
            ClipperCommonExchange(CLIPPER_POOL).sellTokenForEth(inputToken, inputAmount, outputAmount, goodUntil, destinationAddress, theSignature, auxiliaryData);
        } else {
            ClipperCommonExchange(CLIPPER_POOL).swap(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress, theSignature, auxiliaryData);
        }
    }

    function permitProtocolDeposit(uint256 clipperLPAmount, bytes calldata permitData) external {
        safePermit(CLIPPER_POOL, permitData, false);

        IERC20(CLIPPER_POOL).safeTransferFrom(msg.sender, address(this), clipperLPAmount);
        ClipperProtocolDeposit(PROTOCOL_DEPOSIT).depositClipperLPFor(msg.sender, clipperLPAmount);
    }
    
    // To send ETH, use CLIPPER_ETH_SIGIL as the inputToken and attach as msg.value
    // The ETH will be automatically wrapped and transferred to the Pool as WETH
    function transferAndDepositSingleAsset(address inputToken, uint256 inputAmount, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature, bytes calldata permitData) external payable nonReentrant {
        if(permitData.length > 0){
           safePermit(inputToken, permitData, true); 
        }
        
        if(inputToken == CLIPPER_ETH_SIGIL){
            if(msg.value > 0){
                address _wrapper = ClipperCommonExchange(CLIPPER_POOL).WRAPPER_CONTRACT();
                WETH9Interface(_wrapper).deposit{value: msg.value}();
                IERC20(_wrapper).safeTransfer(CLIPPER_POOL, inputAmount);
                inputToken = _wrapper;
            }
        } else {
            IERC20(inputToken).safeTransferFrom(msg.sender, CLIPPER_POOL, inputAmount);
        }

        ClipperCommonExchange(CLIPPER_POOL).depositSingleAsset(address(this), inputToken, inputAmount, 0, poolTokens, goodUntil, theSignature);
        
        ClipperProtocolDeposit(PROTOCOL_DEPOSIT).depositClipperLPFor(msg.sender, poolTokens);
    }

    // Needs to be approved for transfer on each token being sent
    // (permits can be sent in a permitArray corresponding to depositAmounts)
    // Can take raw ETH, which we'll handle the wrapping of locally
    // NB: If raw ETH is sent, no WETH will be transferred from the user
    function transferAndDepositMultipleAssets(uint256[] calldata depositAmounts, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature, bytes[] calldata permitDataArray) external payable nonReentrant {
        bool _hasPermitData = permitDataArray.length > 0;
        address _wrapper;

        if(msg.value > 0){
            _wrapper = ClipperCommonExchange(CLIPPER_POOL).WRAPPER_CONTRACT();
            WETH9Interface(_wrapper).deposit{value: msg.value}();
        }

        uint i=0;
        uint n = depositAmounts.length;
        while(i < n){
            uint256 transferAmount = depositAmounts[i];
            if(transferAmount > 0){
                address _theToken = ClipperCommonExchange(CLIPPER_POOL).tokenAt(i);
                if(_hasPermitData && permitDataArray[i].length > 0){
                    safePermit(_theToken, permitDataArray[i], true);
                }
                // address(0) is not a token
                if(_theToken == _wrapper){
                    // In this case, _wrapper has been set to the wrapper contract
                    // because we had msg.value
                    // That msg.value has been turned into WETH on THIS contract
                    // So we're going to transfer from this contract to the pool 
                    IERC20(_theToken).safeTransfer(CLIPPER_POOL, transferAmount);
                } else {
                    IERC20(_theToken).safeTransferFrom(msg.sender, CLIPPER_POOL, transferAmount);
                }
            }
            i++;
        }

        ClipperCommonExchange(CLIPPER_POOL).deposit(address(this), depositAmounts, 0, poolTokens, goodUntil, theSignature);
        ClipperProtocolDeposit(PROTOCOL_DEPOSIT).depositClipperLPFor(msg.sender, poolTokens);
    }

    // transfer from old Clipper LP
    function transferLP(address payable oldClipper, uint256[] calldata depositAmounts, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature) external nonReentrant {
        if(oldClipper == CLIPPER_POOL){
            revert InvalidClipper();
        }

        uint256 oldLPBalance = IERC20(oldClipper).balanceOf(msg.sender);

        IERC20(oldClipper).safeTransferFrom(msg.sender, address(this), oldLPBalance);
        ClipperCommonExchange(oldClipper).burnToWithdraw(oldLPBalance);
        
        // Go through all the tokens of the old pool and transfer to the new exchange if they're supported there
        // If not, just send them back to the depositor
        uint256 oldNTokens = ClipperCommonExchange(oldClipper).nTokens();
        for(uint i=0; i < oldNTokens; i++){
            address _theToken = ClipperCommonExchange(oldClipper).tokenAt(i);
            uint256 _theBalance = IERC20(_theToken).balanceOf(address(this));
            address _destination;
            if(ClipperCommonExchange(CLIPPER_POOL).isToken(_theToken)){
                _destination = CLIPPER_POOL;
            } else {
                _destination = msg.sender;
            }
            IERC20(_theToken).safeTransfer(_destination, _theBalance);
        }
        ClipperCommonExchange(CLIPPER_POOL).deposit(address(this), depositAmounts, 0, poolTokens, goodUntil, theSignature);
        
        ClipperProtocolDeposit(PROTOCOL_DEPOSIT).depositClipperLPFor(msg.sender, poolTokens);

        emit LPTransferred(msg.sender, oldClipper, oldLPBalance, poolTokens);
    }


}