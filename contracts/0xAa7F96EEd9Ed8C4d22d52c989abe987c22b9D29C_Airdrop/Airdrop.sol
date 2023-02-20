/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.6;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Airdrop {
    event TransferFailed(address to, uint256 value);
    
    address public owner;
    
    constructor(){
        owner = msg.sender;
    }
    

    
    function airdropTokenSimple(IERC20 token, address[] memory recipients, uint256 values,bool revertOnfail) external payable  {
          
        uint totalSuccess = 0;
        
        for (uint256 i = 0; i < recipients.length; i++){
            (bool success,bytes memory returnData) = address(token).call(abi.encodePacked( 
                    token.transferFrom.selector,
                    abi.encode(msg.sender, recipients[i], values)
                ));
                
            if(success){
                (bool decoded) = abi.decode(returnData,(bool));
                if(revertOnfail==true) require(decoded,'One of the transfers failed');
                else if(decoded==false) emit TransferFailed(recipients[i],values);
                if(decoded) totalSuccess++;
            }
            else if(success==false){
                if(revertOnfail==true) require(false,'One of the transfers failed');
                else emit TransferFailed(recipients[i],values);
            }
           }
           require(totalSuccess>=1,'all transfers failed');
           returnExtraEth();
    }
    
        
    function returnExtraEth () internal {
        uint256 balance = address(this).balance;
        if (balance > 0){ 
            payable(msg.sender).transfer(balance); 
        }
    }
    

    

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    
    modifier onlyOwner {
        require(msg.sender==owner,'Only owner can call this function');
        _;
    }
    
}