// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract SEC is ERC20 {
    address internal minter;
    address internal treasury;
    bool internal start;

    constructor(address treasury_address) ERC20("SEC", "SEC") {
        _mint(msg.sender, 1000*10**18);
        start = false;
        minter = msg.sender;
        treasury = treasury_address;
    }

    function activate() public {
        require(msg.sender == minter);
        start = true;
        _mint(treasury, 10*10**18);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(start);
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(start);
        super.transferFrom(sender, recipient, amount);
        return true;
    }
}