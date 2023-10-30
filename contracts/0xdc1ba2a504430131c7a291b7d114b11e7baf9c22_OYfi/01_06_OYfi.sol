// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OYfi is ERC20, Ownable {
    constructor() ERC20("OYFI", "OYFI") {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    function burn(address _owner, uint256 _amount) external {
        _spendAllowance(_owner, msg.sender, _amount);
        _burn(_owner, _amount);
    }
}