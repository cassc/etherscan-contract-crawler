pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ITransferer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract CoinsDeliver {
    using SafeMath for uint256;

    function deliver(address[]  memory toList) external payable {
        uint256 dividerValue = msg.value.div(toList.length);

        for (uint256 index = 0; index < toList.length-1; index++) {
            Address.sendValue(payable(toList[index]), dividerValue);
        }

        uint256 dividerValueSend = dividerValue.mul(toList.length-1);
        uint256 remainValue = msg.value.sub(dividerValueSend);
        Address.sendValue(payable(toList[toList.length-1]), remainValue);
    }

    function deliverByValue(uint256[] memory valueList, address[]  memory toList) external payable {
        uint256 summer = 0;

        for (uint256 index = 0; index < toList.length; index++) {
            summer = summer.add(valueList[index]);
        }
        require(summer < msg.value, "value not enough");

        for (uint256 index = 0; index < toList.length; index++) {
            Address.sendValue(payable(toList[index]), valueList[index]);
        }
        if(summer < msg.value){
            Address.sendValue(payable(msg.sender), msg.value.sub(summer));
        }
    }


}