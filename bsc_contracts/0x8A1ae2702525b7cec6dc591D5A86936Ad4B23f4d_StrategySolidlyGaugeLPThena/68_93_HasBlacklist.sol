// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../owner/Operator.sol";

interface IBlackList {
    function isBlacklisted(address sender) external view returns (bool);
}

contract HasBlacklist is Operator {
    address public BL = 0x107Ac39903bDAD94cb562E686E0A5E116d3dc814;

    modifier notInBlackList(address sender) {
        bool isBlock = IBlackList(BL).isBlacklisted(sender);
        require(isBlock == false, "HasBlacklist: in blacklist");
        _;
    }

    // Set Blacklist 
    function setBL(address blacklist) external onlyOperator {
        BL = blacklist;
    }
}