pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract TSTToken is CappedToken {
 
    string public name = "TBC Shopping Token";
    string public symbol = "TST";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




