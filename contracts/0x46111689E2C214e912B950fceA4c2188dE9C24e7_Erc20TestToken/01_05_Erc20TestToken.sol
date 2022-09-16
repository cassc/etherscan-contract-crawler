pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Erc20TestToken is ERC20 {
    uint8 _decimals;

    constructor(uint8 decimals_) ERC20('Test Erc20 token', 'ERC20T') {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mintTest(uint256 count) public {
        _mint(msg.sender, count);
    }

    function mint(uint256 count) public {
        _mint(msg.sender, count);
    }

    function mintTo(address account, uint256 count) public {
        _mint(account, count);
    }
}