pragma solidity ^0.6.12;

import "./lib/ERC20.sol";

// File: contracts/GovToken.sol
contract GovToken is ERC20 {

    address minter;

    modifier onlyMinter {
        require(msg.sender == minter, 'Only minter can call this function.');
        _;
    }

    constructor(address _minter) public ERC20('Cocktails Voting', 'DQRI') {
        minter = _minter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }
}