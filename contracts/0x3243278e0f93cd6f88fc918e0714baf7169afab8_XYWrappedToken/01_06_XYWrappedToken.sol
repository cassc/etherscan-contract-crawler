// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC20.sol";


contract XYWrappedToken is ERC20, Ownable {

    event SetMinter(address minter, bool isMinter);

    mapping (address => bool) public isMinter;

    modifier onlyMinter {
        require(isMinter[msg.sender], "ERR_NOT_MINTER");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        isMinter[owner()] = true;
    }

    function setMinter(address minter, bool _isMinter) external onlyOwner {
        isMinter[minter] = _isMinter;

        emit SetMinter(minter, _isMinter);
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}