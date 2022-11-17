// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {VoteProposalLib} from "../libraries/VotingStatusLib.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
/*Interface for the ISWAP Router (Uniswap)  Contract*/
interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

interface WETH9Contract {
    function balanceOf(address) external returns (uint);
    function withdraw(uint amount) external;
    function deposit() external payable;
}
contract UniSwapFacet {
    IUniswapRouter immutable _swapRouter;
    WETH9Contract immutable wethAddress;

constructor (IUniswapRouter swapRouter, WETH9Contract _wethAddress) {
    _swapRouter = swapRouter;
    wethAddress = _wethAddress;
}
 error COULD_NOT_PROCESS();
    /* Uniswap Router Address with interface*/
     function executeSwap(
        uint24 _id,
        uint256 _oracleprice,
        uint24 poolfee
    ) external {

        VoteProposalLib.enforceMarried();
        VoteProposalLib.enforceUserHasAccess(msg.sender);
        VoteProposalLib.enforceAcceptedStatus(_id);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();
    
        IUniswapRouter swapRouter;
        swapRouter = _swapRouter;

        //A small fee for the protocol is deducted here
        uint256 _amount = (vt.voteProposalAttributes[_id].amount *
            (10000 - vt.cmFee)) / 10000;
        uint256 _cmfees = vt.voteProposalAttributes[_id].amount - _amount;

        if (vt.voteProposalAttributes[_id].voteType == 101){
            vt.voteProposalAttributes[_id].voteStatus = 101;

       VoteProposalLib.processtxn(vt.addressWaveContract, _cmfees);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: vt.voteProposalAttributes[_id].tokenID,
                    tokenOut: vt.voteProposalAttributes[_id].receiver,
                    fee: poolfee,
                    recipient: address(this),
                    deadline: block.timestamp+ 30 minutes,
                    amountIn: _amount,
                    amountOutMinimum: _oracleprice,
                    sqrtPriceLimitX96: 0
                });
           
           uint resp = swapRouter.exactInputSingle{value: _amount}(params);
           if (resp < _oracleprice) {revert COULD_NOT_PROCESS();} 
            swapRouter.refundETH();
    emit VoteProposalLib.AddStake(address(this), address(swapRouter), block.timestamp, _amount); 
            
            } else if (vt.voteProposalAttributes[_id].voteType == 102) {
                 vt.voteProposalAttributes[_id].voteStatus = 102;
                
                 TransferHelper.safeTransfer(
                    vt.voteProposalAttributes[_id].tokenID,
                    vt.addressWaveContract,
                    _cmfees
                );
            
            
            TransferHelper.safeApprove(
                vt.voteProposalAttributes[_id].tokenID,
                address(_swapRouter),
                _amount
            );
       
       ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: vt.voteProposalAttributes[_id].tokenID,
                    tokenOut: vt.voteProposalAttributes[_id].receiver,
                    fee: poolfee,
                    recipient: address(this),
                    deadline: block.timestamp+ 30 minutes,
                    amountIn: _amount,
                    amountOutMinimum: _oracleprice,
                    sqrtPriceLimitX96: 0
                });

            uint resp = swapRouter.exactInputSingle(params);
            if (resp < _oracleprice) {revert COULD_NOT_PROCESS();} 
           
                
            } else if (vt.voteProposalAttributes[_id].voteType == 103) {
                 vt.voteProposalAttributes[_id].voteStatus = 103;  
                
                 TransferHelper.safeTransfer(
                    vt.voteProposalAttributes[_id].tokenID,
                    vt.addressWaveContract,
                    _cmfees
                );
            
            
            TransferHelper.safeApprove(
                vt.voteProposalAttributes[_id].tokenID,
                address(_swapRouter),
                _amount
            );
       
       ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: vt.voteProposalAttributes[_id].tokenID,
                    tokenOut: vt.voteProposalAttributes[_id].receiver,
                    fee: poolfee,
                    recipient: address(this),
                    deadline: block.timestamp+ 30 minutes,
                    amountIn: _amount,
                    amountOutMinimum: _oracleprice,
                    sqrtPriceLimitX96: 0
                });

            uint resp = swapRouter.exactInputSingle(params);
            
            if (resp < _oracleprice) {revert COULD_NOT_PROCESS();} 
           
            WETH9Contract Weth = WETH9Contract(vt.voteProposalAttributes[_id].receiver);
            
            Weth.withdraw(_oracleprice); 
             
            } else {revert COULD_NOT_PROCESS();}
        

       emit VoteProposalLib.VoteStatus(
            _id,
            msg.sender,
            vt.voteProposalAttributes[_id].voteStatus,
            block.timestamp
        ); 
    }

    function withdrawWeth(uint amount) external{
        VoteProposalLib.enforceMarried();
        VoteProposalLib.enforceUserHasAccess(msg.sender);
        WETH9Contract Weth = WETH9Contract(wethAddress);
        Weth.withdraw(amount);
      } 

    function depositETH(uint amount) external payable{
        VoteProposalLib.enforceMarried();
        VoteProposalLib.enforceUserHasAccess(msg.sender);
        WETH9Contract Weth = WETH9Contract(wethAddress);
        Weth.deposit{value: amount}(); 
     
     emit VoteProposalLib.AddStake(address(this), address(wethAddress), block.timestamp, amount); 
    
      } 


}