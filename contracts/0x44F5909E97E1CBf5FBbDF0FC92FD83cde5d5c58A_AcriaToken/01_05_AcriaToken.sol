// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AcriaToken is ERC20 {

    address admin;

    constructor(uint256 initialSupply) ERC20("Acria Token", "ACRIA") {
        admin = msg.sender;
        _mint(admin, initialSupply);
    }

    function transferBatch(address[] calldata wallets, uint256[] calldata amounts) external {
        require(wallets.length <= 100);
        for (uint i = 0; i < wallets.length; i++) {
            transfer(wallets[i], amounts[i]);
        }
    }

    function mint(uint256 amount) external {
        require(msg.sender == admin);
        require(amount > 0);
        _mint(admin, amount);
    }

    function burn(uint256 amount) external {
        require(amount > 0);
        _burn(msg.sender, amount);
    }
  
}