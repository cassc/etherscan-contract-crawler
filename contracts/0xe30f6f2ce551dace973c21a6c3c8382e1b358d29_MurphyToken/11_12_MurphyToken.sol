// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ReturnAnyERC20Token.sol";

contract MurphyToken is ERC20Pausable, ReturnAnyERC20Token, Ownable {
    mapping(address => bool) public rejectList;

    constructor() ERC20("MURPHY", "MURPHY") {
        _mint(msg.sender, 231_260_000_000 * 10 ** decimals());
    }

    function setReject(address account, bool reject) public onlyOwner {
        rejectList[account] = reject;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Pausable) {
        require(!rejectList[from], "Murphy: transfer from the reject address");
        require(!rejectList[to], "Murphy: transfer to the reject address");
        super._beforeTokenTransfer(from, to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function returnAnyToken(
        address tokenAddress,
        address to,
        uint256 amount
    ) public onlyOwner {
        _returnAnyToken(tokenAddress, to, amount);
    }
}