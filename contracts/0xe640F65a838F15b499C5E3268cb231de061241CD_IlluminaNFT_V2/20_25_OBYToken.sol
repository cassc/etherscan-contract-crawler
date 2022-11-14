//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract OBYToken is ERC20, Ownable {
    mapping(address => bool) private _eligibles;

    event Destruction(uint256 amount);

    constructor() ERC20("OBYToken", "OBY") {}

    modifier onlyEligible() {
        require(owner() == _msgSender() || _eligibles[msg.sender], "OBYToken: caller is not eligible");
        _;
    }

    function setEligibles(address _eligible) public onlyOwner {
        _eligibles[_eligible] = true;
    }

    function mint(address account, uint256 amount) external onlyEligible {
        uint256 sendAmount = amount * (10**18);
        _mint(account, sendAmount);
    }

    function checkBalances(uint256 tokenPrice, address account) external onlyEligible view returns (bool) {
        if (balanceOf(account) >= tokenPrice) {
            return true;
        }
        return false;
    }

    function burnToken(uint256 amount, address account) external onlyEligible {
        uint256 sendAmount = amount * (10**18);
        _burn(account, sendAmount);

        emit Destruction(amount);
    }

    function getEligibles(address account) public view onlyEligible returns (bool) {
        require (account != address(0), "OBYToken: address must not be empty");
        return _eligibles[account];
    }
}