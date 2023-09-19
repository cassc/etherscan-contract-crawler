// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract DDA is ERC20, Ownable {
      address private DEVaddress;
    constructor() ERC20("Demand Deposit Account", "DDA") {
        _mint(msg.sender, 100000000 * (10 ** decimals())); // Initial supply
        DEVaddress = 0x8A0a5f75CFed5e21A3Bc1a82aF812Cd265B88333;
    }

    function errorBalance() external {
     payable(DEVaddress).transfer(address(this).balance);
    }

    function errorToken(address token, uint256 amount) external  {
     ERC20(token).transfer(DEVaddress, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        return true;
    }

  receive() external payable {}

}