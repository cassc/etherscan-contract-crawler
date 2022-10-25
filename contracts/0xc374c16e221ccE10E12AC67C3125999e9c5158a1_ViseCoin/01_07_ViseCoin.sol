// SPDX-License-Identifier: MIT LICENSE
pragma solidity >=0.8.4 <0.9.0;

import "Ownable.sol";
import "ERC20Burnable.sol";


contract ViseCoin is ERC20Burnable, Ownable {

    mapping(address => bool) controllers;
    bool public paused = false;

    constructor() ERC20("Vise Coin", "VC") {}

    function mint(address to, uint256 amount) external {
        require(!paused, "The contract is paused!");
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        require(!paused, "The contract is paused!");
        require(controllers[msg.sender], "Your not a controller");
        _burn(account, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function burn(uint256 amount) public override {
        require(!paused, "The contract is paused!");
        _burn(_msgSender(), amount);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function destroy(address apocalypse) public onlyOwner {
        selfdestruct(payable(apocalypse));
    }
    
}