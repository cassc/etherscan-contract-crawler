// $$$$$$$\  $$$$$$$$\ $$$$$$$\  
// $$  __$$\ $$  _____|$$  __$$\ 
// $$ |  $$ |$$ |      $$ |  $$ |
// $$ |  $$ |$$$$$\    $$ |  $$ |
// $$ |  $$ |$$  __|   $$ |  $$ |
// $$ |  $$ |$$ |      $$ |  $$ |
// $$$$$$$  |$$$$$$$$\ $$$$$$$  |
// \_______/ \________|\_______/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import { ERC20 } from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "openzeppelin-contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";

import { IDEDToken } from "./interface/IDEDToken.sol";

contract DEDToken is ERC20, ERC20Permit, IDEDToken, Ownable {
    uint256 public constant INITIAL_SUPPLY = 666_666_666_666 * 10 ** 18;
    address public adminWallet;

    constructor() ERC20("DED", "DED") ERC20Permit("DED") {
        _mint(address(this), INITIAL_SUPPLY);
    }

    function claim(uint256 amount) external override {
        require(_msgSender() == adminWallet, "not admin");
        _transfer(address(this), _msgSender(), amount);
    }

    function claimTo(uint256 amount, address recipient) external override {
        require(_msgSender() == adminWallet, "not admin");
        _transfer(address(this), recipient, amount);
    }

    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }
}