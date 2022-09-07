// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SwapGovernance.sol";
import "./SwapStructs.sol";
/**
 * @title AtlasDexSwap
 * @dev Proxy contract to swap first by redeeming from wormhole and then call 1inch router to swap assets
 * successful.
 */
contract Swap is SwapGovernance  {

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    using SafeMath for uint256;

    // Event for locked amount.
    event AmountLocked (address indexed dstReceiver, uint256 amountReceived);

    /**
     * @dev Withdraw Tokens on Wrapped. 
     * @param _tokenAmount to be used for withdrawing in native currency from wrapped.
     * @param _isUserFundUsed is used either we need to get fund from user address and then call swap or direct use smart contract balance.   
     */
    function withdrawToUnWrappedToken(uint256 _tokenAmount, bool _isUserFundUsed) internal returns (uint256) {
        IWETH wrapped = IWETH(NATIVE_WRAPPED_ADDRESS);
        if (_isUserFundUsed) {
            require(wrapped.balanceOf(msg.sender) >= _tokenAmount, "Atlas DEX: You have insufficient balance to UnWrap");
            wrapped.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        }
        wrapped.withdraw(_tokenAmount);
        // First Calculating here deduct 0.15 percent.
        uint256 feeDeductionAmount = (_tokenAmount.mul(FEE_PERCENT)).div(FEE_PERCENT_DENOMINATOR);
        payable(FEE_COLLECTOR).transfer(feeDeductionAmount);
        payable(msg.sender).transfer((_tokenAmount.sub(feeDeductionAmount)));
        return  _tokenAmount;
    } // end of deposit ToWrappedToken.    
    /**
     * @dev Deposit Tokens on Wrapped. 
     */
    function depositToWrappedToken() internal returns (uint256) {
        require(msg.value > 0, "Atlas Dex: Amount should be greater than 0 to deposit for wrapped.");
        IWETH wrapped = IWETH(NATIVE_WRAPPED_ADDRESS);
        wrapped.deposit{value: msg.value}();
        // First Calculating here deduct 0.15 percent.
        uint256 feeDeductionAmount = (msg.value * FEE_PERCENT) / FEE_PERCENT_DENOMINATOR;
        wrapped.transfer(FEE_COLLECTOR, feeDeductionAmount);

        wrapped.transfer(msg.sender, (msg.value - feeDeductionAmount));
        return  msg.value - feeDeductionAmount;
    } // end of deposit ToWrappedToken.
    /**
     * @dev Swap Tokens on 0x. 
     * @param _0xData a 0x data to call aggregate router to swap assets.
     */
    function _swapToken0x(bytes calldata _0xData) internal returns (uint256) {

        ( SwapStructs._0xSwapDescription memory swapDescriptionObj) = abi.decode(_0xData[4:], (SwapStructs._0xSwapDescription));
         if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) { // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
                ( address[] memory tokens, uint256 sellAmount,, ) = abi.decode(_0xData[4:], (address[], uint256, uint256, uint8));
                swapDescriptionObj.inputToken = tokens[0];
                swapDescriptionObj.outputToken = tokens[tokens.length - 1];
                swapDescriptionObj.inputTokenAmount = sellAmount;
        }
        uint256 outputCurrencyBalanceBeforeSwap = 0;

        // this if else is to save output token balance
        if (address(swapDescriptionObj.outputToken) == NATIVE_ADDRESS) {
            outputCurrencyBalanceBeforeSwap = address(this).balance;
        } else {
            IERC20 swapOutputToken = IERC20(swapDescriptionObj.outputToken);
            outputCurrencyBalanceBeforeSwap = swapOutputToken.balanceOf(address(this));
        } // end of else

        
        if (address(swapDescriptionObj.inputToken) == NATIVE_ADDRESS) {
            // It means we are trying to transfer with Native amount
            require(msg.value >= swapDescriptionObj.inputTokenAmount, "Atlas DEX: Amount Not match with Swap Amount.");
        } else {
            IERC20 swapSrcToken = IERC20(swapDescriptionObj.inputToken);
            if (swapSrcToken.allowance(address(this), OxAggregatorRouter) < swapDescriptionObj.inputTokenAmount) {
                swapSrcToken.safeApprove(OxAggregatorRouter, MAX_INT);
            }

            require(swapSrcToken.balanceOf(msg.sender) >= swapDescriptionObj.inputTokenAmount, "Atlas DEX: You have insufficent balance to swap");
            swapSrcToken.safeTransferFrom(msg.sender, address(this), swapDescriptionObj.inputTokenAmount);
        }

        (bool success, ) = address(OxAggregatorRouter).call{ value: msg.value }(_0xData);
        require(success, "Atlas Dex: Swap Return Failed");
        uint256 outputCurrencyBalanceAfterSwap = 0;
        // Again this check is to maintain for sending receiver balance to msg.sender
        if (address(swapDescriptionObj.outputToken) == NATIVE_ADDRESS) {
            outputCurrencyBalanceAfterSwap = address(this).balance ;
            outputCurrencyBalanceAfterSwap = outputCurrencyBalanceAfterSwap - outputCurrencyBalanceBeforeSwap;
            require(outputCurrencyBalanceAfterSwap > 0, "Atlas DEX: Transfer output amount should be greater than 0.");
            payable(msg.sender).transfer(outputCurrencyBalanceAfterSwap);
        } else {
            IERC20 swapOutputToken = IERC20(swapDescriptionObj.outputToken);
            outputCurrencyBalanceAfterSwap = swapOutputToken.balanceOf(address(this));
            outputCurrencyBalanceAfterSwap = outputCurrencyBalanceAfterSwap - outputCurrencyBalanceBeforeSwap;
            require(outputCurrencyBalanceAfterSwap > 0, "Atlas DEX: Transfer output amount should be greater than 0.");
            swapOutputToken.safeTransfer(msg.sender, outputCurrencyBalanceAfterSwap);
        } // end of else
        // Now need to transfer fund to destination address. 
        return outputCurrencyBalanceAfterSwap;
    } // end of swap function
    /**
     * @dev Swap Tokens on 1inch. 
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     * @param _isUserFundUsed is used either we need to get fund from user address and then call swap or direct use smart contract balance.
     */
    function _swapToken1Inch(bytes calldata _1inchData, bool _isUserFundUsed) internal returns (uint256) {
        (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(_1inchData[4:], (address, SwapStructs._1inchSwapDescription, bytes));

        uint256 amountForNative = 0;
        if (address(swapDescriptionObj.srcToken) == NATIVE_ADDRESS) {
            // It means we are trying to transfer with Native amount
            require(msg.value >= swapDescriptionObj.amount, "Atlas DEX: Amount Not match with Swap Amount.");
            amountForNative = swapDescriptionObj.amount;
        } else {
            IERC20 swapSrcToken = IERC20(swapDescriptionObj.srcToken);
            if (swapSrcToken.allowance(address(this), oneInchAggregatorRouter) < swapDescriptionObj.amount) {
                swapSrcToken.safeApprove(oneInchAggregatorRouter, MAX_INT);
            }

            // when calling from unlock by payload, need to use smart contract fund.
            if (_isUserFundUsed) {
                require(swapSrcToken.balanceOf(msg.sender) >= swapDescriptionObj.amount, "Atlas DEX: You have insufficient balance to swap");
                swapSrcToken.safeTransferFrom(msg.sender, address(this), swapDescriptionObj.amount);
            }
        } // end of else


        (bool success, bytes memory _returnData ) = address(oneInchAggregatorRouter).call{ value: amountForNative }(_1inchData);
        require(success, "Atlas Dex: Swap Return Failed");


        (uint returnAmount, ) = abi.decode(_returnData, (uint, uint));
        return returnAmount;
    } // end of swap function

    /**
     * @dev Swap Tokens on Chain. 
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     */
    function swapTokens(bytes calldata _1inchData, bytes calldata _0xData, bool _IsWrapped, bool _IsUnWrapped, uint256 _amount) external payable returns (uint256) {
        if(_1inchData.length > 1) {
            return _swapToken1Inch(_1inchData, true);
        } else if (_0xData.length > 1) {
            return _swapToken0x(_0xData);
        } else if (_IsWrapped) {
            return depositToWrappedToken();
        } else if ( _IsUnWrapped) {
            return withdrawToUnWrappedToken(_amount, true);
        }
        return 0;

    }

    /**
     * @dev Initiate a wormhole bridge redeem call to unlock asset and then call 1inch router to swap tokens with unlocked balance.
     * @param _wormholeTokenBridgeToken  a wormhole bridge where fromw need to redeem token
     * @param _encodedVAA  VAA for redeeming to get from wormhole guardians
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     * @param _0xData a 1inch data to call aggregate router to swap assets.
     */
    function unlockTokens(address _wormholeTokenBridgeToken, bytes memory _encodedVAA,  bytes calldata _1inchData, bytes calldata _0xData, bool _IsWrapped, bool _IsUnWrapped, uint256 _amount) external payable returns (uint256) {
        // initiate wormhole bridge contract  
        require(_wormholeTokenBridgeToken != address(0), "Atlas Dex: Wormhole Token Bride Address can't be null");      
        ITokenBridgeWormhole wormholeTokenBridgeContract =  ITokenBridgeWormhole(_wormholeTokenBridgeToken);

        // initiate wormhole contract        
        IWormhole wormholeContract = IWormhole(wormholeTokenBridgeContract.wormhole());

        (WormholeStructs.VM memory vm, ,) = wormholeContract.parseAndVerifyVM(_encodedVAA);

        WormholeStructs.Transfer memory transfer = wormholeTokenBridgeContract.parseTransfer(vm.payload);

        
        IERC20 transferToken;
        if (transfer.tokenChain == wormholeTokenBridgeContract.chainId()) {
            transferToken = IERC20(address(uint160(uint256(transfer.tokenAddress))));
        } else {
            address wrapped = wormholeTokenBridgeContract.wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
            require(wrapped != address(0), "AtlasDex: no wrapper for this token created yet");

            transferToken = IERC20(wrapped);
        }
        wormholeTokenBridgeContract.completeTransfer(_encodedVAA);


        uint256 amountTransfer;
        if(_1inchData.length > 1) {
            (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(_1inchData[4:], (address, SwapStructs._1inchSwapDescription, bytes));
            require(swapDescriptionObj.srcToken == transferToken, "Atlas DEX: Token Not Matched");
            amountTransfer = _swapToken1Inch(_1inchData, true);
        } else if (_0xData.length > 1) {
            ( SwapStructs._0xSwapDescription memory swapDescriptionObj) = abi.decode(_0xData[4:], (SwapStructs._0xSwapDescription));
 

            if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) { // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
                ( address[] memory tokens, uint256 sellAmount,, ) = abi.decode(_0xData[4:], (address[], uint256, uint256, uint8));
                swapDescriptionObj.inputToken = tokens[0];
                swapDescriptionObj.outputToken = tokens[tokens.length - 1];
                swapDescriptionObj.inputTokenAmount = sellAmount;
            }
            require(swapDescriptionObj.inputToken == address(transferToken), "Atlas DEX: Token Not Matched");

            amountTransfer = _swapToken0x(_0xData);
        }
        else if (_IsWrapped) {
            amountTransfer =  depositToWrappedToken();
        } else if ( _IsUnWrapped) {
            amountTransfer = withdrawToUnWrappedToken(_amount, true);
        }
        return amountTransfer;

    } // end of unlock Token

    /**
     * @dev Initiate a wormhole bridge redeem call to unlock asset with payload and then call 1inch router to swap tokens with unlocked balance.
     * @param _wormholeTokenBridgeToken  a wormhole bridge where fromw need to redeem token
     * @param _encodedVAA  VAA for redeeming to get from wormhole guardians
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     * @param _IsUnWrapped to decide if redeem is wrapped asset and user want to be unwrapped so that we should save fee.
     */
    function unlockTokensWithPayload(address _wormholeTokenBridgeToken, bytes memory _encodedVAA,  bytes calldata _1inchData, bool _IsUnWrapped) external payable returns (uint256) {
        // initiate wormhole bridge contract  
        require(_wormholeTokenBridgeToken != address(0), "Atlas Dex: Wormhole Token Bride Address can't be null");      
        ITokenBridgeWormhole wormholeTokenBridgeContract =  ITokenBridgeWormhole(_wormholeTokenBridgeToken);


        // initiate wormhole contract        
        IWormhole wormholeContract = IWormhole(wormholeTokenBridgeContract.wormhole());

        (WormholeStructs.VM memory vm, ,) = wormholeContract.parseAndVerifyVM(_encodedVAA);

        WormholeStructs.TransferWithPayload memory transfer = wormholeTokenBridgeContract.parseTransferWithPayload(vm.payload);

                
        // verify that correct VAA is passed for relayer.
        require(transfer.payloadID == 3, "Atlas Dex: Invalid Payload ID for Unlock");
        
        // as its payload 3 so must be redeemed by the address (this)
        require(address(uint160(uint256(transfer.to))) == address(this), "Atlas Dex: Invalid Recipient Address");
        
        IERC20 transferToken;
        {/// bypass stack too deep
            if (transfer.tokenChain == wormholeTokenBridgeContract.chainId()) {
                transferToken = IERC20(address(uint160(uint256(transfer.tokenAddress))));
            } else {
                address wrapped = wormholeTokenBridgeContract.wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
                require(wrapped != address(0), "AtlasDex: no wrapper for this token created yet");

                transferToken = IERC20(wrapped);
            }
        }

        uint256 amountRedeemed;
        {/// bypass stack too deep
            (, bytes memory queriedBalanceBefore) = address(transferToken).staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
            );
            uint256 balanceBefore = abi.decode(queriedBalanceBefore, (uint256));

            // call wormhole bridge  to redeem token to this contract.
            wormholeTokenBridgeContract.completeTransfer(_encodedVAA);


            /// query own token balance after transfer
            (, bytes memory queriedBalanceAfter) = address(transferToken).staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
            );
            uint256 balanceAfter = abi.decode(queriedBalanceAfter, (uint256));
    
            // instead of trusting on payload amount. we will trust on balance after transfer.
            amountRedeemed = balanceAfter.sub(balanceBefore);
        }
        address userRecipient;
        address destiationToken;
        uint256 fee;
        {/// bypass stack too deep
            SwapStructs.CrossChainRelayerPayload memory relayerPayload = parseUnlockWithPayload(transfer.payload);
            userRecipient = address(uint160(uint256(relayerPayload.receiver)));
            require(userRecipient != address(0), "Atlas Dex: Invalid Payload");
            fee = relayerPayload.fee;
            destiationToken = address(uint160(uint256(relayerPayload.token)));
            // query tokens decimals to normalize amount. as transfer.amount is already normalized.
            (,bytes memory queriedDecimals) = address(transferToken).staticcall(abi.encodeWithSignature("decimals()"));
            uint8 decimals = abi.decode(queriedDecimals, (uint8));

            uint256 amountRedeemedNormalized = normalizeAmount(amountRedeemed, decimals);
            // amount transfer to our contract should be same as in payload. as we are checking with normalized because wormhole support transfer up to 8 decimals
            require(amountRedeemed.sub(fee) > 0 && transfer.amount == amountRedeemedNormalized, "Atlas Dex: Invalid Balance After complete Transfer");
        }

        // this is track exact output amount of token to be sent to user.
        uint256 amountTransfer;
        // First tranfer fee of wormhole unlocked to collector. 
        transferToken.safeTransfer(FEE_COLLECTOR, fee);

        if(_1inchData.length > 1) {
            {/// bypass stack too deep
                (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(_1inchData[4:], (address, SwapStructs._1inchSwapDescription, bytes));
                require(swapDescriptionObj.srcToken == transferToken, "Atlas DEX: Token Not Matched");
                require(address(swapDescriptionObj.dstToken) == destiationToken, "Atlas DEX: Destination Token Not Matched");

                require(swapDescriptionObj.amount == amountRedeemed.sub(fee), "Atlas DEX: 1inch Swap Token  Amount Not Matched");
                require(userRecipient == swapDescriptionObj.dstReceiver, "Atlas Dex: Invalid Balance Reciever");
                amountTransfer = _swapToken1Inch(_1inchData, false);
            }
        }
        else if (_IsUnWrapped) {
            require(NATIVE_WRAPPED_ADDRESS == address(transferToken), "Atlas DEX: Token Not Matched");
            amountTransfer = withdrawToUnWrappedToken(amountRedeemed.sub(fee), false);
        } else {
            // here means user want to get wormhole unlocked token.
            transferToken.safeTransfer(userRecipient, amountRedeemed.sub(fee));
        }
        return amountTransfer;

    } // end of unlock Token with payload

    /**
     * @dev Initiate a 1inch/_0x router to swap tokens and then wormhole bridge call to lock asset.
     * @param lockedTokenData  a wormhole bridge where need to lock token
     */
    function lockedTokens( SwapStructs.LockedToken calldata lockedTokenData) external payable returns (uint64) {
        // initiate wormhole bridge contract        
        require(lockedTokenData._wormholeBridgeToken != address(0), "Atlas Dex: Wormhole Token Bride Address can't be null");      

        ITokenBridgeWormhole wormholeTokenBridgeContract =  ITokenBridgeWormhole(lockedTokenData._wormholeBridgeToken);
        IERC20 wormholeWrappedToken = IERC20(lockedTokenData._token);
        uint256 amountToLock = lockedTokenData._amount; 
        if(lockedTokenData._1inchData.length > 1) { // it means user need to first convert token to wormhole token.
            (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(lockedTokenData._1inchData[4:], (address,SwapStructs._1inchSwapDescription, bytes));
            require(swapDescriptionObj.dstToken == wormholeWrappedToken, "Atlas DEX: Dest Token Not Matched");        
            amountToLock = _swapToken1Inch(lockedTokenData._1inchData, true);
        } // end of if for 1 inch data. 
        else if(lockedTokenData._0xData.length > 1) { // it means user need to first convert token to wormhole token.
            ( SwapStructs._0xSwapDescription memory swapDescriptionObj) = abi.decode(lockedTokenData._0xData[4:], (SwapStructs._0xSwapDescription));
            if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) { // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
                ( address[] memory tokens, uint256 sellAmount,, ) = abi.decode(lockedTokenData._0xData[4:], (address[], uint256, uint256, uint8));
                swapDescriptionObj.inputToken = tokens[0];
                swapDescriptionObj.outputToken = tokens[tokens.length - 1];
                swapDescriptionObj.inputTokenAmount = sellAmount;
            }
            require(swapDescriptionObj.outputToken == address(wormholeWrappedToken), "Atlas DEX: Dest Token Not Matched");        
            amountToLock = _swapToken0x(lockedTokenData._0xData);
        } // end of if for 1 inch data. 
        else if (lockedTokenData._IsWrapped) {
            amountToLock =  depositToWrappedToken();
        } else if ( lockedTokenData._IsUnWrapped) {
            amountToLock = withdrawToUnWrappedToken(lockedTokenData._amountToUnwrap, true);
        }


        require(wormholeWrappedToken.balanceOf(msg.sender) >= amountToLock, "Atlas DEX: You have low balance to lock.");

        wormholeWrappedToken.safeTransferFrom(msg.sender, address(this), amountToLock);

        // query tokens decimals
        (,bytes memory queriedDecimals) = address(wormholeWrappedToken).staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        uint256 amountForWormhole = deNormalizeAmount(normalizeAmount(amountToLock, decimals), decimals);

        if (wormholeWrappedToken.allowance(address(this), lockedTokenData._wormholeBridgeToken) < amountToLock) {
            wormholeWrappedToken.safeApprove(lockedTokenData._wormholeBridgeToken, MAX_INT);
        }
        emit AmountLocked(msg.sender, amountForWormhole);
        uint64 sequence = 0;
        if (lockedTokenData._payload.length > 1) {
            sequence = wormholeTokenBridgeContract.transferTokensWithPayload(lockedTokenData._token, amountForWormhole, lockedTokenData._recipientChain, lockedTokenData._recipient, lockedTokenData._nonce, lockedTokenData._payload);
        } else{
            sequence = wormholeTokenBridgeContract.transferTokens(lockedTokenData._token, amountForWormhole, lockedTokenData._recipientChain, lockedTokenData._recipient, 0, lockedTokenData._nonce);

        }
        return sequence;

    } // end of redeem Token

    receive() external payable {}
} // end of class