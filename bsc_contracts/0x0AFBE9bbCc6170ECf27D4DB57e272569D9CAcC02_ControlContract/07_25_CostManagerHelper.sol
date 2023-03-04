// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CostManagerBase.sol";

/**
* used for instances that have created(cloned) by factory.
*/
contract CostManagerHelper is CostManagerBase {

    function _sender() internal override view returns(address){
        return msg.sender;
    }
}