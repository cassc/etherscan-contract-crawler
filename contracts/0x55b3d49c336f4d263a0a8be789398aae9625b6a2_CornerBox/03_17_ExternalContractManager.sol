// SPDX-License-Identifier: MIT
// Library External Contract Manager v1.0.0
// Creator: Nothing Rhymes With Entertainment

pragma solidity >=0.8.9 <0.9.0;

library ExternalContractManager {
     struct Data {
        address _contract;
        //use this for deteriminng if live
        bool _isLive;
        //use this for any additional conditional checks
        bool _extraFlag;
        //Mapping for keeping track of things like claimed whitelist mints, etc.
        mapping(uint256 => bool) _addressMap;
        mapping(uint256 => bool) _tokenMap;
        //bytes32 for things like merkletree roots
        bytes32 _bytes;

    }

    
}