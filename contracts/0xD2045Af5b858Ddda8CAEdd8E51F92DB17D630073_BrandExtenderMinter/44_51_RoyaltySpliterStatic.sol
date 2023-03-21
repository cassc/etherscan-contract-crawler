// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract RoyaltySpliterStatic {
   
    struct Receiver {
        address wallet;
        uint16 revenue;
    }

    Receiver[] private receivers;
    
    event RoyaltyPaid(address receiver, uint256 sum);

    constructor() {
        // validateAndSaveReceivers( initialReceivers );
    }

    function getReceivers() internal view returns(Receiver[] memory){
        return receivers;
    }

    function updateRecievers(Receiver[] memory newReceivers) external {
        _authorizeUpdateRecievers(newReceivers);
        validateAndSaveReceivers( newReceivers );
    }

    function validateAndSaveReceivers(Receiver[] memory newReceivers) internal {
        uint sum = 0;
        uint i;

        // clean current data
        uint curLen = receivers.length;
        if (curLen > 0) {
            for ( i = 0; i < curLen; i++){
                receivers.pop();
            }
        }

        uint len = newReceivers.length;
        for ( i = 0; i < len; i++){
            sum += newReceivers[i].revenue;
            receivers.push(newReceivers[i]);
        }
        require (sum == 10000, "Total revenue must be 10000");
    }

    function withdrawETH() external {
        uint balance = address(this).balance;
        require(balance > 0, "Empty balance");

        Receiver[] memory _receivers = getReceivers();

        require(_receivers.length > 0, "No receivers");
        unchecked {
            uint sum;
            uint len = _receivers.length;
            for (uint i = 0; i < len; i++){
                sum = balance * _receivers[i].revenue / 10000;
                emit RoyaltyPaid(_receivers[i].wallet, sum);
                _pay( _receivers[i].wallet, sum);
            }

        }
    }

    function _pay(address ETHreceiver, uint256 amount) internal {
        (bool sent, ) = ETHreceiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    function _authorizeUpdateRecievers(Receiver[] memory newReceivers) internal virtual;
}