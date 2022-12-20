// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract MessageValidator is OwnableUpgradeable {
    
    event GalaWalletAddressSet(address galaWalletAddress);     
    event ImportantAddressSet(address importantAddress); 
    event BlockMaxThresholdSet(uint blockMaxThreshold);
    
    using ECDSAUpgradeable for bytes32; 
    address public galaWallet; 
    address public importantAddress; 
    uint public blockMaxThreshold;  
    mapping(string => bool) orders;

    struct PaymentMessage
    {
        string orderId;
        address token;
        uint amount;
        uint transBlock;
        uint transType;
        uint chainId;
        bytes sig;
    }

     struct PaymentMessageEth
    {
        string orderId;        
        uint amount;
        uint transBlock;        
        uint chainId;
        bytes sig;        
    }

    struct PaymentMessageErc1155
    {
        string orderId;
        address token;
        uint baseId;
        uint amount;
        uint transBlock;
        uint transType;
        uint chainId;
        bytes sig;
    }

    function setGalaWalletAddress(address _galaWalletAddress) external onlyOwner {            
        require(_galaWalletAddress != address(0), "Wallet address cannot be zero");
        emit GalaWalletAddressSet(_galaWalletAddress);     
        galaWallet = _galaWalletAddress;       
    }

     function setImportantAddress(address _importantAddress) external onlyOwner {    
        require(_importantAddress != address(0), "important address cannot be zero");    
        emit ImportantAddressSet(_importantAddress); 
        importantAddress = _importantAddress;       
    }

    function setBlockMaxThreshold(uint _blockMaxThreshold) external onlyOwner
    {
        require(_blockMaxThreshold != 0, "blockMax threshold must be greater than zero"); 
        emit BlockMaxThresholdSet(_blockMaxThreshold);
        blockMaxThreshold = _blockMaxThreshold;        
    }

    modifier isValidMessage(PaymentMessage calldata _params)
    {   
        bytes32 message = keccak256(abi.encodePacked(_params.orderId, _params.token, _params.amount, _params.transBlock, _params.transType, _params.chainId));        
        require(message.recover(_params.sig) == importantAddress, "Token Invalid signature");        
        _;    
    }   

     modifier isValidMessageForEth(PaymentMessageEth calldata _params)
    {        
        bytes32 message = keccak256(abi.encodePacked(_params.orderId, _params.amount, _params.transBlock, _params.chainId));        
        require(message.recover(_params.sig) == importantAddress, "Eth Invalid signature");         
        require(_params.amount  == msg.value, "Invalid Amount");         
        _;    
    }  

    modifier isValidMessageForErc1155(PaymentMessageErc1155 calldata _params) 
    {        
        bytes32 message = keccak256(abi.encodePacked(_params.orderId, _params.token, _params.baseId, _params.amount, _params.transBlock, _params.transType, _params.chainId));
        require(message.recover(_params.sig) == importantAddress, "ERC1155 Token Invalid signature");         
        _;    
    }   

    modifier isValidBlock(uint _transBlock)
    {        
        require(block.number <= _transBlock + blockMaxThreshold, "block exceeded the threshold");        
        _;   
    }

    modifier isValidOrder(string memory _orderId) 
    {
        require(!orders[_orderId], "duplicate order");
        orders[_orderId] = true;
        _;
    }  
}