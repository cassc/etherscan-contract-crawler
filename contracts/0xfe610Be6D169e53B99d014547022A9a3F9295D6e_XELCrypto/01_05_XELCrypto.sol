// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XELCrypto is ERC20 {
    address public minter;

    constructor(address _minter) ERC20("XEL Crypto", "XEL") {
        minter = _minter;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "No access");
        _mint(account, amount);
    }
}