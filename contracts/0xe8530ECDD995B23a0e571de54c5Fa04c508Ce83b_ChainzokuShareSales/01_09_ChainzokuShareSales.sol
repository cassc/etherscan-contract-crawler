// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Initialize.sol";
import "./Withdraw.sol";

contract ChainzokuShareSales is Initialize, Withdraw {

    constructor(){}

    function init(address _multiSigContract, Part[] memory _parts) public onlyOwner isNotInitialized{
        MultiSigProxy._setMultiSigContract(_multiSigContract);
        Withdraw._addParts(_parts);
    }

}