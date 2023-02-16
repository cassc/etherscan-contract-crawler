// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

/**************************************
    
    MultiBatch contract

    ------------------------------
    
    This contract is an extended version of @openzeppelin Multicall contract
    Features batch calls and reads with delegatecall and staticcall functions

**************************************/
    
abstract contract MultiBatch is Multicall {

    /**************************************
     
        Multiread

        ------------------------------

        @param _data list of encoded function calls
        @return results_ list of encoded function returns

    /**************************************/

    function multiread(bytes[] calldata _data) external view 
    returns (bytes[] memory results_) {

        // get length
        uint256 length_ = _data.length;

        // initialize array
        results_ = new bytes[](length_);

        // static call in loop
        for (uint256 i = 0; i < length_; i++) {
            results_[i] = Address.functionStaticCall(address(this), _data[i]);
        }

        // return
        return results_;
    }

}