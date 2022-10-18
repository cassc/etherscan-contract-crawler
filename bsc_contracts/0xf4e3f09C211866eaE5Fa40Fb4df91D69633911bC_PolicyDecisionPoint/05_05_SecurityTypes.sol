// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

library SecurityTypes {
    bytes32 public constant ANY = 0x0;
    
    enum PolicyEffect { UNKNOWN, GRANT, DENY }
    
    struct Rule {
       bytes32 role;
       PolicyEffect effect;
    }
    
    struct Policy {
       Rule[] rules;
    }
    
    struct Role {
       bytes32 adminRole;
       string label;
    }
}