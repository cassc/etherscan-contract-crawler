// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../owner/Operator.sol";

contract HasPOL is Operator {
    address public POL = 0x409968A6E6cb006E8919de46A894138C43Ee1D22;
    
    // set pol address
    function setPolAddress(address _pol) external onlyOperator {
        POL = _pol;
    }
}