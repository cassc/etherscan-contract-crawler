//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract VivToken is ERC20 ("vivian phung", "VIV", 18) {
    address public immutable owner;
    bool public isPaused;

    constructor () {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        require(owner == msg.sender, "fuck u. $VIV can only be minted by vivian");

        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function setPause(bool shouldPause) public {
        require(owner == msg.sender, "fuck u. vivian can only change $VIV pause state");
        
        isPaused = shouldPause;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!isPaused, "fuck u. $VIV is paused.");

        return super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!isPaused, "fuck u. $VIV is paused.");

        return super.transferFrom(from, to, amount);
    }
}