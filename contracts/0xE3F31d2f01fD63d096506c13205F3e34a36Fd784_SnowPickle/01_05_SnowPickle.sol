// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract SnowPickle is ERC20 {

    string private _mascot;

    constructor(uint256 initialSupply, string memory name, string memory symbol, string memory _m) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10 ** 18));
        _mascot = _m;
    }

    function mascot() public view returns (string memory) {
        return _mascot;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}