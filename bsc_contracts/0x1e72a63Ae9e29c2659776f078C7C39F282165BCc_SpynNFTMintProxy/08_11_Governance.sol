// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

contract Governance {

    address public _governance;

    constructor() {
        _governance = msg.sender;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}