// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Enoch is ERC20 {

    address public _owner;
    uint256 private _totalSupply = 54000000000000000000000000; //54,000,000 ENOCH tokens
    
    modifier onlyAdmin() {
        require(
            msg.sender == _owner,
            "Only Admin can call this!"
        );
        _;
    }
    
    constructor() ERC20("ENOCH", "ENOCH") {
        _owner = msg.sender;
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 amount) external onlyAdmin {
        _burn(_owner, amount);
    }

    function transferAdminRole(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        _owner = newAdmin;
    }

}