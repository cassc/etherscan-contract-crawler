pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract XNC is CappedToken {
 
    string public name = "Xian Coin";
    string public symbol = "XNC";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




