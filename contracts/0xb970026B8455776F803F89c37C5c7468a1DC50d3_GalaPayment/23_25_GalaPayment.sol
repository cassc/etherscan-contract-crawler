// SPDX-License-Identifier: MIT 
pragma solidity 0.8.2;

import "./base/UpgradeableBase.sol";
import "./base/MessageValidator.sol";
import "./interface/IGalaGameItems.sol";
import "./interface/IGalaERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract GalaPayment is UpgradeableBase, MessageValidator
{    
    event PaymentTransferExecuted(string orderId, address token, uint amount,uint transBlock); 
    event PaymentBurnExecuted(string orderId, address token, uint amount,uint transBlock);
    event PaymentBurnErc1155Executed(string orderId, address token, uint baseId, uint amount, uint transBlock);
    event PaymentExecuted (string orderId,uint amount,uint transBlock);
    using AddressUpgradeable for address payable;
    address public constant DEAD_ADDRESS = address(0);     

    modifier isValidToken(address _token)
    {
        require(_token != DEAD_ADDRESS, "Token address cannot be zero");
        _;
    }

    function initialize() initializer external
    {         
        init();        
    } 
    
    function payAndTransferERC20(PaymentMessage calldata params)   
    isValidMessage(params)
    isValidBlock(params.transBlock)    
    isValidOrder(params.orderId)
    isValidToken(params.token)
    nonReentrant
    whenNotPaused
    external payable
    {   
        emit PaymentTransferExecuted(params.orderId,params.token,params.amount,params.transBlock);   
        IGalaERC20(params.token).transferFrom(msg.sender, address(galaWallet), params.amount); 
    }      

    function payAndBurnERC20(PaymentMessage calldata params)   
    isValidMessage(params)
    isValidBlock(params.transBlock)    
    isValidOrder(params.orderId)
    isValidToken(params.token)
    nonReentrant
    whenNotPaused
    external 
    {   
        emit PaymentBurnExecuted(params.orderId,params.token,params.amount,params.transBlock);   
        IGalaERC20(params.token).burnFrom(msg.sender, params.amount);   
    }      

    function payETH(PaymentMessageEth calldata params)
    isValidMessageForEth(params)
    isValidBlock(params.transBlock)    
    isValidOrder(params.orderId)    
    nonReentrant   
    whenNotPaused 
    external payable
    {           
        emit PaymentExecuted(params.orderId, msg.value, params.transBlock);     
        payable(address(galaWallet)).sendValue(msg.value);
    }

    function payAndBurnErc1155(PaymentMessageErc1155 calldata params)   
    isValidMessageForErc1155(params)
    isValidBlock(params.transBlock)    
    isValidOrder(params.orderId)
    isValidToken(params.token)
    nonReentrant
    whenNotPaused
    external 
    {  
        uint256[] memory baseIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        baseIds[0] = params.baseId;
        amounts[0] = params.amount;
        emit PaymentBurnErc1155Executed(params.orderId, params.token, params.baseId, params.amount, params.transBlock);   
        IGalaGameItems(params.token).burn(msg.sender, baseIds, amounts);        
    }      

     function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }      
}