// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Token is ERC20, Ownable {
    using SafeERC20 for ERC20;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(_amount > 0, "amount is 0");
        _mint(_to, _amount);
        return true;
    }
}