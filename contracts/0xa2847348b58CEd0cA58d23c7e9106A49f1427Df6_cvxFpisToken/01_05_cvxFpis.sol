// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract cvxFpisToken is ERC20 {

    address public owner;
    mapping(address => bool) public operators;

    constructor()
        ERC20(
            "Convex FPIS",
            "cvxFPIS"
        )
    {
        owner = msg.sender;
    }

   function setOperators(address _depositor, address _burner) external {
        require(msg.sender == owner, "!auth");
        operators[_depositor] = true;
        operators[_burner] = true;
        owner = address(0); //immutable once set
    }

    
    function mint(address _to, uint256 _amount) external {
        require(operators[msg.sender], "!authorized");
        
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(operators[msg.sender], "!authorized");
        
        _burn(_from, _amount);
    }

}