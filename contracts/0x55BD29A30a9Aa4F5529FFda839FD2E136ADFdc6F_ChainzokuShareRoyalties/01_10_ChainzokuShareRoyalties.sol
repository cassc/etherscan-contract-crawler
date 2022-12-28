// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Initialize.sol";
import "./Royalties.sol";

contract ChainzokuShareRoyalties is Initialize, Royalties {

    constructor() Royalties(){}

    function init(address _multiSigContract, Part[] memory _parts) public onlyOwner isNotInitialized{
        MultiSigProxy._setMultiSigContract(_multiSigContract);
        Royalties._addParts(_parts);
    }

}