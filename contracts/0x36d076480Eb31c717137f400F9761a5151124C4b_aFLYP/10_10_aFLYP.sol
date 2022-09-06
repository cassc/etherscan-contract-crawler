// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract aFLYP is ERC20, AccessControl {
    constructor() ERC20("aFLYP", "aFLYP") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only authorised contact can use this function"
        );
        _;
    }

    function mintFor(address _receiver, uint256 _amount) external onlyOwner {
        _mint(_receiver, _amount);
    }

    function mint(uint256 _amount) external onlyOwner {
        _mint(_msgSender(), _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        _burn(_msgSender(), _amount);
    }

    function transfer(address to, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}