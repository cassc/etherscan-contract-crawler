// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


contract MultiSender is Ownable{

    
    using SafeMath for uint256;
    using SafeMath for uint16;

    function sendTokens(address _tokenAddress, address[] memory _recipients, uint256 _value) public {
        uint16 length =  uint16(_recipients.length);
        uint256 eachShare = _value.div(length);

        IBEP20 TokenAddress = IBEP20(_tokenAddress);
        
        for(uint16 i=0; i<length; i++){
            TokenAddress.transferFrom(msg.sender, _recipients[i], eachShare);
        }
        
    }

}