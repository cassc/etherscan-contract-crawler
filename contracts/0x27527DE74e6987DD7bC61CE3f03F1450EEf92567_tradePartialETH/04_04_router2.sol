// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract tradePartialETH is Initializable{

    address internal weth;

    event internalSwap(bool isDone,address receivingAddress,uint256 amountReceived,uint256 currentStep,uint256 totalStep);
    event refund(bool success,bool isToken,address tokenAddress,address receiverAddress,uint256 tokenAmount);

    function initialize() public initializer {
        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }
    function swap(bytes[] memory _data)public payable{

        for(uint256 i=0; i<_data.length;i++){

            (address target, bytes memory callData,uint256 tokenValue) = abi.decode(_data[i],(address,bytes,uint256));
            (bool success,) = target.call{value: tokenValue}(callData);
            require(success,"failed");
        }
    }

    function swapCM(bytes[] memory _data)public payable{

        for(uint256 i=0; i<_data.length;i++){

            (address target, bytes memory callData,uint256 tokenValue,address sendToken) = abi.decode(_data[i],(address,bytes,uint256,address));
            (bool success,) = target.call{value: tokenValue}(callData);

            if(success){
                emit internalSwap(true,msg.sender,tokenValue,i,_data.length);
            }

            else if(!success){

                if(sendToken==weth){

                    (bool successA,) = address(msg.sender).call{value:tokenValue}("");
                    if(successA){
                        emit refund(true,false,weth,msg.sender,tokenValue);
                    }
                    else{
                        emit refund(false,false,weth,msg.sender,tokenValue);
                    }
                }
                else{
                    bool isSuccess = IERC20(sendToken).transfer(msg.sender,tokenValue);
                    if(isSuccess){
                        emit refund(true,true,sendToken,msg.sender,tokenValue);
                    }
                    else{
                        emit refund(false,true,sendToken,msg.sender,tokenValue);
                    }
                }
            }
        }
    }
    receive() external payable{}
}